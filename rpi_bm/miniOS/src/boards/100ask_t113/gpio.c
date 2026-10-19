#include "platform.h"
#include "gpio.h"

#define GPIO_CFG(port, pin)  (T113_PIO_BASE + (port) * T113_GPIO_BANK_STRIDE + \
                              ((pin) / 8u) * 4u)
#define GPIO_DAT(port)       (T113_PIO_BASE + (port) * T113_GPIO_BANK_STRIDE + 0x10u)
#define GPIO_PULL(port, pin) (T113_PIO_BASE + (port) * T113_GPIO_BANK_STRIDE + \
                              0x24u + ((pin) / 16u) * 4u)

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

void t113_pinmux_apply(const struct t113_pin *pins, uint32_t count)
{
    for (uint32_t i = 0; i < count; ++i) {
        t113_gpio_set_pull(pins[i].port, pins[i].pin, pins[i].pull);
        t113_gpio_set_function(pins[i].port, pins[i].pin, pins[i].function);
    }
}
