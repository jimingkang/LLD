#include "platform.h"

extern uint8_t __kernel_load_start[];
extern uint8_t __kernel_load_end[];
extern uint8_t __kernel_start[];

static void copy_kernel_payload(void)
{
    uint32_t *src = (uint32_t *)(uintptr_t)__kernel_load_start;
    uint32_t *end = (uint32_t *)(uintptr_t)__kernel_load_end;
    uint32_t *dst = (uint32_t *)(uintptr_t)__kernel_start;
    while (src < end)
        *dst++ = *src++;
}

static void jump_to_kernel(uint32_t dram_size) __attribute__((noreturn));
static void jump_to_kernel(uint32_t dram_size)
{
    void (*entry)(uint32_t) = (void (*)(uint32_t))(uintptr_t)__kernel_start;
    __asm__ volatile(
        "dsb sy\n\t"
        "mov r1, #0\n\t"
        "mcr p15, 0, r1, c8, c7, 0\n\t"  /* invalidate TLB */
        "mcr p15, 0, r1, c7, c5, 0\n\t"  /* invalidate I-cache */
        "mcr p15, 0, r1, c7, c5, 6\n\t"  /* invalidate branch predictor */
        "dsb sy\n\t"
        "isb"
        : : : "r1", "memory");
    entry(dram_size);
    for (;;)
        __asm__ volatile("wfi");
}

void spl_main(void)
{
    t113_early_uart_init();
    t113_early_uart_puts("\nminiOS SPL: 100ASK T113-S3\n");
    t113_early_uart_puts("SPL: running from SRAM, DDR/MMU/cache off\n");

    uint32_t dram_size = t113_dram_init();
    if (!dram_size) {
        t113_early_uart_puts("SPL PANIC: DDR unavailable\n");
        for (;;)
            __asm__ volatile("wfi");
    }

    t113_early_uart_puts("SPL: copy kernel SRAM ");
    t113_early_uart_puthex((uint32_t)(uintptr_t)__kernel_load_start);
    t113_early_uart_puts(" -> DDR ");
    t113_early_uart_puthex((uint32_t)(uintptr_t)__kernel_start);
    t113_early_uart_puts(" bytes=");
    t113_early_uart_puthex((uint32_t)(__kernel_load_end - __kernel_load_start));
    t113_early_uart_putc('\n');
    copy_kernel_payload();
    t113_early_uart_puts("SPL: jump kernel_entry @ 0x40200000\n");
    jump_to_kernel(dram_size);
}
