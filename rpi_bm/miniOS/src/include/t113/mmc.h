#ifndef MINIOS_T113_MMC_H
#define MINIOS_T113_MMC_H

#include "device.h"

/*
 * Lightweight MMC/SDIO core, Linux-shaped:
 *   mmc_host    : an SD/MMC controller (registered by its platform driver's
 *                 probe into a small table, like i2c adapters)
 *   sdio_card   : the card found on a host by mmc_rescan_all()
 *   sdio_func   : one SDIO function (1..7) = a struct device on bus "sdio"
 *   sdio_driver : function driver, matched by vendor/device/class
 *
 * Card enumeration registers devices, so it cannot run inside a probe
 * (driver-core lock). mmc_rescan_all() is called once after all drivers
 * are registered, the way Linux defers mmc_rescan to a workqueue.
 * CMD52 (byte I/O) and CMD53 (byte/block I/O, CPU FIFO access) are
 * implemented; no DMA, no interrupts.
 */

#define MMC_RSP_PRESENT (1u << 0)
#define MMC_RSP_136     (1u << 1)
#define MMC_RSP_CRC     (1u << 2)
#define MMC_RSP_BUSY    (1u << 3)

#define MMC_RSP_NONE    0u
#define MMC_RSP_R1      (MMC_RSP_PRESENT | MMC_RSP_CRC)
#define MMC_RSP_R1B     (MMC_RSP_R1 | MMC_RSP_BUSY)
#define MMC_RSP_R4      (MMC_RSP_PRESENT)              /* no CRC */
#define MMC_RSP_R5      (MMC_RSP_PRESENT | MMC_RSP_CRC)
#define MMC_RSP_R6      (MMC_RSP_PRESENT | MMC_RSP_CRC)

struct mmc_data {
    void *buf;                  /* 4-byte aligned */
    uint32_t blksz;             /* bytes per block */
    uint32_t blocks;
    int write;
};

struct mmc_command {
    uint32_t opcode;
    uint32_t arg;
    uint32_t flags;             /* MMC_RSP_* */
    uint32_t resp[4];
    struct mmc_data *data;      /* 0 = no data phase */
};

struct mmc_host;

struct mmc_host_ops {
    /* Send one command (+ optional data). 0 or -ETIMEDOUT / -EIO. */
    int (*request)(struct mmc_host *host, struct mmc_command *cmd);
    void (*set_ios)(struct mmc_host *host, uint32_t clock_hz,
                    uint32_t bus_width);
    /* Card power sequence (regulators, enable GPIO, 32k clock...). */
    void (*power)(struct mmc_host *host, int on);
    void (*dump)(struct mmc_host *host);        /* optional diagnostics */
};

#define MMC_MAX_HOSTS 3

struct sdio_card;

struct mmc_host {
    int index;                  /* mmcN */
    const char *name;           /* "mmc1" */
    struct device *dev;         /* controller device (platform sdc1) */
    const struct mmc_host_ops *ops;
    void *priv;
    uint32_t f_init;            /* identification clock, Hz */
    struct sdio_card *card;
};

#define SDIO_MAX_FUNCS 7

struct sdio_func;

struct sdio_card {
    struct mmc_host *host;
    uint16_t rca;
    uint32_t ocr;
    uint8_t num_funcs;
    uint8_t cccr_rev;
    uint8_t sdio_rev;
    uint8_t caps;
    uint16_t vendor;            /* from common CIS MANFID */
    uint16_t device;
    struct sdio_func *funcs[SDIO_MAX_FUNCS];
};

#define SDIO_ANY_ID 0xffffu

struct sdio_device_id {
    uint16_t class;             /* SDIO_ANY_ID = don't care */
    uint16_t vendor;
    uint16_t device;
};

struct sdio_func {
    struct sdio_card *card;
    uint8_t num;                /* 1..7 */
    uint8_t class;
    uint16_t vendor;
    uint16_t device;
    char dev_name[20];          /* "mmc1:0001:1" */
    uint32_t blksz;             /* block size set via sdio_set_block_size */
    struct device dev;
    const struct sdio_device_id *id;    /* set while bound */
};

struct sdio_driver {
    int (*probe)(struct sdio_func *func, const struct sdio_device_id *id);
    void (*remove)(struct sdio_func *func);
    struct device_driver driver;
    const struct sdio_device_id *id_table;      /* {0} terminated */
};

#define to_sdio_func(d)   container_of(d, struct sdio_func, dev)
#define to_sdio_driver(d) container_of(d, struct sdio_driver, driver)

extern struct bus_type sdio_bus_type;

int sdio_bus_init(void);
int mmc_add_host(struct mmc_host *host);
void mmc_remove_host(struct mmc_host *host);
/* Enumerate every host without a card. Call outside any probe. */
void mmc_rescan_all(void);
/* Change the bus clock (1-bit). 0 = back to the host's f_init. */
void mmc_set_clock(struct mmc_host *host, uint32_t hz);

int sdio_driver_register(struct sdio_driver *drv);
void sdio_driver_unregister(struct sdio_driver *drv);

/* CMD52 byte access; fn 0 = CCCR/FBR space. */
int sdio_io_rw_direct(struct sdio_card *card, int write, uint8_t fn,
                      uint32_t addr, uint8_t in, uint8_t *out);
int sdio_readb(struct sdio_func *func, uint32_t addr, uint8_t *val);
int sdio_writeb(struct sdio_func *func, uint32_t addr, uint8_t val);
int sdio_f0_readb(struct sdio_func *func, uint32_t addr, uint8_t *val);
int sdio_f0_writeb(struct sdio_func *func, uint32_t addr, uint8_t val);
/*
 * CMD53. `addr` is the function register address; incr = 1 auto-increments
 * it (memory-like), 0 keeps it fixed (FIFO port). len must be a multiple
 * of 4; <= 512 uses byte mode, larger uses block mode with func->blksz.
 */
int sdio_io_rw_extended(struct sdio_func *func, int write, uint32_t addr,
                        int incr, void *buf, uint32_t len);
int sdio_memcpy_fromio(struct sdio_func *func, void *dst, uint32_t addr,
                       uint32_t len);
int sdio_memcpy_toio(struct sdio_func *func, uint32_t addr, const void *src,
                     uint32_t len);
int sdio_enable_func(struct sdio_func *func);
int sdio_disable_func(struct sdio_func *func);
int sdio_set_block_size(struct sdio_func *func, uint32_t blksz);

static inline void sdio_set_drvdata(struct sdio_func *f, void *data)
{
    dev_set_drvdata(&f->dev, data);
}

static inline void *sdio_get_drvdata(const struct sdio_func *f)
{
    return dev_get_drvdata(&f->dev);
}

/* CCCR registers (function 0). */
#define SDIO_CCCR_CCCR      0x00
#define SDIO_CCCR_SD        0x01
#define SDIO_CCCR_IOEx      0x02
#define SDIO_CCCR_IORx      0x03
#define SDIO_CCCR_IENx      0x04
#define SDIO_CCCR_ABORT     0x06
#define SDIO_CCCR_IF        0x07
#define SDIO_CCCR_CAPS      0x08
#define SDIO_CCCR_CIS       0x09        /* 3 bytes, little endian */
#define SDIO_FBR_BASE(f)    ((uint32_t)(f) * 0x100u)
#define SDIO_FBR_STD_IF     0x00
#define SDIO_FBR_CIS        0x09
#define SDIO_FBR_BLKSIZE    0x10

/* XR829 HIF register access (xr829.c). */
int xr829_reg_read32(struct sdio_func *func, uint32_t reg_id, uint32_t *val);
int xr829_reg_write32(struct sdio_func *func, uint32_t reg_id, uint32_t val);

#endif
