/*
 * XRadio HIF register and device memory access over SDIO CMD53, after
 * the xradio driver's hwio.c.  See hwio.h.
 */
#include "platform.h"
#include "device.h"
#include "mmc.h"
#include "hwio.h"

int xradio_reg_read_32(struct sdio_func *func, uint32_t reg_id, uint32_t *val)
{
    uint32_t buf[1] = { 0 };
    int ret = sdio_memcpy_fromio(func, buf, HIF_ADDR(0, reg_id), 4);
    if (!ret)
        *val = buf[0];                  /* little endian on both sides */
    return ret;
}

int xradio_reg_write_32(struct sdio_func *func, uint32_t reg_id, uint32_t val)
{
    uint32_t buf[1] = { val };
    return sdio_memcpy_toio(func, HIF_ADDR(0, reg_id), buf, 4);
}

int xradio_reg_bit_op(struct sdio_func *f, uint32_t reg_id, uint32_t set,
                      uint32_t clr)
{
    uint32_t v;
    int ret = xradio_reg_read_32(f, reg_id, &v);
    if (ret < 0 && reg_id == HIF_CONTROL_REG_ID)
        ret = xradio_reg_read_32(f, reg_id, &v);    /* hwio.c retries once */
    if (ret < 0)
        return ret;
    return xradio_reg_write_32(f, reg_id, (v & ~clr) | set);
}

/* addr -> SRAM_BASE_ADDR, then len bytes through port_id. */
static int indirect_write(struct sdio_func *f, uint32_t addr, uint32_t port_id,
                          const void *buf, uint32_t len)
{
    int ret = xradio_reg_write_32(f, HIF_SRAM_BASE_ADDR_REG_ID, addr);
    if (ret < 0)
        return ret;
    return sdio_memcpy_toio(f, HIF_ADDR(0, port_id), buf, len);
}

static int indirect_read(struct sdio_func *f, uint32_t addr, uint32_t port_id,
                         uint32_t prefetch, void *buf, uint32_t len)
{
    uint32_t cfg;
    int ret;

    if ((ret = xradio_reg_write_32(f, HIF_SRAM_BASE_ADDR_REG_ID, addr)) < 0 ||
        (ret = xradio_reg_read_32(f, HIF_CONFIG_REG_ID, &cfg)) < 0 ||
        (ret = xradio_reg_write_32(f, HIF_CONFIG_REG_ID, cfg | prefetch)) < 0)
        return ret;
    for (uint32_t i = 0; i < 20; ++i) {
        if ((ret = xradio_reg_read_32(f, HIF_CONFIG_REG_ID, &cfg)) < 0)
            return ret;
        if (!(cfg & prefetch))
            break;
        t113_mdelay(i);
    }
    if (cfg & prefetch)
        return -ETIMEDOUT;
    return sdio_memcpy_fromio(f, buf, HIF_ADDR(0, port_id), len);
}

int xradio_apb_write(struct sdio_func *f, uint32_t addr, const void *buf,
                     uint32_t len)
{
    return indirect_write(f, addr, HIF_SRAM_DPORT_REG_ID, buf, len);
}

int xradio_apb_write_32(struct sdio_func *f, uint32_t addr, uint32_t val)
{
    uint32_t b[1] = { val };
    return xradio_apb_write(f, addr, b, 4);
}

int xradio_apb_read_32(struct sdio_func *f, uint32_t addr, uint32_t *val)
{
    uint32_t b[1] = { 0 };
    int ret = indirect_read(f, addr, HIF_SRAM_DPORT_REG_ID,
                            HIF_CONFIG_PFETCH_BIT, b, 4);
    *val = b[0];
    return ret;
}

int xradio_ahb_write_32(struct sdio_func *f, uint32_t addr, uint32_t val)
{
    uint32_t b[1] = { val };
    return indirect_write(f, addr, HIF_AHB_DPORT_REG_ID, b, 4);
}

int xradio_ahb_read_32(struct sdio_func *f, uint32_t addr, uint32_t *val)
{
    uint32_t b[1] = { 0 };
    int ret = indirect_read(f, addr, HIF_AHB_DPORT_REG_ID,
                            HIF_CONFIG_AHB_PFETCH_BIT, b, 4);
    *val = b[0];
    return ret;
}
