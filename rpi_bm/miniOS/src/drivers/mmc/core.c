#include "platform.h"
#include "mmc.h"

#define SD_IO_SEND_OP_COND      5
#define SD_SEND_RELATIVE_ADDR   3
#define MMC_SELECT_CARD         7
#define MMC_GO_IDLE_STATE       0
#define SD_IO_RW_DIRECT         52
#define SD_IO_RW_EXTENDED       53

#define R4_READY                (1u << 31)
#define R4_NUM_FUNCS(r)         (((r) >> 28) & 7u)
#define R4_MEM_PRESENT          (1u << 27)
#define OCR_VDD_MASK            0x00ff8000u     /* 2.7..3.6 V */

#define R5_ERROR_MASK           0xcb00u         /* COM_CRC|ILLEGAL|ERROR|FUNC|OOR */

#define CISTPL_NULL             0x00
#define CISTPL_MANFID           0x20
#define CISTPL_END              0xff

/* Static pools: no allocator needed for a handful of cards/functions. */
static struct mmc_host *hosts[MMC_MAX_HOSTS];
static struct sdio_card card_pool[MMC_MAX_HOSTS];
static struct sdio_func func_pool[MMC_MAX_HOSTS * SDIO_MAX_FUNCS];
static uint32_t func_used;

static void puthex16(uint32_t v)
{
    static const char hex[] = "0123456789abcdef";
    t113_uart_puts("0x");
    for (int s = 12; s >= 0; s -= 4)
        t113_uart_putc(hex[(v >> s) & 15u]);
}

/* ------------------------------------------------------------- hosts */

int mmc_add_host(struct mmc_host *host)
{
    if (!host || !host->ops || !host->ops->request ||
        host->index < 0 || host->index >= MMC_MAX_HOSTS)
        return -EINVAL;
    if (hosts[host->index])
        return -EBUSY;
    host->card = 0;
    hosts[host->index] = host;
    return 0;
}

void mmc_remove_host(struct mmc_host *host)
{
    if (host && host->index >= 0 && host->index < MMC_MAX_HOSTS &&
        hosts[host->index] == host)
        hosts[host->index] = 0;
}

/* ------------------------------------------------------------- CMD52 */

int sdio_io_rw_direct(struct sdio_card *card, int write, uint8_t fn,
                      uint32_t addr, uint8_t in, uint8_t *out)
{
    /* (assigned field by field: a struct initializer would emit memset) */
    struct mmc_command cmd;
    cmd.opcode = SD_IO_RW_DIRECT;
    cmd.arg = (write ? 0x80000000u : 0u) | ((uint32_t)fn << 28) |
              ((write && out) ? 0x08000000u : 0u) |    /* RAW */
              ((addr & 0x1ffffu) << 9) | in;
    cmd.flags = MMC_RSP_R5;
    cmd.resp[0] = 0;
    cmd.data = 0;
    if (!card || fn > 7)
        return -EINVAL;
    int ret = card->host->ops->request(card->host, &cmd);
    if (ret < 0)
        return ret;
    if (cmd.resp[0] & R5_ERROR_MASK)
        return -EIO;
    if (out)
        *out = (uint8_t)cmd.resp[0];
    return 0;
}

int sdio_readb(struct sdio_func *f, uint32_t addr, uint8_t *val)
{
    return sdio_io_rw_direct(f->card, 0, f->num, addr, 0, val);
}

int sdio_writeb(struct sdio_func *f, uint32_t addr, uint8_t val)
{
    return sdio_io_rw_direct(f->card, 1, f->num, addr, val, 0);
}

int sdio_f0_readb(struct sdio_func *f, uint32_t addr, uint8_t *val)
{
    return sdio_io_rw_direct(f->card, 0, 0, addr, 0, val);
}

int sdio_f0_writeb(struct sdio_func *f, uint32_t addr, uint8_t val)
{
    return sdio_io_rw_direct(f->card, 1, 0, addr, val, 0);
}

int sdio_enable_func(struct sdio_func *f)
{
    uint8_t v;
    int ret = sdio_f0_readb(f, SDIO_CCCR_IOEx, &v);
    if (ret < 0)
        return ret;
    ret = sdio_f0_writeb(f, SDIO_CCCR_IOEx, v | (uint8_t)(1u << f->num));
    if (ret < 0)
        return ret;
    for (int ms = 0; ms < 1000; ++ms) {         /* function ready (IORx) */
        ret = sdio_f0_readb(f, SDIO_CCCR_IORx, &v);
        if (ret < 0)
            return ret;
        if (v & (1u << f->num))
            return 0;
        t113_mdelay(1);
    }
    return -ETIMEDOUT;
}

int sdio_disable_func(struct sdio_func *f)
{
    uint8_t v;
    int ret = sdio_f0_readb(f, SDIO_CCCR_IOEx, &v);
    if (ret < 0)
        return ret;
    return sdio_f0_writeb(f, SDIO_CCCR_IOEx, v & (uint8_t)~(1u << f->num));
}

int sdio_set_block_size(struct sdio_func *f, uint32_t blksz)
{
    uint32_t reg = SDIO_FBR_BASE(f->num) + SDIO_FBR_BLKSIZE;
    int ret = sdio_f0_writeb(f, reg, (uint8_t)blksz);
    if (!ret)
        ret = sdio_f0_writeb(f, reg + 1, (uint8_t)(blksz >> 8));
    if (!ret)
        f->blksz = blksz;
    return ret;
}

int sdio_io_rw_extended(struct sdio_func *f, int write, uint32_t addr,
                        int incr, void *buf, uint32_t len)
{
    struct mmc_data data;
    struct mmc_command cmd;
    uint32_t count;
    int block;

    if (!f || !buf || !len || (len & 3u) || ((uintptr_t)buf & 3u) ||
        addr > 0x1ffffu)
        return -EINVAL;
    block = len > 512u;
    if (block) {
        if (!f->blksz || len % f->blksz || len / f->blksz > 511u)
            return -EINVAL;
        data.blksz = f->blksz;
        data.blocks = len / f->blksz;
        count = data.blocks;
    } else {
        data.blksz = len;
        data.blocks = 1;
        count = len & 0x1ffu;           /* 512 encodes as 0 */
    }
    data.buf = buf;
    data.write = write;

    cmd.opcode = SD_IO_RW_EXTENDED;
    cmd.arg = (write ? 0x80000000u : 0u) | ((uint32_t)f->num << 28) |
              (block ? 0x08000000u : 0u) | (incr ? 0x04000000u : 0u) |
              (addr << 9) | count;
    cmd.flags = MMC_RSP_R5;
    cmd.resp[0] = 0;
    cmd.data = &data;

    int ret = f->card->host->ops->request(f->card->host, &cmd);
    if (ret < 0)
        return ret;
    return (cmd.resp[0] & R5_ERROR_MASK) ? -EIO : 0;
}

void mmc_set_clock(struct mmc_host *host, uint32_t hz)
{
    if (!hz)
        hz = host->f_init ? host->f_init : 400000u;
    if (host->ops->set_ios)
        host->ops->set_ios(host, hz, 1);
}

int sdio_memcpy_fromio(struct sdio_func *f, void *dst, uint32_t addr,
                       uint32_t len)
{
    return sdio_io_rw_extended(f, 0, addr, 1, dst, len);
}

int sdio_memcpy_toio(struct sdio_func *f, uint32_t addr, const void *src,
                     uint32_t len)
{
    return sdio_io_rw_extended(f, 1, addr, 1, (void *)(uintptr_t)src, len);
}

/* ------------------------------------------------------------- CIS */

static int read_cis_ptr(struct sdio_card *card, uint32_t reg, uint32_t *ptr)
{
    uint32_t p = 0;
    for (int i = 0; i < 3; ++i) {
        uint8_t b;
        int ret = sdio_io_rw_direct(card, 0, 0, reg + (uint32_t)i, 0, &b);
        if (ret < 0)
            return ret;
        p |= (uint32_t)b << (8 * i);
    }
    *ptr = p;
    return 0;
}

/* Walk a CIS tuple chain looking for MANFID. 0 if found. */
static int parse_cis_manfid(struct sdio_card *card, uint32_t ptr,
                            uint16_t *vendor, uint16_t *device)
{
    if (ptr < 0x1000u || ptr > 0x17fffu)
        return -EINVAL;
    for (int tuples = 0; tuples < 64; ++tuples) {
        uint8_t code, link;
        if (sdio_io_rw_direct(card, 0, 0, ptr, 0, &code) < 0)
            return -EIO;
        if (code == CISTPL_END)
            return -ENODEV;
        if (code == CISTPL_NULL) {
            ++ptr;
            continue;
        }
        if (sdio_io_rw_direct(card, 0, 0, ptr + 1, 0, &link) < 0)
            return -EIO;
        if (link == 0xff)
            return -ENODEV;
        if (code == CISTPL_MANFID && link >= 4) {
            uint8_t b[4];
            for (uint32_t i = 0; i < 4; ++i)
                if (sdio_io_rw_direct(card, 0, 0, ptr + 2 + i, 0, &b[i]) < 0)
                    return -EIO;
            *vendor = (uint16_t)(b[0] | (b[1] << 8));
            *device = (uint16_t)(b[2] | (b[3] << 8));
            return 0;
        }
        ptr += 2u + link;
    }
    return -ENODEV;
}

/* ------------------------------------------------------------- bus */

static const struct sdio_device_id *
sdio_match_one(const struct sdio_device_id *id, const struct sdio_func *f)
{
    for (; id && (id->vendor || id->device || id->class); ++id) {
        if (id->class != SDIO_ANY_ID && id->class != f->class)
            continue;
        if (id->vendor != SDIO_ANY_ID && id->vendor != f->vendor)
            continue;
        if (id->device != SDIO_ANY_ID && id->device != f->device)
            continue;
        return id;
    }
    return 0;
}

static int sdio_bus_match(struct device *dev, struct device_driver *drv)
{
    return sdio_match_one(to_sdio_driver(drv)->id_table,
                          to_sdio_func(dev)) != 0;
}

static int sdio_bus_probe(struct device *dev)
{
    struct sdio_func *f = to_sdio_func(dev);
    struct sdio_driver *sdrv = to_sdio_driver(dev->driver);

    f->id = sdio_match_one(sdrv->id_table, f);
    int ret = sdrv->probe ? sdrv->probe(f, f->id) : 0;
    if (ret < 0)
        f->id = 0;
    return ret;
}

static void sdio_bus_remove(struct device *dev)
{
    struct sdio_func *f = to_sdio_func(dev);
    struct sdio_driver *sdrv = to_sdio_driver(dev->driver);

    if (sdrv->remove)
        sdrv->remove(f);
    f->id = 0;
}

struct bus_type sdio_bus_type = {
    .name = "sdio",
    .match = sdio_bus_match,
    .probe = sdio_bus_probe,
    .remove = sdio_bus_remove,
};

int sdio_bus_init(void)
{
    return bus_register(&sdio_bus_type);
}

int sdio_driver_register(struct sdio_driver *drv)
{
    if (!drv || !drv->driver.name)
        return -EINVAL;
    drv->driver.bus = &sdio_bus_type;
    return driver_register(&drv->driver);
}

void sdio_driver_unregister(struct sdio_driver *drv)
{
    if (drv)
        driver_unregister(&drv->driver);
}

/* ------------------------------------------------------------- enumeration */

static void host_msg(struct mmc_host *host, const char *msg)
{
    t113_uart_puts(host->name);
    t113_uart_puts(": ");
    t113_uart_puts(msg);
}

static int mmc_cmd(struct mmc_host *host, uint32_t op, uint32_t arg,
                   uint32_t flags, uint32_t *resp0)
{
    struct mmc_command cmd;
    cmd.opcode = op;
    cmd.arg = arg;
    cmd.flags = flags;
    cmd.resp[0] = 0;
    cmd.data = 0;
    int ret = host->ops->request(host, &cmd);
    if (!ret && resp0)
        *resp0 = cmd.resp[0];
    return ret;
}

static void format_func_name(struct sdio_func *f)
{
    static const char hex[] = "0123456789abcdef";
    char *p = f->dev_name;
    const char *h = f->card->host->name;
    while (*h && p < f->dev_name + 8)
        *p++ = *h++;
    *p++ = ':';
    for (int s = 12; s >= 0; s -= 4)
        *p++ = hex[(f->card->rca >> s) & 15u];
    *p++ = ':';
    *p++ = (char)('0' + f->num);
    *p = '\0';
}

static int sdio_attach_card(struct mmc_host *host)
{
    uint32_t r4 = 0, ocr, r6;
    int ret;

    if (host->ops->power)
        host->ops->power(host, 1);
    if (host->ops->set_ios)
        host->ops->set_ios(host, host->f_init ? host->f_init : 400000u, 1);

    mmc_cmd(host, MMC_GO_IDLE_STATE, 0, MMC_RSP_NONE, 0);

    ret = mmc_cmd(host, SD_IO_SEND_OP_COND, 0, MMC_RSP_R4, &r4);
    if (ret < 0) {
        host_msg(host, ret == -ETIMEDOUT ? "no SDIO card (CMD5 timeout)\n"
                                         : "CMD5 failed\n");
        return ret;
    }
    ocr = r4 & OCR_VDD_MASK;
    if (!ocr) {
        host_msg(host, "card OCR has no 2.7-3.6V window: ");
        t113_uart_puthex(r4);
        t113_uart_putc('\n');
        return -ENODEV;
    }
    for (int i = 0; ; ++i) {
        ret = mmc_cmd(host, SD_IO_SEND_OP_COND, ocr, MMC_RSP_R4, &r4);
        if (!ret && (r4 & R4_READY))
            break;
        if (i >= 100) {
            host_msg(host, "card never became ready (CMD5)\n");
            return -ETIMEDOUT;
        }
        t113_mdelay(10);
    }

    struct sdio_card *card = &card_pool[host->index];
    card->host = host;
    card->ocr = r4;
    card->num_funcs = (uint8_t)R4_NUM_FUNCS(r4);
    card->vendor = card->device = 0;

    ret = mmc_cmd(host, SD_SEND_RELATIVE_ADDR, 0, MMC_RSP_R6, &r6);
    if (ret < 0) {
        host_msg(host, "CMD3 failed\n");
        return ret;
    }
    card->rca = (uint16_t)(r6 >> 16);
    ret = mmc_cmd(host, MMC_SELECT_CARD, (uint32_t)card->rca << 16,
                  MMC_RSP_R1B, 0);
    if (ret < 0) {
        host_msg(host, "CMD7 failed\n");
        return ret;
    }

    uint8_t v;
    if (sdio_io_rw_direct(card, 0, 0, SDIO_CCCR_CCCR, 0, &v) == 0) {
        card->cccr_rev = v & 0x0f;
        card->sdio_rev = v >> 4;
    }
    sdio_io_rw_direct(card, 0, 0, SDIO_CCCR_CAPS, 0, &card->caps);

    uint32_t cis;
    if (read_cis_ptr(card, SDIO_CCCR_CIS, &cis) == 0)
        parse_cis_manfid(card, cis, &card->vendor, &card->device);

    host->card = card;
    host_msg(host, "SDIO card rca ");
    puthex16(card->rca);
    t113_uart_puts(" OCR ");
    t113_uart_puthex(card->ocr);
    t113_uart_puts(" funcs ");
    t113_uart_putc((char)('0' + card->num_funcs));
    t113_uart_puts(" vendor ");
    puthex16(card->vendor);
    t113_uart_puts(" device ");
    puthex16(card->device);
    t113_uart_putc('\n');
    return 0;
}

static void sdio_add_funcs(struct mmc_host *host)
{
    struct sdio_card *card = host->card;

    for (uint8_t n = 1; n <= card->num_funcs && n <= SDIO_MAX_FUNCS; ++n) {
        if (func_used >= sizeof(func_pool) / sizeof(func_pool[0]))
            return;
        struct sdio_func *f = &func_pool[func_used++];
        uint8_t std_if = 0;
        uint32_t cis;

        f->card = card;
        f->num = n;
        sdio_io_rw_direct(card, 0, 0, SDIO_FBR_BASE(n) + SDIO_FBR_STD_IF,
                          0, &std_if);
        f->class = std_if & 0x0f;
        f->vendor = card->vendor;
        f->device = card->device;
        if (read_cis_ptr(card, SDIO_FBR_BASE(n) + SDIO_FBR_CIS, &cis) == 0)
            parse_cis_manfid(card, cis, &f->vendor, &f->device);

        format_func_name(f);
        f->dev.name = f->dev_name;
        f->dev.parent = host->dev;
        f->dev.bus = &sdio_bus_type;
        card->funcs[n - 1] = f;

        host_msg(host, "func ");
        t113_uart_putc((char)('0' + n));
        t113_uart_puts(" class ");
        puthex16(f->class);
        t113_uart_puts(" vendor ");
        puthex16(f->vendor);
        t113_uart_puts(" device ");
        puthex16(f->device);
        t113_uart_putc('\n');

        if (device_register(&f->dev) < 0) {
            host_msg(host, "cannot register sdio function\n");
        } else if (!f->dev.driver) {
            int ndrv = 0;
            struct list_head *node;
            list_for_each(node, &sdio_bus_type.drivers)
                ++ndrv;
            host_msg(host, "no sdio driver matched (");
            t113_uart_putc((char)('0' + (ndrv > 9 ? 9 : ndrv)));
            t113_uart_puts(" registered)\n");
        }
    }
}

void mmc_rescan_all(void)
{
    for (int i = 0; i < MMC_MAX_HOSTS; ++i) {
        struct mmc_host *host = hosts[i];
        if (!host || host->card)
            continue;
        if (sdio_attach_card(host) == 0) {
            sdio_add_funcs(host);
        } else {
            if (host->ops->dump)
                host->ops->dump(host);
            if (host->ops->power)
                host->ops->power(host, 0);
        }
    }
}
