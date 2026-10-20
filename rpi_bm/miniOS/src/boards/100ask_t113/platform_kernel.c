#include "platform.h"
#include "kernel/boot.h"

extern uint8_t __kernel_reserved_end[];

void kernel_platform_panic(const char *message)
{
    t113_uart_puts("PANIC: ");
    t113_uart_puts(message);
    t113_uart_putc('\n');
    for (;;)
        __asm__ volatile("wfi");
}

void kernel_platform_interrupt_init(void) { t113_gic_init(); }
void kernel_platform_console_irq_init(void) { t113_uart_irq_init(); }

void kernel_platform_timer_init(void)
{
    t113_timer0_init();
    t113_uart_puts("GIC + Timer0 IRQ ready: expect one tick per second\n");
}

void kernel_platform_enable_interrupts(void)
{
    __asm__ volatile("cpsie i" ::: "memory");
}

void kernel_platform_idle(void) { __asm__ volatile("wfi"); }

/* Architecture entry called from kernel_entry.S after SPL enters DDR. */
void kernel_main(uint32_t dram_size)
{
    t113_uart_init();
    t113_uart_puts("\nminiOS kernel: executing from DDR (built "
                   __DATE__ " " __TIME__ ")\n");
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
    if (pool_base >= dram_end)
        kernel_platform_panic("kernel consumes all DDR");

    t113_bootpack_dump();
    kernel_boot(pool_base, dram_end);
}
