#include "platform.h"

typedef struct {
    volatile uint32_t data;
    volatile uint32_t ier;
    volatile uint32_t fcr;
    volatile uint32_t lcr;
    volatile uint32_t mcr;
    volatile uint32_t lsr;
} early_uart_regs_t;

static early_uart_regs_t *const uart3 =
    (early_uart_regs_t *)(uintptr_t)T113_UART3_BASE;

void t113_early_uart_init(void)
{
    uint32_t gate = mmio_read32(T113_CCU_UART_BGR);
    gate &= ~((1u << 3) | (1u << 19));
    mmio_write32(T113_CCU_UART_BGR, gate);
    for (volatile unsigned int i = 0; i < 100; ++i) { }
    gate |= (1u << 3) | (1u << 19);
    mmio_write32(T113_CCU_UART_BGR, gate);

    uint32_t cfg = mmio_read32(T113_GPIO_PB_BASE + T113_GPIO_CFG0);
    cfg &= ~((0xfu << 24) | (0xfu << 28));
    cfg |= (T113_GPIO_MUX_UART3 << 24) | (T113_GPIO_MUX_UART3 << 28);
    mmio_write32(T113_GPIO_PB_BASE + T113_GPIO_CFG0, cfg);

    uart3->mcr = 3;
    uart3->lcr = 0x80;
    uart3->data = 13;
    uart3->ier = 0;
    uart3->lcr = 3;
    uart3->fcr = 7;
}

void t113_early_uart_putc(char c)
{
    if (c == '\n')
        t113_early_uart_putc('\r');
    while ((uart3->lsr & (1u << 6)) == 0) { }
    uart3->data = (uint32_t)(uint8_t)c;
}

void t113_early_uart_puts(const char *s)
{
    while (*s)
        t113_early_uart_putc(*s++);
}

void t113_early_uart_puthex(uint32_t value)
{
    static const char digits[] = "0123456789abcdef";
    t113_early_uart_puts("0x");
    for (int shift = 28; shift >= 0; shift -= 4)
        t113_early_uart_putc(digits[(value >> shift) & 0xfu]);
}
