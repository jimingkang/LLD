#include "platform.h"
#include "dram_compat.h"

/* Exact 100ASK T113-S3 DDR3 parameters from SyterKit v0.3.0.0 board.c. */
static dram_para_t dram_para = {
    .dram_clk = 792,
    .dram_type = SUNXI_DRAM_TYPE_DDR3,
    .dram_zq = 0x7b7bfb,
    .dram_odt_en = 0x00,
    .dram_para1 = 0x000010d2,
    .dram_para2 = 0,
    .dram_mr0 = 0x1c70,
    .dram_mr1 = 0x42,
    .dram_mr2 = 0x18,
    .dram_mr3 = 0,
    .dram_tpr0 = 0x004a2195,
    .dram_tpr1 = 0x02423190,
    .dram_tpr2 = 0x0008b061,
    .dram_tpr3 = 0xb4787896,
    .dram_tpr4 = 0,
    .dram_tpr5 = 0x48484848,
    .dram_tpr6 = 0x00000048,
    .dram_tpr7 = 0x1620121e,
    .dram_tpr8 = 0,
    .dram_tpr9 = 0,
    .dram_tpr10 = 0,
    .dram_tpr11 = 0x00340000,
    .dram_tpr12 = 0x00000046,
    .dram_tpr13 = 0x34000100,
};

static int dram_test_word(volatile uint32_t *address, uint32_t pattern)
{
    uint32_t saved = *address;
    *address = pattern;
    __asm__ volatile("dsb sy" ::: "memory");
    uint32_t value = *address;
    *address = saved;
    return value == pattern;
}

uint32_t t113_dram_init(void)
{
    t113_early_uart_puts("DRAM: SyterKit DDR3 training at 792 MHz...\n");
    uint32_t size_mb = (uint32_t)sunxi_dram_init(&dram_para);
    if (!size_mb || size_mb > 2048u) {
        t113_early_uart_puts("DRAM: initialization failed\n");
        return 0;
    }

    uint32_t size_bytes = size_mb << 20;
    volatile uint32_t *first = (volatile uint32_t *)(uintptr_t)SDRAM_BASE;
    volatile uint32_t *last =
        (volatile uint32_t *)(uintptr_t)(SDRAM_BASE + size_bytes - 4u);
    if (!dram_test_word(first, 0x55aa33ccu) ||
        !dram_test_word(last, 0xaa55cc33u)) {
        t113_early_uart_puts("DRAM: boundary read/write test failed\n");
        return 0;
    }

    t113_early_uart_puts("DRAM: size-MB=");
    t113_early_uart_puthex(size_mb);
    t113_early_uart_puts(" range=[0x40000000, ");
    t113_early_uart_puthex(SDRAM_BASE + size_bytes);
    t113_early_uart_puts(") boundary test OK\n");
    return size_bytes;
}
