#include "uart.h"
#include "lib.h"

void uart_putc(unsigned char c)
{
    while (in_word(UART0_FR) & (1 << 3)) { }
    out_word(UART0_DR, c);
}

unsigned char uart_getc(void)
{
    return in_word(UART0_DR);
}

void uart_puts(const char *string)
{
    for (int i = 0; string[i] != '\0'; i++) {
        uart_putc(string[i]);
    }
}
void uart_put_number(unsigned int num) {
    char buffer[16];
    int i = 0;
    
    if (num == 0) {
        uart_putc('0');
        return;
    }
    
    // Convert number to string (reverse order)
    while (num > 0) {
        buffer[i++] = '0' + (num % 10);
        num /= 10;
    }
    
    // Print digits in correct order
    while (i > 0) {
        uart_putc(buffer[--i]);
    }
}

void uart_handler(void)
{
    uint32_t status = in_word(UART0_MIS);

    if (status & (1 << 4)) {
        char ch = uart_getc();

        if (ch == '\r') {
            uart_puts("\r\n");
        }
        else {
            uart_putc(ch);
        }
        
        out_word(UART0_ICR, (1 << 4));
    }
}


void init_uart(void)
{
    out_word(UART0_CR, 0);
    out_word(UART0_IBRD, 26);
    out_word(UART0_FBRD, 0);
    out_word(UART0_LCRH, (1 << 5) | (1 << 6));
    out_word(UART0_IMSC, (1 << 4));
    out_word(UART0_CR, (1 << 0) | (1 << 8) | (1 << 9));
}
