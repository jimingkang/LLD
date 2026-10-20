#ifndef MINIOS_XRADIO_HWIO_H
#define MINIOS_XRADIO_HWIO_H

#include <stdint.h>

/*
 * XRadio host interface (HIF) registers, after the xradio driver's
 * hwio.h.  SDIO address = (buf_id << 7) | (reg_id << 2).  HIF registers
 * work before any firmware is loaded.  Device memory is reached
 * indirectly: write the address to SRAM_BASE_ADDR, then stream through
 * SRAM_DPORT (APB, shared RAM) or AHB_DPORT (AHB, CPU memory); reads
 * first set a PREFETCH bit in CONFIG and wait for it to clear.
 */

struct sdio_func;

#define BIT(n)                      (1u << (n))

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

int xradio_reg_read_32(struct sdio_func *func, uint32_t reg_id, uint32_t *val);
int xradio_reg_write_32(struct sdio_func *func, uint32_t reg_id, uint32_t val);
/* Read-modify-write: (reg & ~clr) | set. */
int xradio_reg_bit_op(struct sdio_func *func, uint32_t reg_id, uint32_t set,
                      uint32_t clr);
int xradio_apb_write(struct sdio_func *func, uint32_t addr, const void *buf,
                     uint32_t len);
int xradio_apb_write_32(struct sdio_func *func, uint32_t addr, uint32_t val);
int xradio_apb_read_32(struct sdio_func *func, uint32_t addr, uint32_t *val);
int xradio_ahb_write_32(struct sdio_func *func, uint32_t addr, uint32_t val);
int xradio_ahb_read_32(struct sdio_func *func, uint32_t addr, uint32_t *val);

#endif
