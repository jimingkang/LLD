#include "platform.h"
#include "gpio.h"

#define GPIO_CFG(port, pin)  (T113_PIO_BASE + (port) * T113_GPIO_BANK_STRIDE + \
                              ((pin) / 8u) * 4u)
#define GPIO_DAT(port)       (T113_PIO_BASE + (port) * T113_GPIO_BANK_STRIDE + 0x10u)
#define GPIO_PULL(port, pin) (T113_PIO_BASE + (port) * T113_GPIO_BANK_STRIDE + \
                              0x24u + ((pin) / 16u) * 4u)
#define GPIO_IRQ_BASE(port)  (T113_PIO_BASE + 0x200u + ((port) - T113_PB) * 0x20u)
#define GPIO_IRQ_CFG(port, pin) (GPIO_IRQ_BASE(port) + ((pin) / 8u) * 4u)
#define GPIO_IRQ_CTRL(port)  (GPIO_IRQ_BASE(port) + 0x10u)
#define GPIO_IRQ_STATUS(port) (GPIO_IRQ_BASE(port) + 0x14u)
#define GPIO_IRQ_DEBOUNCE(port) (GPIO_IRQ_BASE(port) + 0x18u)

static void rmw(uint32_t addr, uint32_t mask, uint32_t value)
{
    mmio_write32(addr, (mmio_read32(addr) & ~mask) | (value & mask));
}

void t113_gpio_set_function(uint32_t port, uint32_t pin, uint32_t function)
{
    uint32_t shift = (pin % 8u) * 4u;
    rmw(GPIO_CFG(port, pin), 0xfu << shift, function << shift);
}

uint32_t t113_gpio_get_function(uint32_t port, uint32_t pin)
{
    return (mmio_read32(GPIO_CFG(port, pin)) >> ((pin % 8u) * 4u)) & 0xfu;
}

void t113_gpio_set_pull(uint32_t port, uint32_t pin, uint32_t pull)
{
    uint32_t shift = (pin % 16u) * 2u;
    rmw(GPIO_PULL(port, pin), 0x3u << shift, pull << shift);
}

void t113_gpio_set_value(uint32_t port, uint32_t pin, uint32_t value)
{
    rmw(GPIO_DAT(port), 1u << pin, (value ? 1u : 0u) << pin);
}

uint32_t t113_gpio_get_value(uint32_t port, uint32_t pin)
{
    return (mmio_read32(GPIO_DAT(port)) >> pin) & 1u;
}

void t113_gpio_direction_output(int gpio, uint32_t value)
{
    if (gpio < 0)
        return;
    uint32_t port = (uint32_t)gpio / 32u, pin = (uint32_t)gpio % 32u;
    t113_gpio_set_value(port, pin, value);
    t113_gpio_set_function(port, pin, T113_GPIO_OUT);
}

void t113_gpio_direction_input(int gpio)
{
    if (gpio < 0)
        return;
    uint32_t port = (uint32_t)gpio / 32u, pin = (uint32_t)gpio % 32u;
    t113_gpio_set_function(port, pin, T113_GPIO_IN);
}

int t113_gpio_get(int gpio)
{
    if (gpio < 0)
        return -1;
    return (int)t113_gpio_get_value((uint32_t)gpio / 32u,
                                    (uint32_t)gpio % 32u);
}

int t113_gpio_irq_config(int gpio, uint32_t mode)
{
    if (gpio < 0)
        return -1;
    uint32_t port = (uint32_t)gpio / 32u, pin = (uint32_t)gpio % 32u;
    if (port < T113_PB || port > T113_PG || pin >= 32u)
        return -1;
    uint32_t shift = (pin % 8u) * 4u;
    t113_gpio_irq_disable(gpio);
    rmw(GPIO_IRQ_CFG(port, pin), 0xfu << shift, mode << shift);
    /* 32 kHz debounce clock, maximum /128 prescale (~3.9 ms). */
    mmio_write32(GPIO_IRQ_DEBOUNCE(port), 0x71u);
    t113_gpio_set_function(port, pin, T113_GPIO_IRQ);
    t113_gpio_irq_ack(gpio);
    return 0;
}

void t113_gpio_irq_enable(int gpio)
{
    uint32_t port = (uint32_t)gpio / 32u, pin = (uint32_t)gpio % 32u;
    rmw(GPIO_IRQ_CTRL(port), 1u << pin, 1u << pin);
}

void t113_gpio_irq_disable(int gpio)
{
    uint32_t port = (uint32_t)gpio / 32u, pin = (uint32_t)gpio % 32u;
    rmw(GPIO_IRQ_CTRL(port), 1u << pin, 0);
}

int t113_gpio_irq_pending(int gpio)
{
    uint32_t port = (uint32_t)gpio / 32u, pin = (uint32_t)gpio % 32u;
    return !!(mmio_read32(GPIO_IRQ_STATUS(port)) & (1u << pin));
}

void t113_gpio_irq_ack(int gpio)
{
    uint32_t port = (uint32_t)gpio / 32u, pin = (uint32_t)gpio % 32u;
    mmio_write32(GPIO_IRQ_STATUS(port), 1u << pin);
}

void t113_pinmux_apply(const struct t113_pin *pins, uint32_t count)
{
    for (uint32_t i = 0; i < count; ++i) {
        t113_gpio_set_pull(pins[i].port, pins[i].pin, pins[i].pull);
        t113_gpio_set_function(pins[i].port, pins[i].pin, pins[i].function);
    }
}
