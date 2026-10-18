#include "platform.h"
#include "sched.h"

extern uint8_t __kernel_reserved_end[];

/* Minimal ARM user image: an intentional busy loop. Timer IRQs must still
 * preempt it, proving User mode, its page table and the kernel return path. */
static const uint32_t init_user_image[] = {
    0xeafffffeu, /* b . */
};

void kernel_main(uint32_t dram_size)
{
    t113_uart_init();
    t113_uart_puts("\nminiOS kernel: executing from DDR\n");
    t113_uart_puts("kernel entry=0x40200000 current-PC=");
    uint32_t pc;
    __asm__ volatile("mov %0, pc" : "=r"(pc));
    t113_uart_puthex(pc);
    t113_uart_putc('\n');

    t113_mmu_init();
    t113_uart_puts("MMU: SCTLR=");
    t113_uart_puthex(t113_mmu_is_enabled());
    t113_uart_puts(" TTBR0=");
    t113_uart_puthex(t113_mmu_ttbr0());
    t113_uart_putc('\n');

    uint32_t pool_base = ((uint32_t)(uintptr_t)__kernel_reserved_end + 0xfffu) & ~0xfffu;
    uint32_t dram_end = 0x40000000u + dram_size;
    if (pool_base >= dram_end) {
        t113_uart_puts("PANIC: kernel consumes all DDR\n");
        for (;;)
            __asm__ volatile("wfi");
    }
    t113_page_alloc_init(pool_base, dram_end - pool_base);

    t113_gic_init();
    t113_sched_init();
    if (t113_create_init_user_process(init_user_image,
                                      sizeof(init_user_image),
                                      0x00100000u) < 0) {
        t113_uart_puts("PANIC: cannot create init user process\n");
        for (;;)
            __asm__ volatile("wfi");
    }
    t113_timer0_init();
    t113_uart_puts("GIC + Timer0 IRQ ready: expect one tick per second\n");
    __asm__ volatile("cpsie i" ::: "memory");
    for (;;)
        __asm__ volatile("wfi");
}
