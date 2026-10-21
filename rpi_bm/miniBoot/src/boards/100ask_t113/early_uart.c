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

#define UART_USR       (*(volatile uint32_t *)(uintptr_t)(T113_UART3_BASE + 0x7cu))
#define UART_USR_TFNF  (1u << 1)
#define UART_USR_RFNE  (1u << 3)

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
    /* T113 uses a DesignWare APB UART. USR.TFNF is the authoritative FIFO
     * space indication; LSR.THRE/TEMT proved unreliable after receiving. */
    while (!(UART_USR & UART_USR_TFNF)) { }
    uart3->data = (uint32_t)(uint8_t)c;
}

void t113_early_uart_try_putc(char c)
{
    if (UART_USR & UART_USR_TFNF)
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

int t113_early_uart_getc_nonblock(void)
{
    if (!(UART_USR & UART_USR_RFNE))
        return -1;
    /* Reading RBR consumes a byte and clears receive error state associated
     * with it. Return the byte even if OE/PE/FE was latched so the shell can
     * continue rather than wedging permanently on the same FIFO entry. */
    return (int)(uart3->data & 0xffu);
}

char t113_early_uart_getc(void)
{
    int c;
    while ((c = t113_early_uart_getc_nonblock()) < 0) { }
    return (char)c;
}

void t113_early_uart_drain_rx(void)
{
    /* Consume the rest of the key sequence that interrupted autoboot. Do
     * not reprogram UART clocks/divisors while characters are being sent. */
    for (uint32_t i = 0; i < 64u && (UART_USR & UART_USR_RFNE); ++i)
        (void)uart3->data;
}

uint64_t t113_counter_ticks(void)
{
    uint32_t lo, hi, hi2;
    do {
        __asm__ volatile("mrrc p15, 0, %0, %1, c14" : "=r"(lo), "=r"(hi));
        __asm__ volatile("mrrc p15, 0, %0, %1, c14" : "=r"(lo), "=r"(hi2));
    } while (hi != hi2);
    return ((uint64_t)hi << 32) | lo;
}
