#include "gpio.h"
#include "utils.h"
#include "peripherals/aux.h"
#include "mini_uart.h"
#include <io.h>


#define TXD 14
#define RXD 15

void uart_send(char c) {
    while(!(REGS_AUX->mu_lsr & 0x20));

    REGS_AUX->mu_io = c;
}

char uart_recv() {
    while(!(REGS_AUX->mu_lsr & 1));

    return REGS_AUX->mu_io & 0xFF;
}

void uart_send_string(char *str) {
    while(*str) {
        if (*str == '\n') {
            uart_send('\r');
        }

        uart_send(*str);
        str++;
    }
}

void uart_send_string2(char *str, uint64_t value, int print_hex) {
    // Print the string prefix
    while (*str) {
        if (*str == '\n') {
            uart_send('\r');
        }
        uart_send(*str);
        str++;
    }

    // If print_hex is non-zero, print the value as hexadecimal
    if (print_hex) {
        char hex_buf[19]; // Buffer for "0x" + 16 digits + newline + null
        hex_buf[0] = '0';
        hex_buf[1] = 'x';
        hex_buf[18] = '\0';

        // Convert value to hex (16 digits for 64-bit)
        for (int i = 17; i >= 2; i--) {
            int nibble = value & 0xF;
            hex_buf[i] = (nibble < 10) ? ('0' + nibble) : ('a' + nibble - 10);
            value >>= 4;
        }
        hex_buf[17] = '\n'; // Add newline

        // Send hex string
        char *ptr = hex_buf;
        while (*ptr) {
            uart_send(*ptr);
            ptr++;
        }
    }
}
int muart_read(struct _io_device *d, void *buff, u32 size) {
    u8 *buffer = buff;

    for (u32 i=0; i<size; i++) {
        *buffer++ = uart_recv();
    }

    return size;
}

int muart_write(struct _io_device *d, void *buff, u32 size) {
    u8 *buffer = buff;
    
    for (u32 i=0; i<size; i++) {
        char c = *buffer++;

        if (c == '\n') {
            size++;
            uart_send('\r');
        }

        uart_send(c);
    }

    return size;
}

io_device muart_device = {0};

void uart_init() {
    gpio_pin_set_func(TXD, GFAlt5);
    gpio_pin_set_func(RXD, GFAlt5);

    gpio_pin_enable(TXD);
    gpio_pin_enable(RXD);

    REGS_AUX->enables = 1;
    REGS_AUX->mu_control = 0;
    REGS_AUX->mu_ier = 0xD;
    REGS_AUX->mu_lcr = 3;
    REGS_AUX->mu_mcr = 0;

#if RPI_VERSION == 3
    REGS_AUX->mu_baud_rate = 270; // = 115200 @ 250 Mhz
#endif

#if RPI_VERSION == 4
    REGS_AUX->mu_baud_rate = 541; // = 115200 @ 500 Mhz
#endif

    REGS_AUX->mu_control = 3;

    uart_send('\r');
    uart_send('\n');
    uart_send('\n');

    muart_device.name = "muart";
    muart_device.read = muart_read;
    muart_device.write = muart_write;

    io_device_register(&muart_device);
}

