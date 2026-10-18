#ifndef MINIOS_T113_DRAM_COMPAT_H
#define MINIOS_T113_DRAM_COMPAT_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "dram_regs.h"

#define SDRAM_BASE 0x40000000u

#define BIT(x) (1u << (x))
#define max(a, b) (((a) > (b)) ? (a) : (b))

#define CCU_BASE                 0x02001000u
#define CCU_PLL_DDR_CTRL_REG     0x010u
#define CCU_MBUS_CLK_REG         0x540u
#define CCU_DRAM_CLK_REG         0x800u
#define CCU_DRAM_BGR_REG         0x80cu

enum sunxi_dram_type {
    SUNXI_DRAM_TYPE_DDR2 = 2,
    SUNXI_DRAM_TYPE_DDR3 = 3,
    SUNXI_DRAM_TYPE_LPDDR2 = 6,
    SUNXI_DRAM_TYPE_LPDDR3 = 7,
};

typedef struct {
    uint32_t dram_clk;
    uint32_t dram_type;
    uint32_t dram_zq;
    uint32_t dram_odt_en;
    uint32_t dram_para1;
    uint32_t dram_para2;
    uint32_t dram_mr0;
    uint32_t dram_mr1;
    uint32_t dram_mr2;
    uint32_t dram_mr3;
    uint32_t dram_tpr0;
    uint32_t dram_tpr1;
    uint32_t dram_tpr2;
    uint32_t dram_tpr3;
    uint32_t dram_tpr4;
    uint32_t dram_tpr5;
    uint32_t dram_tpr6;
    uint32_t dram_tpr7;
    uint32_t dram_tpr8;
    uint32_t dram_tpr9;
    uint32_t dram_tpr10;
    uint32_t dram_tpr11;
    uint32_t dram_tpr12;
    uint32_t dram_tpr13;
} dram_para_t;

static inline uint32_t readl(uintptr_t address)
{
    return *(volatile uint32_t *)address;
}

static inline void writel(uint32_t value, uintptr_t address)
{
    *(volatile uint32_t *)address = value;
}

#define setbits_le32(addr, set) \
    writel(readl((uintptr_t)(addr)) | (uint32_t)(set), (uintptr_t)(addr))
#define clrbits_le32(addr, clear) \
    writel(readl((uintptr_t)(addr)) & ~(uint32_t)(clear), (uintptr_t)(addr))
#define clrsetbits_le32(addr, clear, set) \
    writel((readl((uintptr_t)(addr)) & ~(uint32_t)(clear)) | (uint32_t)(set), \
           (uintptr_t)(addr))

static inline uint64_t dram_arch_counter(void)
{
    uint32_t low, high;
    __asm__ volatile("mrrc p15, 0, %0, %1, c14"
                     : "=r"(low), "=r"(high));
    return ((uint64_t)high << 32) | low;
}

static inline void udelay(uint32_t us)
{
    uint64_t start = dram_arch_counter();
    uint64_t ticks = (uint64_t)us * 24u;
    while (dram_arch_counter() - start < ticks) { }
}

/* Keep the imported training algorithm small.  miniOS prints stage-level
 * status in dram.c; verbose SyterKit printf logging is compiled out. */
#define printk_debug(...) ((void)0)
#define printk_trace(...) ((void)0)
#define printk_info(...) ((void)0)
#define printk_warning(...) ((void)0)
#define printk_error(...) ((void)0)

uint64_t sunxi_dram_init(void *para);

#endif
