/* UART3 PB6/PB7 setup follows SyterKit v0.3.0.0 100ask-t113s3 board.c. */
#include "platform.h"

typedef struct {
    volatile uint32_t rbr_thr_dll;
    volatile uint32_t ier_dlh;
    volatile uint32_t iir_fcr;
    volatile uint32_t lcr;
    volatile uint32_t mcr;
    volatile uint32_t lsr;
    volatile uint32_t msr;
    volatile uint32_t sch;
} uart_regs_t;

static uart_regs_t *const uart3 = (uart_regs_t *)(uintptr_t)T113_UART3_BASE;

static void gpio_set_uart3(void)
{
    uint32_t cfg = mmio_read32(T113_GPIO_PB_BASE + T113_GPIO_CFG0);
    cfg &= ~((0xfu << 24) | (0xfu << 28)); /* PB6, PB7 */
    cfg |= (T113_GPIO_MUX_UART3 << 24) | (T113_GPIO_MUX_UART3 << 28);
    mmio_write32(T113_GPIO_PB_BASE + T113_GPIO_CFG0, cfg);
}

void t113_uart_init(void)
{
    uint32_t gate = mmio_read32(T113_CCU_UART_BGR);
    gate &= ~((1u << 3) | (1u << 19));
    mmio_write32(T113_CCU_UART_BGR, gate);
    for (volatile unsigned int i = 0; i < 100; ++i) { }
    gate |= (1u << 3) | (1u << 19); /* UART3 gate + reset deassert */
    mmio_write32(T113_CCU_UART_BGR, gate);

    gpio_set_uart3();

    uart3->mcr = 0x3;
    uart3->lcr = 0x80;              /* divisor latch access */
    uart3->rbr_thr_dll = 13;        /* 24 MHz / (16 * 115200) */
    uart3->ier_dlh = 0;
    uart3->lcr = 0x03;              /* 8 data bits, 1 stop, no parity */
    uart3->iir_fcr = 0x07;          /* enable and reset FIFOs */
}

void t113_uart_putc(char c)
{
    if (c == '\n')
        t113_uart_putc('\r');
    while ((uart3->lsr & (1u << 6)) == 0) { }
    uart3->rbr_thr_dll = (uint32_t)(uint8_t)c;
}

void t113_uart_puts(const char *s)
{
    while (*s)
        t113_uart_putc(*s++);
}

void t113_uart_puthex(uint32_t value)
{
    static const char digits[] = "0123456789abcdef";

    t113_uart_puts("0x");
    for (int shift = 28; shift >= 0; shift -= 4)
        t113_uart_putc(digits[(value >> shift) & 0xfu]);
}
