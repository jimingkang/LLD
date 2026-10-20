#ifndef MINIOS_KERNEL_BOOT_H
#define MINIOS_KERNEL_BOOT_H

#include <stdint.h>

void kernel_boot(uint32_t page_pool_base, uint32_t physical_memory_end)
    __attribute__((noreturn));

void kernel_platform_panic(const char *message) __attribute__((noreturn));
void kernel_platform_interrupt_init(void);
void kernel_platform_console_irq_init(void);
void kernel_platform_timer_init(void);
void kernel_platform_enable_interrupts(void);
void kernel_platform_idle(void);

#endif
