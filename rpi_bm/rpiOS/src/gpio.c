#include "hardware.h"

void gpio_init(void) {
    // Initialize GPIO pins for UART (pins 14 and 15)
    gpio_pin_set_func(14, 4); // TXD0
    gpio_pin_set_func(15, 4); // RXD0
    
    // Disable pull-up/down for pins 14 and 15
    *GPPUD = 0;
    delay(150);
    *GPPUDCLK0 = (1 << 14) | (1 << 15);
    delay(150);
    *GPPUDCLK0 = 0;
}

void gpio_pin_set_func(unsigned int pin, unsigned int func) {
    unsigned int reg_index = pin / 10;
    unsigned int bit = (pin % 10) * 3;
    
    volatile uint32_t* reg = &GPFSEL0[reg_index];
    *reg &= ~(7 << bit);
    *reg |= func << bit;
}

void gpio_pin_set_output(unsigned int pin) {
    gpio_pin_set_func(pin, 1);
}

void gpio_pin_set_input(unsigned int pin) {
    gpio_pin_set_func(pin, 0);
}

void gpio_pin_set(unsigned int pin) {
    if (pin < 32) {
        *GPSET0 = 1 << pin;
    }
}

void gpio_pin_clear(unsigned int pin) {
    if (pin < 32) {
        *GPCLR0 = 1 << pin;
    }
}


void new_gpio_pin_set_func(u8 pinNumber, GpioFunc func) {
    u8 bitStart = (pinNumber * 3) % 30;
    u8 reg = pinNumber / 10;

    u32 selector = REGS_GPIO->func_select[reg];
    selector &= ~(7 << bitStart);
    selector |= (func << bitStart);

    REGS_GPIO->func_select[reg] = selector;
}

void new_gpio_pin_enable(u8 pinNumber) {
    REGS_GPIO->pupd_enable = 0;
    delay(150);
    REGS_GPIO->pupd_enable_clocks[pinNumber / 32] = 1 << (pinNumber % 32);
    delay(150);
    REGS_GPIO->pupd_enable = 0;
    REGS_GPIO->pupd_enable_clocks[pinNumber / 32] = 0;
}
