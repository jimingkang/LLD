#include "uart.h"
#include "lib.h"

void write_char(unsigned char c)
{
    while (in_word(UART0_FR) & (1 << 3)) { }
    out_word(UART0_DR, c);
}

unsigned char read_char(void)
{
    return in_word(UART0_DR);
}

void write_string(const char *string)
{
    for (int i = 0; string[i] != '\0'; i++) {
        write_char(string[i]);
    }
}

void uart_handler(void)
{
    uint32_t status = in_word(UART0_MIS);

    if (status & (1 << 4)) {
        char ch = read_char();

        if (ch == '\r') {
            write_string("\r\n");
        }
        else {
            write_char(ch);
        }
        
        out_word(UART0_ICR, (1 << 4));
    }
}


void init_uart(void)
{
    uint32_t selector;

    out_word(UART0_CR, 0);

    /* Route PL011 UART0 to GPIO14 (TX) and GPIO15 (RX), ALT0. */
    selector = in_word(GPFSEL1);
    selector &= ~((7 << 12) | (7 << 15));
    selector |= (4 << 12) | (4 << 15);
    out_word(GPFSEL1, selector);

    /* Disable pulls on GPIO14/15 (BCM2837 pull-control sequence). */
    out_word(GPPUD, 0);
    delay(150);
    out_word(GPPUDCLK0, (1 << 14) | (1 << 15));
    delay(150);
    out_word(GPPUDCLK0, 0);

    out_word(UART0_ICR, 0x7ff);
    out_word(UART0_IBRD, 26);
    out_word(UART0_FBRD, 3);
    out_word(UART0_LCRH, (1 << 5) | (1 << 6));
    out_word(UART0_IMSC, (1 << 4));
    out_word(UART0_CR, (1 << 0) | (1 << 8) | (1 << 9));
}
