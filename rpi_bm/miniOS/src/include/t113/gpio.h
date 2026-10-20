#ifndef MINIOS_T113_GPIO_H
#define MINIOS_T113_GPIO_H

#include <stdint.h>

/*
 * Minimal sun20i-d1 / sun8iw20 PIO helpers (bank stride 0x30):
 *   +0x00..0x0c CFG0..3  4 bits/pin   function select (0 in, 1 out, 2.. alt)
 *   +0x10       DAT      1 bit/pin
 *   +0x14..0x20 DRV0..3  4 bits/pin
 *   +0x24..0x28 PULL0..1 2 bits/pin   0 none, 1 up, 2 down
 */

enum t113_gpio_port {
    T113_PB = 1, T113_PC, T113_PD, T113_PE, T113_PF, T113_PG,
};

#define T113_GPIO_IN        0u
#define T113_GPIO_OUT       1u
#define T113_GPIO_DISABLED  0xfu
#define T113_GPIO_IRQ       6u

#define T113_GPIO_IRQ_RISING  0u
#define T113_GPIO_IRQ_FALLING 1u
#define T113_GPIO_IRQ_BOTH    4u

#define T113_PULL_NONE      0u
#define T113_PULL_UP        1u
#define T113_PULL_DOWN      2u

/* Encode a pin as one number (port * 32 + pin), -1 = not connected. */
#define T113_GPIO(port, pin) ((int)((port) * 32 + (pin)))
#define T113_GPIO_NONE       (-1)

struct t113_pin {
    uint8_t port;
    uint8_t pin;
    uint8_t function;
    uint8_t pull;
};

void t113_gpio_set_function(uint32_t port, uint32_t pin, uint32_t function);
uint32_t t113_gpio_get_function(uint32_t port, uint32_t pin);
void t113_gpio_set_pull(uint32_t port, uint32_t pin, uint32_t pull);
void t113_gpio_set_value(uint32_t port, uint32_t pin, uint32_t value);
uint32_t t113_gpio_get_value(uint32_t port, uint32_t pin);

/* gpio = T113_GPIO(port, pin); ignored when gpio < 0. */
void t113_gpio_direction_output(int gpio, uint32_t value);
void t113_gpio_direction_input(int gpio);
int t113_gpio_get(int gpio);
int t113_gpio_irq_config(int gpio, uint32_t mode);
void t113_gpio_irq_enable(int gpio);
void t113_gpio_irq_disable(int gpio);
int t113_gpio_irq_pending(int gpio);
void t113_gpio_irq_ack(int gpio);

void t113_pinmux_apply(const struct t113_pin *pins, uint32_t count);

#endif
