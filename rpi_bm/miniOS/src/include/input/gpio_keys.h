#ifndef MINIOS_INPUT_GPIO_KEYS_H
#define MINIOS_INPUT_GPIO_KEYS_H

#include <stdint.h>

#define MINIOS_EV_KEY       1u
#define MINIOS_KEY_ENTER   28u

struct minios_input_event {
    uint32_t time_ms;
    uint16_t type;
    uint16_t code;
    int32_t value;
};

struct gpio_keys_platform_data {
    int gpio;
    uint32_t irq;
    uint16_t code;
    uint8_t active_low;
    uint8_t pull;
    uint32_t debounce_ms;
};

struct platform_driver;
extern struct platform_driver gpio_keys_driver;

#endif
