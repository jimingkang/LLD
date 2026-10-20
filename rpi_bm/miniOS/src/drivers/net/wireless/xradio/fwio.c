/*
 * XRadio firmware download, after the xradio driver's fwio.c
 * xradio_load_firmware():
 *   CONFIG hw-type check -> SDD reference clock -> DPLL in TSET_GEN ->
 *   CONTROL.WUP, wait RDY -> CONFIG.ACCESS_MODE (direct) -> DPLL_CTRL sync
 *   -> boot_xr829.bin word-by-word to AHB 0x08000000 ->
 *   release CPU, handshake "are you here" -> fw_xr829.bin in 1 KiB blocks
 *   through the 32 KiB download FIFO at APB 0x09004000 (put/get ring) ->
 *   status SUCCESS -> CONFIG IRQ enables, clear ACCESS_MODE (queue mode).
 * The images are read from /boot (FAT32); they are proprietary and not
 * part of the git tree.  The SDD stays loaded for WSM CONFIGURATION.
 */
#include "platform.h"
#include "device.h"
#include "mmc.h"
#include "fs/vfs.h"
#include "net/netutil.h"
#include "xradio.h"

/* Device memory map / download control block (hwio.h) */
#define AHB_MEMORY_ADDRESS          0x08000000u
#define APB_ADDR(a)                 (0x09000000u + (a))
#define DOWNLOAD_FIFO_OFFSET        0x00004000u
#define DOWNLOAD_FIFO_SIZE          0x00008000u
#define DOWNLOAD_CTRL_OFFSET        0x0000ff80u
#define DOWNLOAD_IMAGE_SIZE_REG     (DOWNLOAD_CTRL_OFFSET + 0x00u)
#define DOWNLOAD_FLAGS_REG          (DOWNLOAD_CTRL_OFFSET + 0x04u)
#define DOWNLOAD_PUT_REG            (DOWNLOAD_CTRL_OFFSET + 0x08u)
#define DOWNLOAD_TRACE_PC_REG       (DOWNLOAD_CTRL_OFFSET + 0x0cu)
#define DOWNLOAD_GET_REG            (DOWNLOAD_CTRL_OFFSET + 0x10u)
#define DOWNLOAD_STATUS_REG         (DOWNLOAD_CTRL_OFFSET + 0x14u)
#define DOWNLOAD_BLOCK_SIZE         1024u
#define DOWNLOAD_ARE_YOU_HERE       0x87654321u
#define DOWNLOAD_I_AM_HERE          0x12345678u
#define DOWNLOAD_PENDING            0xffffffffu
#define DOWNLOAD_SUCCESS            0u

#define PWRCTRL_WLAN_ADDRESS        0x0ac80000u
#define PWRCTRL_WLAN_START_CFG      (PWRCTRL_WLAN_ADDRESS + 0x18u)
#define PWRCTRL_WLAN_COMMON_CFG     (PWRCTRL_WLAN_ADDRESS + 0x178u)
#define PWRCTRL_WLAN_DPLL_CTRL      (PWRCTRL_WLAN_ADDRESS + 0x154u)
#define PWRCTRL_COMMON_REG_DONE     0x1u
#define PWRCTRL_COMMON_REG_BT       0x4u
#define PWRCTRL_COMMON_REG_ARBT     0x8u

#define DPLL_INIT_VAL_XRADIO        0x0ec4f121u
#define SDD_REFERENCE_FREQUENCY_ELT_ID 0xc5u

static uint32_t dl_buf[DOWNLOAD_BLOCK_SIZE / 4u];  /* 4-byte aligned */

static void say(struct sdio_func *func, const char *msg)
{
    t113_uart_puts(func->dev_name);
    t113_uart_puts(": ");
    t113_uart_puts(msg);
}

static void say_hex(struct sdio_func *func, const char *msg, uint32_t v)
{
    say(func, msg);
    t113_uart_puthex(v);
    t113_uart_putc('\n');
}

struct firmware_image {
    void *data;
    uint32_t size;
};

static struct firmware_image *need_image(struct sdio_func *f,
                                         const char *path,
                                         struct firmware_image *image)
{
    struct file *file = t113_vfs_open(path, VFS_O_RDONLY);
    uint32_t size = file ? t113_vfs_file_size(file) : 0;
    uint32_t pages = (size + 4095u) / 4096u;
    void *data = pages ? t113_alloc_pages(pages, 1) : 0;
    int got = data ? t113_vfs_read(file, data, size) : -1;
    t113_vfs_close(file);
    if (got != (int)size) {
        if (data) t113_free_pages(data, pages);
        say(f, "cannot load ");
        t113_uart_puts(path);
        t113_uart_putc('\n');
        return 0;
    }
    image->data = data;
    image->size = size;
    say(f, "loaded "); t113_uart_puts(path);
    t113_uart_puts(" bytes "); net_putdec(size); t113_uart_putc('\n');
    return image;
}

/* SDD = list of {u8 id, u8 len, data[len]}; take the reference clock. */
static uint32_t parse_sdd(struct sdio_func *f, const uint8_t *p, uint32_t size)
{
    uint32_t dpll = DPLL_INIT_VAL_XRADIO, off = 0, ref = 0;

    while (off + 2u <= size) {
        uint8_t id = p[off], len = p[off + 1u];
        if (off + 2u + len > size)
            break;
        if (id == SDD_REFERENCE_FREQUENCY_ELT_ID && len >= 2u)
            ref = (uint32_t)p[off + 2u] | ((uint32_t)p[off + 3u] << 8);
        off += 2u + len;
    }
    switch (ref) {
    case 0x32c8: dpll = 0x1d89d241u; break;     /* 13 MHz */
    case 0x3e80: dpll = 0x1e1u; break;          /* 16 MHz */
    case 0x41a0: dpll = 0x124931c1u; break;     /* 16.8 MHz */
    case 0x4b00: dpll = 0x191u; break;          /* 19.2 MHz */
    case 0x5dc0: dpll = 0x141u; break;          /* 24 MHz */
    case 0x6590: dpll = 0x0ec4f121u; break;     /* 26 MHz */
    case 0x8340: dpll = 0x92490e1u; break;      /* 33.6 MHz */
    case 0x9600: dpll = 0x100010c1u; break;     /* 38.4 MHz */
    case 0x9c40: dpll = 0xc1u; break;           /* 40 MHz */
    case 0xbb80: dpll = 0xa1u; break;           /* 48 MHz */
    case 0xcb20: dpll = 0x7627091u; break;      /* 52 MHz */
    default: break;
    }
    say(f, "SDD ref clock ");
    net_putdec(ref);
    t113_uart_puts(" kHz, DPLL ");
    t113_uart_puthex(dpll);
    t113_uart_putc('\n');
    return dpll;
}

static uint32_t dllctrl_convert(uint32_t dpll)
{
    return (((dpll >> 31) & 0x1u) << 0) |      /* config */
           (((dpll >> 29) & 0x3u) << 1) |      /* dither */
           (((dpll >> 12) & 0x1u) << 3) |      /* frac ctrl */
           (((dpll >> 13) & 0xffffu) << 4) |   /* frac */
           (((dpll >> 4) & 0xffu) << 20);      /* divn */
}

/* fwio.c xradio_update_dpllctrl() (SUPPORT_DPLL_CHECK is on in Tina). */
static int update_dpllctrl(struct sdio_func *f, uint32_t want)
{
    uint32_t v = 0, rd = 0;
    int ret = 0;

    xradio_ahb_read_32(f, PWRCTRL_WLAN_START_CFG, &v);
    for (uint32_t i = 0; ; ++i) {
        if ((ret = xradio_ahb_read_32(f, PWRCTRL_WLAN_COMMON_CFG, &v)) < 0)
            break;
        if (v & PWRCTRL_COMMON_REG_DONE) {
            xradio_ahb_read_32(f, PWRCTRL_WLAN_DPLL_CTRL, &rd);
            if (rd == want)
                break;                              /* already synced */
        }
        if ((v & PWRCTRL_COMMON_REG_ARBT) && !(v & PWRCTRL_COMMON_REG_BT)) {
            xradio_ahb_read_32(f, PWRCTRL_WLAN_DPLL_CTRL, &rd);
            if (rd != want) {
                say_hex(f, "DPLL_CTRL was ", rd);
                xradio_ahb_write_32(f, PWRCTRL_WLAN_DPLL_CTRL, want | 1u);
                t113_mdelay(5);
            }
            xradio_ahb_write_32(f, PWRCTRL_WLAN_COMMON_CFG, PWRCTRL_COMMON_REG_DONE);
            break;
        }
        if (i >= 100) {
            say_hex(f, "DPLL access timeout, COMMON_CFG ", v);
            ret = -ETIMEDOUT;
            break;
        }
        t113_mdelay(i);
    }
    xradio_ahb_write_32(f, PWRCTRL_WLAN_START_CFG, 0);
    return ret;
}

static int download_bootloader(struct sdio_func *f,
                               const struct firmware_image *e)
{
    const uint32_t *w = (const uint32_t *)e->data;
    for (uint32_t i = 0; i < e->size / 4u; ++i) {
        int ret = xradio_ahb_write_32(f, AHB_MEMORY_ADDRESS + 4u * i, w[i]);
        if (ret < 0) {
            say_hex(f, "bootloader write failed at word ", i);
            return ret;
        }
    }
    say(f, "bootloader loaded (");
    net_putdec(e->size);
    t113_uart_puts(" bytes)\n");
    return 0;
}

#define CHK(expr) do { if ((ret = (expr)) < 0) goto io_error; } while (0)

static int download_firmware(struct sdio_func *f,
                             const struct firmware_image *e)
{
    const uint8_t *img = (const uint8_t *)e->data;
    uint32_t v = 0, put = 0, get = 0, i;
    int ret;

    CHK(xradio_apb_write_32(f, APB_ADDR(DOWNLOAD_IMAGE_SIZE_REG), DOWNLOAD_ARE_YOU_HERE));
    CHK(xradio_apb_write_32(f, APB_ADDR(DOWNLOAD_PUT_REG), 0));
    CHK(xradio_apb_write_32(f, APB_ADDR(DOWNLOAD_GET_REG), 0));
    CHK(xradio_apb_write_32(f, APB_ADDR(DOWNLOAD_STATUS_REG), DOWNLOAD_PENDING));
    CHK(xradio_apb_write_32(f, APB_ADDR(DOWNLOAD_FLAGS_REG), 0));

    /* Release the CPU from reset and enable its clock: bootloader runs. */
    CHK(xradio_reg_bit_op(f, HIF_CONFIG_REG_ID, 0, HIF_CONFIG_CPU_RESET_BIT));
    CHK(xradio_reg_bit_op(f, HIF_CONFIG_REG_ID, 0, HIF_CONFIG_CPU_CLK_DIS_BIT));

    for (i = 0; i < 100; ++i) {
        CHK(xradio_apb_read_32(f, APB_ADDR(DOWNLOAD_IMAGE_SIZE_REG), &v));
        if (v == DOWNLOAD_I_AM_HERE)
            break;
        t113_mdelay(10);
    }
    if (v != DOWNLOAD_I_AM_HERE) {
        say_hex(f, "bootloader not ready, IMAGE_SIZE reads ", v);
        return -ETIMEDOUT;
    }
    say(f, "bootloader answered I_AM_HERE\n");

    /* DOWNLOAD_BLOCK_SIZE (1024) must be a multiple of the SDIO block. */
    if (f->blksz > DOWNLOAD_BLOCK_SIZE || DOWNLOAD_BLOCK_SIZE % f->blksz)
        CHK(sdio_set_block_size(f, DOWNLOAD_BLOCK_SIZE / 2u));

    CHK(xradio_apb_write_32(f, APB_ADDR(DOWNLOAD_IMAGE_SIZE_REG), e->size));

    uint32_t blocks = (e->size + DOWNLOAD_BLOCK_SIZE - 1u) / DOWNLOAD_BLOCK_SIZE;
    for (uint32_t b = 0; b < blocks; ++b) {
        CHK(xradio_apb_read_32(f, APB_ADDR(DOWNLOAD_STATUS_REG), &v));
        if (v != DOWNLOAD_PENDING) {
            say_hex(f, "bootloader reported error ", v);
            return -EIO;
        }

        uint32_t n = e->size - put;
        if (n > DOWNLOAD_BLOCK_SIZE)
            n = DOWNLOAD_BLOCK_SIZE;
        uint8_t *dst = (uint8_t *)dl_buf;
        for (uint32_t k = 0; k < DOWNLOAD_BLOCK_SIZE; ++k)
            dst[k] = k < n ? img[put + k] : 0;      /* pad the last block */

        /* Wait for room in the 32 KiB ring (put - get <= 31 KiB). */
        for (i = 0; i < 100; ++i) {
            CHK(xradio_apb_read_32(f, APB_ADDR(DOWNLOAD_GET_REG), &get));
            if (put - get <= DOWNLOAD_FIFO_SIZE - DOWNLOAD_BLOCK_SIZE)
                break;
            t113_mdelay(i);
        }
        if (put - get > DOWNLOAD_FIFO_SIZE - DOWNLOAD_BLOCK_SIZE) {
            say(f, "timeout waiting for download FIFO\n");
            return -ETIMEDOUT;
        }

        CHK(xradio_apb_write(f, APB_ADDR(DOWNLOAD_FIFO_OFFSET +
                                  (put & (DOWNLOAD_FIFO_SIZE - 1u))),
                      dl_buf, DOWNLOAD_BLOCK_SIZE));
        put += n;
        CHK(xradio_apb_write_32(f, APB_ADDR(DOWNLOAD_PUT_REG), put));
        if ((b & 31u) == 31u) {
            say(f, "firmware ");
            net_putdec(put / 1024u);
            t113_uart_puts(" KiB\n");
        }
    }

    for (i = 0; i < 300; i += 1u + i / 2u) {
        CHK(xradio_apb_read_32(f, APB_ADDR(DOWNLOAD_STATUS_REG), &v));
        if (v != DOWNLOAD_PENDING)
            break;
        t113_mdelay(i);
    }
    if (v != DOWNLOAD_SUCCESS) {
        uint32_t pc = 0;
        xradio_apb_read_32(f, APB_ADDR(DOWNLOAD_TRACE_PC_REG), &pc);
        say(f, "firmware download failed, status ");
        t113_uart_puthex(v);
        t113_uart_puts(" trace pc ");
        t113_uart_puthex(pc);
        t113_uart_putc('\n');
        return -EIO;
    }
    say(f, "firmware download complete (");
    net_putdec(e->size);
    t113_uart_puts(" bytes)\n");
    return 0;

io_error:
    say(f, "SDIO error during firmware download\n");
    return ret;
}

int xradio_load_firmware(struct xradio_common *hw_priv)
{
    struct sdio_func *f = hw_priv->func;
    static struct firmware_image boot_image, fw_image, sdd_image;
    struct firmware_image *boot = need_image(f, "/boot/boot_xr829.bin", &boot_image);
    struct firmware_image *fw = need_image(f, "/boot/fw_xr829.bin", &fw_image);
    struct firmware_image *sdd = need_image(f, "/boot/sdd_xr829.bin", &sdd_image);
    uint32_t v = 0;
    int ret;

    if (!boot || !fw || !sdd)
        return -ENODEV;
    hw_priv->sdd = sdd->data;
    hw_priv->sdd_len = sdd->size;

    CHK(xradio_reg_read_32(f, HIF_CONFIG_REG_ID, &v));
    if (((v >> 24) & 0x4u) != 0x4u) {
        say_hex(f, "not an XRadio HIF (CONFIG) ", v);
        return -ENODEV;
    }

    uint32_t dpll = parse_sdd(f, (const uint8_t *)sdd->data,
                              sdd->size);
    CHK(xradio_reg_write_32(f, HIF_TSET_GEN_R_W_REG_ID, dpll));
    t113_mdelay(5);
    CHK(xradio_reg_read_32(f, HIF_TSET_GEN_R_W_REG_ID, &v));
    if (v != dpll) {
        say_hex(f, "DPLL register did not stick, read ", v);
        return -EIO;
    }

    CHK(xradio_reg_bit_op(f, HIF_CONTROL_REG_ID, HIF_CTRL_WUP_BIT, 0));
    for (uint32_t i = 0; i < 300; i += 1u + i / 2u) {
        CHK(xradio_reg_read_32(f, HIF_CONTROL_REG_ID, &v));
        if (v & HIF_CTRL_RDY_BIT)
            break;
        t113_mdelay(i);
    }
    if (!(v & HIF_CTRL_RDY_BIT)) {
        say_hex(f, "device did not wake up, CONTROL ", v);
        return -ETIMEDOUT;
    }
    say(f, "device awake\n");

    CHK(xradio_reg_bit_op(f, HIF_CONFIG_REG_ID, HIF_CONFIG_ACCESS_MODE_BIT, 0));
    update_dpllctrl(f, dllctrl_convert(dpll));

    if ((ret = download_bootloader(f, boot)) < 0 ||
        (ret = download_firmware(f, fw)) < 0)
        return ret;

    /* Device IRQ enables live in CONFIG; then switch to queue (message) mode. */
    CHK(xradio_reg_bit_op(f, HIF_CONFIG_REG_ID, HIF_CONF_IRQ_RDY_ENABLE, 0));
    CHK(xradio_reg_bit_op(f, HIF_CONFIG_REG_ID, 0, HIF_CONFIG_ACCESS_MODE_BIT));
    t113_mdelay(10);
    return 0;

io_error:
    say(f, "SDIO error during firmware load\n");
    return ret;
}

#undef CHK
