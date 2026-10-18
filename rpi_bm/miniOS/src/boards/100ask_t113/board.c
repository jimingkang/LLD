/*
 * 100ASK T113-S3 board description: the SoC blocks the kernel currently
 * drives, expressed as platform devices (a hand-written stand-in for a
 * device tree). Addresses/IRQs follow sun8i-t113s.dtsi.
 *
 * Registering these does NOT touch hardware: UART3 is brought up by
 * t113_uart_init() as the early console, and GIC/Timer0 are still
 * initialised explicitly from kernel_main() in their existing order.
 */
#include "platform.h"
#include "platform_device.h"
#include "board.h"

static const struct resource uart3_resources[] = {
    DEFINE_RES_MEM(T113_UART3_BASE, T113_UART3_SIZE),
    DEFINE_RES_IRQ(T113_IRQ_UART3),
};

static const struct resource gic_resources[] = {
    DEFINE_RES_MEM_NAMED(T113_GIC_DIST_BASE, T113_GIC_DIST_SIZE, "dist"),
    DEFINE_RES_MEM_NAMED(T113_GIC_CPU_BASE, T113_GIC_CPU_SIZE, "cpu"),
};

static const struct resource timer0_resources[] = {
    DEFINE_RES_MEM(T113_TIMER_BASE, T113_TIMER_SIZE),
    DEFINE_RES_IRQ(T113_IRQ_TIMER0),
};

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static struct platform_device uart3_device = {
    .name = "uart3",
    .compatible = "allwinner,sun20i-d1-uart",
    .num_resources = ARRAY_SIZE(uart3_resources),
    .resource = uart3_resources,
};

static struct platform_device gic_device = {
    .name = "gic",
    .compatible = "arm,cortex-a7-gic",
    .num_resources = ARRAY_SIZE(gic_resources),
    .resource = gic_resources,
};

static struct platform_device timer0_device = {
    .name = "timer0",
    .compatible = "allwinner,sun20i-d1-timer",
    .num_resources = ARRAY_SIZE(timer0_resources),
    .resource = timer0_resources,
};

/* Interrupt controller first, like DT probing order on real Linux. */
static struct platform_device *const board_devices[] = {
    &gic_device,
    &uart3_device,
    &timer0_device,
};

static struct platform_driver *const board_drivers[] = {
    &t113_gic_driver,
    &t113_uart_driver,
    &t113_timer_driver,
};

int t113_board_register_devices(void)
{
    int failed = 0;
    for (uint32_t i = 0; i < ARRAY_SIZE(board_devices); ++i) {
        if (platform_device_register(board_devices[i]) < 0) {
            t113_uart_puts("board: cannot register device ");
            t113_uart_puts(board_devices[i]->name);
            t113_uart_putc('\n');
            ++failed;
        }
    }
    return failed ? -EINVAL : 0;
}

int t113_board_register_drivers(void)
{
    int failed = 0;
    for (uint32_t i = 0; i < ARRAY_SIZE(board_drivers); ++i) {
        if (platform_driver_register(board_drivers[i]) < 0) {
            t113_uart_puts("board: cannot register driver ");
            t113_uart_puts(board_drivers[i]->driver.name);
            t113_uart_putc('\n');
            ++failed;
        }
    }
    return failed ? -EINVAL : 0;
}
