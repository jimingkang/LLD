#ifndef MINIBOOT_100ASK_T113_PLATFORM_H
#define MINIBOOT_100ASK_T113_PLATFORM_H

#include <stdint.h>

#define T113_CCU_BASE           0x02001000u
#define T113_PIO_BASE           0x02000000u
#define T113_UART3_BASE         0x02500c00u
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

void t113_early_uart_init(void);
void t113_early_uart_putc(char c);
void t113_early_uart_try_putc(char c);
void t113_early_uart_puts(const char *s);
void t113_early_uart_puthex(uint32_t value);
int t113_early_uart_getc_nonblock(void);
char t113_early_uart_getc(void);
void t113_early_uart_drain_rx(void);
uint64_t t113_counter_ticks(void); /* architectural counter, 24 MHz */
uint32_t t113_dram_init(void);

#endif
