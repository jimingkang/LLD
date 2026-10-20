/*
 * XRadio XR829 WiFi (SDIO function 1): enumeration + firmware download.
 *
 * XR829 on the 100ASK T113-Pro enumerates as 0x0a9e:0x2282 (measured);
 * the older XR819 is 0x0020:0x2281 (open-source xradio driver).
 *
 * Register access follows xradio hwio.c: SDIO address =
 *   (buf_id << 7) | (reg_id << 2)
 * HIF registers work before any firmware is loaded. Device memory is
 * reached indirectly: write the address to SRAM_BASE_ADDR, then stream
 * through SRAM_DPORT (APB, shared RAM) or AHB_DPORT (AHB, CPU memory);
 * reads first set a PREFETCH bit in CONFIG and wait for it to clear.
 *
 * Firmware download follows xradio fwio.c xradio_load_firmware():
 *   CONFIG hw-type check -> SDD reference clock -> DPLL in TSET_GEN ->
 *   CONTROL.WUP, wait RDY -> CONFIG.ACCESS_MODE (direct) -> DPLL_CTRL sync
 *   -> boot_xr829.bin word-by-word to AHB 0x08000000 ->
 *   release CPU, handshake "are you here" -> fw_xr829.bin in 1 KiB blocks
 *   through the 32 KiB download FIFO at APB 0x09004000 (put/get ring) ->
 *   status SUCCESS -> CONFIG IRQ enables, clear ACCESS_MODE (queue mode).
 * The three images come from the SD bootpack (see miniBoot bootpack.h);
 * they are proprietary and are not part of the git tree.
 * After boot the firmware queues a WSM "startup" indication; it is read
 * and its header printed as proof of life. WSM/802.11 are not done yet.
 */
#include "platform.h"
#include "mmc.h"
#include "board.h"
#include "fs/vfs.h"
#include "xradio/wsm.h"
#include "xradio/sta.h"

#define XR829_BLOCK_SIZE    512u
#define XR829_FAST_CLOCK    12000000u   /* default-speed, 1-bit */

#define BIT(n)              (1u << (n))

/* HIF register ids (hwio.h) */
#define HIF_CONFIG_REG_ID           0x0u
#define HIF_CONTROL_REG_ID          0x1u
#define HIF_IN_OUT_QUEUE_REG_ID     0x2u
#define HIF_AHB_DPORT_REG_ID        0x3u
#define HIF_SRAM_BASE_ADDR_REG_ID   0x4u
#define HIF_SRAM_DPORT_REG_ID       0x5u
#define HIF_TSET_GEN_R_W_REG_ID     0x6u
#define HIF_ADDR(buf_id, id)        ((((uint32_t)(buf_id) & 0x1fu) << 7) | ((id) << 2))

#define HIF_CTRL_NEXT_LEN_MASK      0x0fffu
#define HIF_CTRL_WUP_BIT            BIT(12)
#define HIF_CTRL_RDY_BIT            BIT(13)

#define HIF_CONFIG_ACCESS_MODE_BIT  BIT(10)
#define HIF_CONFIG_AHB_PFETCH_BIT   BIT(11)
#define HIF_CONFIG_CPU_CLK_DIS_BIT  BIT(12)
#define HIF_CONFIG_PFETCH_BIT       BIT(13)
#define HIF_CONFIG_CPU_RESET_BIT    BIT(14)
#define HIF_CONF_IRQ_RDY_ENABLE     (BIT(16) | BIT(17))

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

struct xr829 {
    struct sdio_func *func;
    int enabled;
    uint32_t config;
    int cmd53_ok;
    int fw_ok;
    const void *sdd;
    uint32_t sdd_len;
    uint32_t buf_id_rx;         /* queue-mode read buffer id (0..3) */
    uint32_t buf_id_tx;         /* queue-mode write buffer id (0..31) */
};

static struct xr829 xr829_dev;
static uint32_t xr829_dl_buf[DOWNLOAD_BLOCK_SIZE / 4u];  /* 4-byte aligned */

static void puthex16(uint32_t v)
{
    static const char hex[] = "0123456789abcdef";
    t113_uart_puts("0x");
    for (int s = 12; s >= 0; s -= 4)
        t113_uart_putc(hex[(v >> s) & 15u]);
}

static void putdec(uint32_t v)
{
    char b[11];
    int i = 10;
    b[i] = '\0';
    do {
        b[--i] = (char)('0' + v % 10u);
        v /= 10u;
    } while (v && i);
    t113_uart_puts(&b[i]);
}

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

/* ------------------------------------------------------- HIF registers */

int xr829_reg_read32(struct sdio_func *func, uint32_t reg_id, uint32_t *val)
{
    uint32_t buf[1] = { 0 };
    int ret = sdio_memcpy_fromio(func, buf, HIF_ADDR(0, reg_id), 4);
    if (!ret)
        *val = buf[0];                  /* little endian on both sides */
    return ret;
}

int xr829_reg_write32(struct sdio_func *func, uint32_t reg_id, uint32_t val)
{
    uint32_t buf[1] = { val };
    return sdio_memcpy_toio(func, HIF_ADDR(0, reg_id), buf, 4);
}

static int reg_bit_op(struct sdio_func *f, uint32_t reg_id, uint32_t set,
                      uint32_t clr)
{
    uint32_t v;
    int ret = xr829_reg_read32(f, reg_id, &v);
    if (ret < 0 && reg_id == HIF_CONTROL_REG_ID)
        ret = xr829_reg_read32(f, reg_id, &v);      /* hwio.c retries once */
    if (ret < 0)
        return ret;
    return xr829_reg_write32(f, reg_id, (v & ~clr) | set);
}

/* ------------------------------------------- indirect memory access */

/* addr -> SRAM_BASE_ADDR, then len bytes through port_id. */
static int indirect_write(struct sdio_func *f, uint32_t addr, uint32_t port_id,
                          const void *buf, uint32_t len)
{
    int ret = xr829_reg_write32(f, HIF_SRAM_BASE_ADDR_REG_ID, addr);
    if (ret < 0)
        return ret;
    return sdio_memcpy_toio(f, HIF_ADDR(0, port_id), buf, len);
}

static int indirect_read(struct sdio_func *f, uint32_t addr, uint32_t port_id,
                         uint32_t prefetch, void *buf, uint32_t len)
{
    uint32_t cfg;
    int ret;

    if ((ret = xr829_reg_write32(f, HIF_SRAM_BASE_ADDR_REG_ID, addr)) < 0 ||
        (ret = xr829_reg_read32(f, HIF_CONFIG_REG_ID, &cfg)) < 0 ||
        (ret = xr829_reg_write32(f, HIF_CONFIG_REG_ID, cfg | prefetch)) < 0)
        return ret;
    for (uint32_t i = 0; i < 20; ++i) {
        if ((ret = xr829_reg_read32(f, HIF_CONFIG_REG_ID, &cfg)) < 0)
            return ret;
        if (!(cfg & prefetch))
            break;
        t113_mdelay(i);
    }
    if (cfg & prefetch)
        return -ETIMEDOUT;
    return sdio_memcpy_fromio(f, buf, HIF_ADDR(0, port_id), len);
}

static int apb_write(struct sdio_func *f, uint32_t addr, const void *buf,
                     uint32_t len)
{
    return indirect_write(f, addr, HIF_SRAM_DPORT_REG_ID, buf, len);
}

static int apb_write32(struct sdio_func *f, uint32_t addr, uint32_t val)
{
    uint32_t b[1] = { val };
    return apb_write(f, addr, b, 4);
}

static int apb_read32(struct sdio_func *f, uint32_t addr, uint32_t *val)
{
    uint32_t b[1] = { 0 };
    int ret = indirect_read(f, addr, HIF_SRAM_DPORT_REG_ID,
                            HIF_CONFIG_PFETCH_BIT, b, 4);
    *val = b[0];
    return ret;
}

static int ahb_write32(struct sdio_func *f, uint32_t addr, uint32_t val)
{
    uint32_t b[1] = { val };
    return indirect_write(f, addr, HIF_AHB_DPORT_REG_ID, b, 4);
}

static int ahb_read32(struct sdio_func *f, uint32_t addr, uint32_t *val)
{
    uint32_t b[1] = { 0 };
    int ret = indirect_read(f, addr, HIF_AHB_DPORT_REG_ID,
                            HIF_CONFIG_AHB_PFETCH_BIT, b, 4);
    *val = b[0];
    return ret;
}

/* ---------------------------------------------------------- self test */

/* CMD53 sanity check on registers that need no firmware. */
static int xr829_cmd53_selftest(struct sdio_func *func, int verbose)
{
    static const uint32_t patterns[] = { 0xa5a55a5au, 0x12345678u, 0x0u };
    uint32_t cfg1 = 0, cfg2 = 0, ctrl = 0, saved = 0, v = 0;
    int ret;

    if ((ret = xr829_reg_read32(func, HIF_CONFIG_REG_ID, &cfg1)) < 0 ||
        (ret = xr829_reg_read32(func, HIF_CONFIG_REG_ID, &cfg2)) < 0) {
        say(func, "CMD53 read of HIF_CONFIG failed\n");
        return ret;
    }
    xr829_reg_read32(func, HIF_CONTROL_REG_ID, &ctrl);
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
    xr829_dev.config = cfg1;

    xr829_reg_read32(func, HIF_TSET_GEN_R_W_REG_ID, &saved);
    for (uint32_t i = 0; i < sizeof(patterns) / sizeof(patterns[0]); ++i) {
        if ((ret = xr829_reg_write32(func, HIF_TSET_GEN_R_W_REG_ID, patterns[i])) < 0 ||
            (ret = xr829_reg_read32(func, HIF_TSET_GEN_R_W_REG_ID, &v)) < 0) {
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
    xr829_reg_write32(func, HIF_TSET_GEN_R_W_REG_ID, saved);
    if (verbose)
        say(func, "CMD53 write/read-back OK (HIF_TSET_GEN, 3 patterns)\n");
    return 0;
}

/* ------------------------------------------------------ firmware load */

struct firmware_image {
    void *data;
    uint32_t size;
};

static struct firmware_image *need_image(struct sdio_func *f,
                                         const char *path,
                                         struct firmware_image *image)
{
    struct vfs_file *file = t113_vfs_open(path, VFS_O_RDONLY);
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
    t113_uart_puts(" bytes "); putdec(size); t113_uart_putc('\n');
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
    putdec(ref);
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

    ahb_read32(f, PWRCTRL_WLAN_START_CFG, &v);
    for (uint32_t i = 0; ; ++i) {
        if ((ret = ahb_read32(f, PWRCTRL_WLAN_COMMON_CFG, &v)) < 0)
            break;
        if (v & PWRCTRL_COMMON_REG_DONE) {
            ahb_read32(f, PWRCTRL_WLAN_DPLL_CTRL, &rd);
            if (rd == want)
                break;                              /* already synced */
        }
        if ((v & PWRCTRL_COMMON_REG_ARBT) && !(v & PWRCTRL_COMMON_REG_BT)) {
            ahb_read32(f, PWRCTRL_WLAN_DPLL_CTRL, &rd);
            if (rd != want) {
                say_hex(f, "DPLL_CTRL was ", rd);
                ahb_write32(f, PWRCTRL_WLAN_DPLL_CTRL, want | 1u);
                t113_mdelay(5);
            }
            ahb_write32(f, PWRCTRL_WLAN_COMMON_CFG, PWRCTRL_COMMON_REG_DONE);
            break;
        }
        if (i >= 100) {
            say_hex(f, "DPLL access timeout, COMMON_CFG ", v);
            ret = -ETIMEDOUT;
            break;
        }
        t113_mdelay(i);
    }
    ahb_write32(f, PWRCTRL_WLAN_START_CFG, 0);
    return ret;
}

static int download_bootloader(struct sdio_func *f,
                               const struct firmware_image *e)
{
    const uint32_t *w = (const uint32_t *)e->data;
    for (uint32_t i = 0; i < e->size / 4u; ++i) {
        int ret = ahb_write32(f, AHB_MEMORY_ADDRESS + 4u * i, w[i]);
        if (ret < 0) {
            say_hex(f, "bootloader write failed at word ", i);
            return ret;
        }
    }
    say(f, "bootloader loaded (");
    putdec(e->size);
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

    CHK(apb_write32(f, APB_ADDR(DOWNLOAD_IMAGE_SIZE_REG), DOWNLOAD_ARE_YOU_HERE));
    CHK(apb_write32(f, APB_ADDR(DOWNLOAD_PUT_REG), 0));
    CHK(apb_write32(f, APB_ADDR(DOWNLOAD_GET_REG), 0));
    CHK(apb_write32(f, APB_ADDR(DOWNLOAD_STATUS_REG), DOWNLOAD_PENDING));
    CHK(apb_write32(f, APB_ADDR(DOWNLOAD_FLAGS_REG), 0));

    /* Release the CPU from reset and enable its clock: bootloader runs. */
    CHK(reg_bit_op(f, HIF_CONFIG_REG_ID, 0, HIF_CONFIG_CPU_RESET_BIT));
    CHK(reg_bit_op(f, HIF_CONFIG_REG_ID, 0, HIF_CONFIG_CPU_CLK_DIS_BIT));

    for (i = 0; i < 100; ++i) {
        CHK(apb_read32(f, APB_ADDR(DOWNLOAD_IMAGE_SIZE_REG), &v));
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

    CHK(apb_write32(f, APB_ADDR(DOWNLOAD_IMAGE_SIZE_REG), e->size));

    uint32_t blocks = (e->size + DOWNLOAD_BLOCK_SIZE - 1u) / DOWNLOAD_BLOCK_SIZE;
    for (uint32_t b = 0; b < blocks; ++b) {
        CHK(apb_read32(f, APB_ADDR(DOWNLOAD_STATUS_REG), &v));
        if (v != DOWNLOAD_PENDING) {
            say_hex(f, "bootloader reported error ", v);
            return -EIO;
        }

        uint32_t n = e->size - put;
        if (n > DOWNLOAD_BLOCK_SIZE)
            n = DOWNLOAD_BLOCK_SIZE;
        uint8_t *dst = (uint8_t *)xr829_dl_buf;
        for (uint32_t k = 0; k < DOWNLOAD_BLOCK_SIZE; ++k)
            dst[k] = k < n ? img[put + k] : 0;      /* pad the last block */

        /* Wait for room in the 32 KiB ring (put - get <= 31 KiB). */
        for (i = 0; i < 100; ++i) {
            CHK(apb_read32(f, APB_ADDR(DOWNLOAD_GET_REG), &get));
            if (put - get <= DOWNLOAD_FIFO_SIZE - DOWNLOAD_BLOCK_SIZE)
                break;
            t113_mdelay(i);
        }
        if (put - get > DOWNLOAD_FIFO_SIZE - DOWNLOAD_BLOCK_SIZE) {
            say(f, "timeout waiting for download FIFO\n");
            return -ETIMEDOUT;
        }

        CHK(apb_write(f, APB_ADDR(DOWNLOAD_FIFO_OFFSET +
                                  (put & (DOWNLOAD_FIFO_SIZE - 1u))),
                      xr829_dl_buf, DOWNLOAD_BLOCK_SIZE));
        put += n;
        CHK(apb_write32(f, APB_ADDR(DOWNLOAD_PUT_REG), put));
        if ((b & 31u) == 31u) {
            say(f, "firmware ");
            putdec(put / 1024u);
            t113_uart_puts(" KiB\n");
        }
    }

    for (i = 0; i < 300; i += 1u + i / 2u) {
        CHK(apb_read32(f, APB_ADDR(DOWNLOAD_STATUS_REG), &v));
        if (v != DOWNLOAD_PENDING)
            break;
        t113_mdelay(i);
    }
    if (v != DOWNLOAD_SUCCESS) {
        uint32_t pc = 0;
        apb_read32(f, APB_ADDR(DOWNLOAD_TRACE_PC_REG), &pc);
        say(f, "firmware download failed, status ");
        t113_uart_puthex(v);
        t113_uart_puts(" trace pc ");
        t113_uart_puthex(pc);
        t113_uart_putc('\n');
        return -EIO;
    }
    say(f, "firmware download complete (");
    putdec(e->size);
    t113_uart_puts(" bytes)\n");
    return 0;

io_error:
    say(f, "SDIO error during firmware download\n");
    return ret;
}

static int xr829_load_firmware(struct sdio_func *f)
{
    static struct firmware_image boot_image, fw_image, sdd_image;
    struct firmware_image *boot = need_image(f, "/boot/boot_xr829.bin", &boot_image);
    struct firmware_image *fw = need_image(f, "/boot/fw_xr829.bin", &fw_image);
    struct firmware_image *sdd = need_image(f, "/boot/sdd_xr829.bin", &sdd_image);
    uint32_t v = 0;
    int ret;

    if (!boot || !fw || !sdd)
        return -ENODEV;
    xr829_dev.sdd = sdd->data;
    xr829_dev.sdd_len = sdd->size;

    CHK(xr829_reg_read32(f, HIF_CONFIG_REG_ID, &v));
    if (((v >> 24) & 0x4u) != 0x4u) {
        say_hex(f, "not an XRadio HIF (CONFIG) ", v);
        return -ENODEV;
    }

    uint32_t dpll = parse_sdd(f, (const uint8_t *)sdd->data,
                              sdd->size);
    CHK(xr829_reg_write32(f, HIF_TSET_GEN_R_W_REG_ID, dpll));
    t113_mdelay(5);
    CHK(xr829_reg_read32(f, HIF_TSET_GEN_R_W_REG_ID, &v));
    if (v != dpll) {
        say_hex(f, "DPLL register did not stick, read ", v);
        return -EIO;
    }

    CHK(reg_bit_op(f, HIF_CONTROL_REG_ID, HIF_CTRL_WUP_BIT, 0));
    for (uint32_t i = 0; i < 300; i += 1u + i / 2u) {
        CHK(xr829_reg_read32(f, HIF_CONTROL_REG_ID, &v));
        if (v & HIF_CTRL_RDY_BIT)
            break;
        t113_mdelay(i);
    }
    if (!(v & HIF_CTRL_RDY_BIT)) {
        say_hex(f, "device did not wake up, CONTROL ", v);
        return -ETIMEDOUT;
    }
    say(f, "device awake\n");

    CHK(reg_bit_op(f, HIF_CONFIG_REG_ID, HIF_CONFIG_ACCESS_MODE_BIT, 0));
    update_dpllctrl(f, dllctrl_convert(dpll));

    if ((ret = download_bootloader(f, boot)) < 0 ||
        (ret = download_firmware(f, fw)) < 0)
        return ret;

    /* Device IRQ enables live in CONFIG; then switch to queue (message) mode. */
    CHK(reg_bit_op(f, HIF_CONFIG_REG_ID, HIF_CONF_IRQ_RDY_ENABLE, 0));
    CHK(reg_bit_op(f, HIF_CONFIG_REG_ID, 0, HIF_CONFIG_ACCESS_MODE_BIT));
    t113_mdelay(10);
    xr829_reg_read32(f, HIF_CONFIG_REG_ID, &v);
    xr829_dev.buf_id_rx = 0;
    xr829_dev.buf_id_tx = 0;
    return 0;

io_error:
    say(f, "SDIO error during firmware load\n");
    return ret;
}

#undef CHK

/*
 * Proof of life: wait for the firmware's first WSM message (normally the
 * startup indication, id 0x0801), read it from the queue and print its
 * header. CONTROL.NEXT_LEN is the message length in 16-bit words; the
 * read also returns the next CONTROL value in its last 2 bytes.
 */
static void xr829_read_first_message(struct sdio_func *f)
{
    uint32_t ctrl = 0;

    for (uint32_t i = 0; i < 100; ++i) {
        if (xr829_reg_read32(f, HIF_CONTROL_REG_ID, &ctrl) == 0 &&
            (ctrl & HIF_CTRL_NEXT_LEN_MASK))
            break;
        t113_mdelay(10);
    }
    uint32_t len = (ctrl & HIF_CTRL_NEXT_LEN_MASK) << 1;
    if (!len) {
        say_hex(f, "no WSM message from firmware, CONTROL ", ctrl);
        return;
    }
    uint32_t rd = len + 2u;
    rd = rd <= 512u ? (rd + 3u) & ~3u
                    : (rd + f->blksz - 1u) / f->blksz * f->blksz;
    if (rd > sizeof(xr829_dl_buf)) {
        say_hex(f, "first WSM message too long: ", len);
        return;
    }
    uint32_t buf_id = xr829_dev.buf_id_rx + 1u;
    if (sdio_memcpy_fromio(f, xr829_dl_buf,
                           HIF_ADDR(buf_id, HIF_IN_OUT_QUEUE_REG_ID), rd) < 0) {
        say(f, "reading the first WSM message failed\n");
        return;
    }
    xr829_dev.buf_id_rx = buf_id & 3u;

    const uint16_t *h = (const uint16_t *)xr829_dl_buf;
    say(f, "WSM msg id ");
    puthex16(h[1]);
    t113_uart_puts(" len ");
    putdec(h[0]);
    t113_uart_puts((h[1] & 0x0fffu) == 0x0801u ? " (startup indication)" : "");
    t113_uart_puts(" data");
    for (uint32_t k = 2; k < 10 && k * 2u < h[0]; ++k) {
        t113_uart_putc(' ');
        puthex16(h[k]);
    }
    t113_uart_putc('\n');
}

/* ------------------------------------------------------------ driver */

static int xr829_probe(struct sdio_func *func, const struct sdio_device_id *id)
{
    (void)id;
    int ret = sdio_enable_func(func);
    if (ret < 0) {
        say(func, "cannot enable SDIO function\n");
        return ret;
    }
    ret = sdio_set_block_size(func, XR829_BLOCK_SIZE);
    if (ret < 0) {
        sdio_disable_func(func);
        return ret;
    }

    uint8_t ioe = 0, ior = 0, bs_lo = 0, bs_hi = 0;
    sdio_f0_readb(func, SDIO_CCCR_IOEx, &ioe);
    sdio_f0_readb(func, SDIO_CCCR_IORx, &ior);
    sdio_f0_readb(func, SDIO_FBR_BASE(func->num) + SDIO_FBR_BLKSIZE, &bs_lo);
    sdio_f0_readb(func, SDIO_FBR_BASE(func->num) + SDIO_FBR_BLKSIZE + 1, &bs_hi);

    xr829_dev.func = func;
    xr829_dev.enabled = 1;
    sdio_set_drvdata(func, &xr829_dev);

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
    xr829_dev.cmd53_ok = xr829_cmd53_selftest(func, 1) == 0;
    if (!xr829_dev.cmd53_ok) {
        say(func, "CMD53 not working; firmware download impossible\n");
        return 0;
    }

    /* 174 KiB at 400 kHz 1-bit takes seconds: go faster if it holds up. */
    struct mmc_host *host = func->card->host;
    mmc_set_clock(host, XR829_FAST_CLOCK);
    if (xr829_cmd53_selftest(func, 0) == 0) {
        say(func, "SDIO clock ");
        putdec(XR829_FAST_CLOCK / 1000u);
        t113_uart_puts(" kHz\n");
    } else {
        say(func, "CMD53 fails at the fast clock, back to the init clock\n");
        mmc_set_clock(host, 0);
    }

    xr829_dev.fw_ok = xr829_load_firmware(func) == 0;
    if (xr829_dev.fw_ok) {
        say(func, "firmware running\n");
        if (wsm_init(func, 2000) < 0) {
            say(func, "WSM command layer init failed\n");
            xr829_read_first_message(func); /* raw transport diagnostic */
        } else {
            say(func, "WSM command layer ready\n");
            /* CONFIGURATION must be the first normal WSM command after the
             * startup indication.  The reference xradio driver consumes the
             * SDD in xradio_setup_mac() before issuing MIB queries or scan. */
            if (xradio_sta_start(xr829_dev.sdd, xr829_dev.sdd_len) < 0)
                say(func, "station scan stage failed\n");

            /* Keep the harmless diagnostic query, but only after firmware
             * configuration so it cannot perturb the startup state machine. */
            uint32_t tx_power = 0;
            uint32_t tx_power_len = sizeof(tx_power);
            int mib_ret = wsm_read_mib(WSM_MIB_DOT11_CURRENT_TX_POWER,
                                       &tx_power, &tx_power_len);
            if (!mib_ret) {
                say(func, "WSM READ_MIB current TX power OK, len ");
                putdec(tx_power_len);
                t113_uart_puts(" data ");
                t113_uart_puthex(tx_power);
                t113_uart_putc('\n');
            } else {
                say(func, "WSM READ_MIB current TX power failed ");
                t113_uart_puthex((uint32_t)mib_ret);
                t113_uart_putc('\n');
            }
        }
    } else {
        say(func, "firmware load FAILED\n");
    }
    return 0;
}

static void xr829_remove(struct sdio_func *func)
{
    sdio_disable_func(func);
    xr829_dev.func = 0;
    xr829_dev.enabled = 0;
}

static const struct sdio_device_id xr829_ids[] = {
    { SDIO_ANY_ID, 0x0a9e, 0x2282 },        /* XR829, read from 100ASK T113-Pro */
    { SDIO_ANY_ID, 0x0020, 0x2281 },        /* XR819 per open-source xradio */
    { SDIO_ANY_ID, 0x0a9e, SDIO_ANY_ID },   /* other XRadio parts: still bind */
    { SDIO_ANY_ID, 0x0020, SDIO_ANY_ID },
    { 0, 0, 0 },
};

struct sdio_driver xr829_driver = {
    .probe = xr829_probe,
    .remove = xr829_remove,
    .driver = { .name = "xradio_wlan" },
    .id_table = xr829_ids,
};
