/*
 * Allwinner SMHC (sunxi-mmc) host controller, sun20i-d1 / T113 flavour,
 * command-only (CMD52 class) polling driver for SDIO enumeration.
 *
 * Register layout follows U-Boot drivers/mmc/sunxi_mmc.h; clocks follow
 * mainline ccu-sun20i-d1.c:
 *   mmcN mod clock  CCU 0x830 + 4N : gate b31, mux b24-26 (0 = HOSC),
 *                                    P b8-9, M b0-3, fixed post-div 2
 *   bus gate/reset  CCU 0x84c      : gate bit N, reset bit 16+N
 * The D1 SMHC needs "new timing" mode (NTSR b31) and DATA0 masked while
 * the card clock is being updated (CLKCR b31), as in Linux sunxi-mmc.
 */
#include "platform.h"
#include "platform_device.h"
#include "gpio.h"
#include "mmc.h"
#include "wifi.h"
#include "board.h"

#define SMHC_GCTRL      0x000u
#define SMHC_CLKCR      0x004u
#define SMHC_TMOUT      0x008u
#define SMHC_WIDTH      0x00cu
#define SMHC_BLKSZ      0x010u
#define SMHC_BYTECNT    0x014u
#define SMHC_CMD        0x018u
#define SMHC_ARG        0x01cu
#define SMHC_RESP0      0x020u
#define SMHC_IMASK      0x030u
#define SMHC_RINT       0x038u
#define SMHC_STATUS     0x03cu
#define SMHC_NTSR       0x05cu
#define SMHC_HWRST      0x078u
#define SMHC_FIFO       0x200u          /* NCAT2 layout (D1/T113) */

#define GCTRL_RESET     0x7u            /* soft | fifo | dma */
#define GCTRL_FIFO_RST  (1u << 1)
#define GCTRL_AHB       (1u << 31)      /* CPU accesses the FIFO */

#define CLKCR_ENABLE    (1u << 16)
#define CLKCR_POWERSAVE (1u << 17)
#define CLKCR_MASK_D0   (1u << 31)
#define CLKCR_DIV_MASK  0xffu

#define CMD_RESP_EXPIRE (1u << 6)
#define CMD_LONG_RESP   (1u << 7)
#define CMD_CHK_CRC     (1u << 8)
#define CMD_DATA        (1u << 9)
#define CMD_WRITE       (1u << 10)
#define CMD_WAIT_PRE    (1u << 13)
#define CMD_INIT_SEQ    (1u << 15)
#define CMD_UPCLK_ONLY  (1u << 21)
#define CMD_START       (1u << 31)

#define RINT_RESP_ERR   (1u << 1)
#define RINT_CMD_DONE   (1u << 2)
#define RINT_DATA_OVER  (1u << 3)
#define RINT_RESP_CRC   (1u << 6)
#define RINT_RESP_TMO   (1u << 8)
#define RINT_HW_LOCKED  (1u << 12)
#define RINT_START_ERR  (1u << 13)
#define RINT_END_ERR    (1u << 15)
#define RINT_ERR_MASK   0xbfc2u

#define STATUS_FIFO_EMPTY (1u << 2)
#define STATUS_FIFO_FULL (1u << 3)
#define STATUS_CARD_BUSY (1u << 9)

#define NTSR_NEW_MODE   (1u << 31)

#define CCU_MMC_CLK(n)  (T113_CCU_BASE + 0x830u + 4u * (n))
#define CCU_MMC_BGR     (T113_CCU_BASE + 0x84cu)
#define CCU_PLL_PERI0   (T113_CCU_BASE + 0x020u)
#define CCU_FANOUT_GATE (T113_CCU_BASE + 0xf30u)
#define CCU_FANOUT_CFG  (T113_CCU_BASE + 0xf3cu)

#define SMHC_SRC_HZ     12000000u       /* HOSC 24 MHz / fixed post-div 2 */

struct t113_smhc {
    uint32_t base;
    const struct t113_mmc_platform_data *pdata;
    uint32_t clock_hz;
    uint32_t last_rint;
    struct mmc_host host;
};

static struct t113_smhc smhc_state[MMC_MAX_HOSTS];
static const char *const smhc_names[MMC_MAX_HOSTS] = { "mmc0", "mmc1", "mmc2" };

static inline uint32_t rd(struct t113_smhc *s, uint32_t reg)
{
    return mmio_read32(s->base + reg);
}

static inline void wr(struct t113_smhc *s, uint32_t reg, uint32_t v)
{
    mmio_write32(s->base + reg, v);
}

static int smhc_reset(struct t113_smhc *s)
{
    wr(s, SMHC_GCTRL, GCTRL_RESET);
    for (int us = 0; us < 10000; ++us) {
        if (!(rd(s, SMHC_GCTRL) & GCTRL_RESET))
            return 0;
        t113_udelay(1);
    }
    return -ETIMEDOUT;
}

static int smhc_update_clk(struct t113_smhc *s)
{
    wr(s, SMHC_CMD, CMD_START | CMD_UPCLK_ONLY | CMD_WAIT_PRE);
    for (int us = 0; us < 200000; ++us) {
        if (!(rd(s, SMHC_CMD) & CMD_START)) {
            wr(s, SMHC_RINT, rd(s, SMHC_RINT));
            return 0;
        }
        t113_udelay(1);
    }
    return -ETIMEDOUT;
}

static void smhc_set_ios(struct mmc_host *host, uint32_t hz, uint32_t width)
{
    struct t113_smhc *s = host->priv;
    uint32_t div = 0;

    if (hz && hz < SMHC_SRC_HZ)
        div = (SMHC_SRC_HZ + 2u * hz - 1u) / (2u * hz);   /* never faster */
    if (div > CLKCR_DIV_MASK)
        div = CLKCR_DIV_MASK;

    uint32_t clkcr = rd(s, SMHC_CLKCR) & ~CLKCR_ENABLE;
    wr(s, SMHC_CLKCR, clkcr | CLKCR_MASK_D0);
    smhc_update_clk(s);

    clkcr = (clkcr & ~(CLKCR_DIV_MASK | CLKCR_POWERSAVE)) | div;
    wr(s, SMHC_CLKCR, clkcr | CLKCR_ENABLE | CLKCR_MASK_D0);
    smhc_update_clk(s);
    wr(s, SMHC_CLKCR, clkcr | CLKCR_ENABLE);

    wr(s, SMHC_WIDTH, width == 4 ? 1u : 0u);
    s->clock_hz = div ? SMHC_SRC_HZ / (2u * div) : SMHC_SRC_HZ;
}

/* Move the data phase through the FIFO by CPU. 0, or <0 on bus error. */
static int smhc_pio(struct t113_smhc *s, struct mmc_data *d)
{
    uint32_t *p = (uint32_t *)d->buf;
    uint32_t words = d->blksz * d->blocks / 4u;

    for (uint32_t spins = 0; words; ) {
        uint32_t st = rd(s, SMHC_STATUS);
        if (d->write ? !(st & STATUS_FIFO_FULL) : !(st & STATUS_FIFO_EMPTY)) {
            if (d->write)
                wr(s, SMHC_FIFO, *p++);
            else
                *p++ = rd(s, SMHC_FIFO);
            --words;
            spins = 0;
            continue;
        }
        if (rd(s, SMHC_RINT) & RINT_ERR_MASK)
            return -EIO;
        if (++spins > 200000u)          /* ~200 ms without progress */
            return -ETIMEDOUT;
        t113_udelay(1);
    }
    return 0;
}

static int smhc_request(struct mmc_host *host, struct mmc_command *c)
{
    struct t113_smhc *s = host->priv;
    struct mmc_data *d = c->data;
    uint32_t cmd = CMD_START | (c->opcode & 0x3fu);

    if (c->opcode == 0)
        cmd |= CMD_INIT_SEQ;
    if (c->flags & MMC_RSP_PRESENT)
        cmd |= CMD_RESP_EXPIRE;
    if (c->flags & MMC_RSP_136)
        cmd |= CMD_LONG_RESP;
    if (c->flags & MMC_RSP_CRC)
        cmd |= CMD_CHK_CRC;
    if (d) {
        if ((d->blksz * d->blocks) & 3u || ((uintptr_t)d->buf & 3u))
            return -EINVAL;
        cmd |= CMD_DATA | CMD_WAIT_PRE | (d->write ? CMD_WRITE : 0u);
        wr(s, SMHC_GCTRL, rd(s, SMHC_GCTRL) | GCTRL_AHB | GCTRL_FIFO_RST);
        for (int us = 0; us < 1000 && (rd(s, SMHC_GCTRL) & GCTRL_FIFO_RST); ++us)
            t113_udelay(1);
        wr(s, SMHC_BLKSZ, d->blksz);
        wr(s, SMHC_BYTECNT, d->blksz * d->blocks);
    }

    wr(s, SMHC_RINT, 0xffffffffu);
    wr(s, SMHC_ARG, c->arg);
    wr(s, SMHC_CMD, cmd);

    int ret = d ? smhc_pio(s, d) : 0;
    uint32_t want = RINT_CMD_DONE | (d ? RINT_DATA_OVER : 0u);
    uint32_t rint = 0;
    if (ret == 0) {
        ret = -ETIMEDOUT;
        for (int us = 0; us < 200000; ++us) {
            rint = rd(s, SMHC_RINT);
            if (rint & RINT_ERR_MASK) {
                ret = (rint & RINT_RESP_TMO) ? -ETIMEDOUT : -EIO;
                break;
            }
            if ((rint & want) == want) {
                ret = 0;
                break;
            }
            t113_udelay(1);
        }
    } else {
        rint = rd(s, SMHC_RINT);
    }
    s->last_rint = rint;

    if (ret == 0) {
        c->resp[0] = rd(s, SMHC_RESP0);
        if (c->flags & MMC_RSP_136) {
            /* controller returns bits [127:96] in RESP3 */
            c->resp[3] = c->resp[0];
            c->resp[2] = rd(s, SMHC_RESP0 + 4);
            c->resp[1] = rd(s, SMHC_RESP0 + 8);
            c->resp[0] = rd(s, SMHC_RESP0 + 12);
        }
        if (c->flags & MMC_RSP_BUSY) {
            for (int ms = 0; ms < 500 && (rd(s, SMHC_STATUS) & STATUS_CARD_BUSY); ++ms)
                t113_mdelay(1);
        }
    } else {
        /* Errors can wedge the state machine: reset and re-apply clock. */
        smhc_reset(s);
        smhc_set_ios(host, s->clock_hz, rd(s, SMHC_WIDTH) ? 4u : 1u);
    }
    wr(s, SMHC_RINT, 0xffffffffu);
    return ret;
}

/*
 * Card power sequence for an XR829-style SDIO module: 32.768 kHz clock on a
 * CLK_FANOUT pin, then pulse the enable (WL_REG_ON) low -> high.
 */
static void smhc_power(struct mmc_host *host, int on)
{
    struct t113_smhc *s = host->priv;
    const struct t113_mmc_platform_data *pd = s->pdata;

    if (!pd)
        return;
    if (!on) {
        t113_gpio_direction_output(pd->power_gpio, 0);
        return;
    }
    if (pd->fanout >= 0) {
        uint32_t n = (uint32_t)pd->fanout;
        if (!(mmio_read32(CCU_PLL_PERI0) & (1u << 31)))
            t113_uart_puts("mmc: PLL_PERIPH0 off - 32k fanout will be dead\n");
        mmio_write32(CCU_FANOUT_GATE, mmio_read32(CCU_FANOUT_GATE) | (1u << 4));
        uint32_t cfg = mmio_read32(CCU_FANOUT_CFG);
        cfg &= ~(7u << (3u * n));                   /* source 0 = 32k */
        cfg |= 1u << (21u + n);                     /* fanoutN gate */
        mmio_write32(CCU_FANOUT_CFG, cfg);
        t113_pinmux_apply(&pd->fanout_pin, 1);
    }
    t113_gpio_direction_output(pd->power_gpio, 0);
    t113_mdelay(10);
    t113_gpio_direction_output(pd->power_gpio, 1);
    t113_mdelay(pd->power_on_delay_ms ? pd->power_on_delay_ms : 100u);
}

static void dump_reg(const char *name, uint32_t addr)
{
    t113_uart_puts("  ");
    t113_uart_puts(name);
    t113_uart_puts(" = ");
    t113_uart_puthex(mmio_read32(addr));
    t113_uart_putc('\n');
}

static void smhc_dump(struct mmc_host *host)
{
    struct t113_smhc *s = host->priv;
    t113_uart_puts(host->name);
    t113_uart_puts(": diagnostics (last RINT ");
    t113_uart_puthex(s->last_rint);
    t113_uart_puts(", clock ");
    t113_uart_puthex(s->clock_hz);
    t113_uart_puts(" Hz)\n");
    dump_reg("GCTRL", s->base + SMHC_GCTRL);
    dump_reg("CLKCR", s->base + SMHC_CLKCR);
    dump_reg("STATUS", s->base + SMHC_STATUS);
    dump_reg("NTSR", s->base + SMHC_NTSR);
    dump_reg("CCU MMC_CLK", CCU_MMC_CLK(host->index));
    dump_reg("CCU MMC_BGR", CCU_MMC_BGR);
    dump_reg("CCU PLL_PERI0", CCU_PLL_PERI0);
    dump_reg("CCU FANOUT_GATE", CCU_FANOUT_GATE);
    dump_reg("CCU FANOUT_CFG", CCU_FANOUT_CFG);
    dump_reg("PG_CFG0 PG0-7", T113_PIO_BASE + 6u * 0x30u + 0x00u);
    dump_reg("PG_CFG1 PG8-15", T113_PIO_BASE + 6u * 0x30u + 0x04u);
    dump_reg("PG_DAT", T113_PIO_BASE + 6u * 0x30u + 0x10u);
}

static const struct mmc_host_ops smhc_ops = {
    .request = smhc_request,
    .set_ios = smhc_set_ios,
    .power = smhc_power,
    .dump = smhc_dump,
};

static int t113_smhc_probe(struct platform_device *pdev)
{
    const struct resource *mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!mem || mem->start < T113_SMHC0_BASE ||
        (mem->start - T113_SMHC0_BASE) % T113_SMHC_STRIDE)
        return -ENODEV;
    uint32_t idx = (mem->start - T113_SMHC0_BASE) / T113_SMHC_STRIDE;
    if (idx >= MMC_MAX_HOSTS)
        return -ENODEV;

    struct t113_smhc *s = &smhc_state[idx];
    s->base = mem->start;
    s->pdata = pdev->dev.platform_data;

    /* Bus gate + reset, mod clock = HOSC (24 MHz, /2 post-div). */
    uint32_t bgr = mmio_read32(CCU_MMC_BGR);
    mmio_write32(CCU_MMC_BGR, bgr & ~(1u << (16u + idx)));
    t113_udelay(10);
    mmio_write32(CCU_MMC_BGR, bgr | (1u << idx) | (1u << (16u + idx)));
    mmio_write32(CCU_MMC_CLK(idx), 1u << 31);

    if (s->pdata)
        t113_pinmux_apply(s->pdata->pins, s->pdata->num_pins);

    if (smhc_reset(s) < 0)
        return -EIO;
    wr(s, SMHC_HWRST, 0);
    t113_udelay(10);
    wr(s, SMHC_HWRST, 1);
    wr(s, SMHC_NTSR, rd(s, SMHC_NTSR) | NTSR_NEW_MODE);
    wr(s, SMHC_TMOUT, 0xffffff40u);
    wr(s, SMHC_IMASK, 0);
    wr(s, SMHC_RINT, 0xffffffffu);

    s->host.index = (int)idx;
    s->host.name = smhc_names[idx];
    s->host.dev = &pdev->dev;
    s->host.ops = &smhc_ops;
    s->host.priv = s;
    s->host.f_init = 400000u;
    smhc_set_ios(&s->host, s->host.f_init, 1);

    int ret = mmc_add_host(&s->host);
    if (ret < 0)
        return ret;
    platform_set_drvdata(pdev, &s->host);
    platform_dev_info(pdev, "SMHC host ready (card scan deferred to rescan)");
    return 0;
}

static void t113_smhc_remove(struct platform_device *pdev)
{
    struct mmc_host *host = platform_get_drvdata(pdev);
    mmc_remove_host(host);
    smhc_power(host, 0);
}

static const struct of_device_id t113_smhc_of_match[] = {
    { .compatible = "allwinner,sun20i-d1-mmc" },
    { 0 },
};

struct platform_driver t113_smhc_driver = {
    .probe = t113_smhc_probe,
    .remove = t113_smhc_remove,
    .driver = { .name = "sunxi-mmc" },
    .of_match_table = t113_smhc_of_match,
};
