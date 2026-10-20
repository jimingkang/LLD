/*
 * XRadio SDIO function driver, after the xradio driver's sdio.c: binds
 * to SDIO function 1, checks that CMD53 works, raises the bus clock and
 * hands the device to the core (main.c).
 *
 * XR829 on the 100ASK T113-Pro enumerates as 0x0a9e:0x2282 (measured);
 * the older XR819 is 0x0020:0x2281 (open-source xradio driver).
 */
#include "platform.h"
#include "device.h"
#include "mmc.h"
#include "net/netutil.h"
#include "xradio.h"

#define XRADIO_BLOCK_SIZE   512u
#define XRADIO_FAST_CLOCK   12000000u   /* default-speed, 1-bit */

static void puthex16(uint32_t v)
{
    static const char hex[] = "0123456789abcdef";
    t113_uart_puts("0x");
    for (int s = 12; s >= 0; s -= 4)
        t113_uart_putc(hex[(v >> s) & 15u]);
}

static void say(struct sdio_func *func, const char *msg)
{
    t113_uart_puts(func->dev_name);
    t113_uart_puts(": ");
    t113_uart_puts(msg);
}

/* CMD53 sanity check on registers that need no firmware. */
static int xradio_cmd53_selftest(struct sdio_func *func, int verbose)
{
    static const uint32_t patterns[] = { 0xa5a55a5au, 0x12345678u, 0x0u };
    uint32_t cfg1 = 0, cfg2 = 0, ctrl = 0, saved = 0, v = 0;
    int ret;

    if ((ret = xradio_reg_read_32(func, HIF_CONFIG_REG_ID, &cfg1)) < 0 ||
        (ret = xradio_reg_read_32(func, HIF_CONFIG_REG_ID, &cfg2)) < 0) {
        say(func, "CMD53 read of HIF_CONFIG failed\n");
        return ret;
    }
    xradio_reg_read_32(func, HIF_CONTROL_REG_ID, &ctrl);
    if (verbose) {
        say(func, "HIF_CONFIG ");
        t113_uart_puthex(cfg1);
        t113_uart_puts(cfg1 == cfg2 ? " (stable)" : " (UNSTABLE: ");
        if (cfg1 != cfg2) {
            t113_uart_puthex(cfg2);
            t113_uart_putc(')');
        }
        t113_uart_puts(" HIF_CONTROL ");
        t113_uart_puthex(ctrl);
        t113_uart_putc('\n');
    }
    if (cfg1 != cfg2)
        return -EIO;
    xradio_priv.hif_config = cfg1;

    xradio_reg_read_32(func, HIF_TSET_GEN_R_W_REG_ID, &saved);
    for (uint32_t i = 0; i < sizeof(patterns) / sizeof(patterns[0]); ++i) {
        if ((ret = xradio_reg_write_32(func, HIF_TSET_GEN_R_W_REG_ID, patterns[i])) < 0 ||
            (ret = xradio_reg_read_32(func, HIF_TSET_GEN_R_W_REG_ID, &v)) < 0) {
            say(func, "CMD53 write/read of HIF_TSET_GEN failed\n");
            return ret;
        }
        if (v != patterns[i]) {
            say(func, "HIF_TSET_GEN mismatch: wrote ");
            t113_uart_puthex(patterns[i]);
            t113_uart_puts(" read ");
            t113_uart_puthex(v);
            t113_uart_putc('\n');
            return -EIO;
        }
    }
    xradio_reg_write_32(func, HIF_TSET_GEN_R_W_REG_ID, saved);
    if (verbose)
        say(func, "CMD53 write/read-back OK (HIF_TSET_GEN, 3 patterns)\n");
    return 0;
}

static int xradio_sdio_probe(struct sdio_func *func,
                             const struct sdio_device_id *id)
{
    (void)id;
    int ret = sdio_enable_func(func);
    if (ret < 0) {
        say(func, "cannot enable SDIO function\n");
        return ret;
    }
    ret = sdio_set_block_size(func, XRADIO_BLOCK_SIZE);
    if (ret < 0) {
        sdio_disable_func(func);
        return ret;
    }

    uint8_t ioe = 0, ior = 0, bs_lo = 0, bs_hi = 0;
    sdio_f0_readb(func, SDIO_CCCR_IOEx, &ioe);
    sdio_f0_readb(func, SDIO_CCCR_IORx, &ior);
    sdio_f0_readb(func, SDIO_FBR_BASE(func->num) + SDIO_FBR_BLKSIZE, &bs_lo);
    sdio_f0_readb(func, SDIO_FBR_BASE(func->num) + SDIO_FBR_BLKSIZE + 1, &bs_hi);

    xradio_priv.func = func;
    sdio_set_drvdata(func, &xradio_priv);

    say(func, "XRadio WiFi ");
    puthex16(func->vendor);
    t113_uart_putc(':');
    puthex16(func->device);
    t113_uart_puts(" enabled (IOEx ");
    puthex16(ioe);
    t113_uart_puts(" IORx ");
    puthex16(ior);
    t113_uart_puts(" blksz ");
    puthex16((uint32_t)bs_lo | ((uint32_t)bs_hi << 8));
    t113_uart_puts(")\n");

    /* The data path is still bring-up: report, but keep the binding. */
    if (xradio_cmd53_selftest(func, 1) != 0) {
        say(func, "CMD53 not working; firmware download impossible\n");
        return 0;
    }

    /* 174 KiB at 400 kHz 1-bit takes seconds: go faster if it holds up. */
    struct mmc_host *host = func->card->host;
    mmc_set_clock(host, XRADIO_FAST_CLOCK);
    if (xradio_cmd53_selftest(func, 0) == 0) {
        say(func, "SDIO clock ");
        net_putdec(XRADIO_FAST_CLOCK / 1000u);
        t113_uart_puts(" kHz\n");
    } else {
        say(func, "CMD53 fails at the fast clock, back to the init clock\n");
        mmc_set_clock(host, 0);
    }

    xradio_core_probe(func);
    return 0;
}

static void xradio_sdio_remove(struct sdio_func *func)
{
    sdio_disable_func(func);
    xradio_priv.func = 0;
}

static const struct sdio_device_id xradio_sdio_ids[] = {
    { SDIO_ANY_ID, 0x0a9e, 0x2282 },        /* XR829, read from 100ASK T113-Pro */
    { SDIO_ANY_ID, 0x0020, 0x2281 },        /* XR819 per open-source xradio */
    { SDIO_ANY_ID, 0x0a9e, SDIO_ANY_ID },   /* other XRadio parts: still bind */
    { SDIO_ANY_ID, 0x0020, SDIO_ANY_ID },
    { 0, 0, 0 },
};

struct sdio_driver xradio_sdio_driver = {
    .probe = xradio_sdio_probe,
    .remove = xradio_sdio_remove,
    .driver = { .name = "xradio_wlan" },
    .id_table = xradio_sdio_ids,
};
