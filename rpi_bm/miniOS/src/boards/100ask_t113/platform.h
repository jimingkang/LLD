#ifndef MINIOS_100ASK_T113_PLATFORM_H
#define MINIOS_100ASK_T113_PLATFORM_H

#include <stdint.h>

/* Allwinner T113-S3 / sun8iw20 addresses used by SyterKit v0.3.0.0. */
#define T113_CCU_BASE           0x02001000u
#define T113_PIO_BASE           0x02000000u
#define T113_UART3_BASE         0x02500c00u
#define T113_TIMER_BASE         0x02050000u
#define T113_GIC_BASE           0x03020000u
#define T113_GIC_DIST_BASE      (T113_GIC_BASE + 0x1000u)
#define T113_GIC_CPU_BASE       (T113_GIC_BASE + 0x2000u)

#define T113_IRQ_TIMER0         91u

#define T113_CCU_UART_BGR       (T113_CCU_BASE + 0x090cu)

#define T113_GPIO_BANK_STRIDE   0x30u
#define T113_GPIO_PB_BASE       (T113_PIO_BASE + T113_GPIO_BANK_STRIDE)
#define T113_GPIO_CFG0          0x00u
#define T113_GPIO_MUX_UART3     7u

static inline uint32_t mmio_read32(uint32_t addr)
{
    return *(volatile uint32_t *)(uintptr_t)addr;
}

static inline void mmio_write32(uint32_t addr, uint32_t value)
{
    *(volatile uint32_t *)(uintptr_t)addr = value;
}

void t113_uart_init(void);
void t113_uart_putc(char c);
void t113_uart_puts(const char *s);
void t113_uart_puthex(uint32_t value);

void t113_gic_init(void);
void t113_gic_enable_irq(uint32_t irq);
uint32_t t113_gic_acknowledge(void);
void t113_gic_end_irq(uint32_t irq_ack);

void t113_timer0_init(void);
void t113_timer0_acknowledge(void);
uint32_t t113_timer_ticks(void);
void t113_irq_handler(void);

void t113_mmu_init(void);
uint32_t t113_mmu_is_enabled(void);
uint32_t t113_mmu_ttbr0(void);
uint32_t t113_mmu_l1_entry(uint32_t va);

void t113_page_alloc_init(uint32_t base, uint32_t size);
void *t113_alloc_page(void);
void *t113_alloc_pages(uint32_t count, uint32_t align_pages);
void t113_free_pages(void *address, uint32_t count);
uint32_t t113_page_free_count(void);

void t113_user_vm_demo_init(void);

void t113_sched_init(void);
void t113_sched_tick(void);

#endif
