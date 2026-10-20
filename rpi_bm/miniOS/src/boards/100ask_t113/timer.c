#include "platform.h"
#include "platform_device.h"
#include "board.h"
#include "sched.h"

#define TIMER_IRQ_EN       (T113_TIMER_BASE + 0x00u)
#define TIMER_IRQ_STATUS   (T113_TIMER_BASE + 0x04u)
#define TIMER0_CTRL        (T113_TIMER_BASE + 0x10u)
#define TIMER0_INTERVAL    (T113_TIMER_BASE + 0x14u)

#define TIMER_CTRL_ENABLE  (1u << 0)
#define TIMER_CTRL_RELOAD  (1u << 1)
#define TIMER_CTRL_OSC24M  (1u << 2)

static volatile uint32_t ticks;

/* 1: print one status line per Timer0 tick (once a second): who runs,
 * every task's state, UART3 IER/LSR/USR, and the GIC view of IRQ 37.
 * If the lines keep coming after a hang, the CPU and Timer0 are alive. */
#ifndef SCHED_STATUS_TRACE
#define SCHED_STATUS_TRACE 0
#endif

/* 1: minimal-timing heartbeat.  Every 5th tick prints '.', and a tick that
 * saw new UART3 IRQs prints "<qN>" (N = total UART IRQs, hex).  A few
 * characters per second at most, so it barely perturbs timing.  Dots that
 * keep coming during a "hang" mean the CPU and Timer0 are alive. */
#ifndef HEARTBEAT_TRACE
#define HEARTBEAT_TRACE 0
#endif

#if HEARTBEAT_TRACE
static void heartbeat(void)
{
    static uint32_t last_rx_irqs;
    uint32_t rx_irqs = t113_uart_rx_irq_count();
    if (rx_irqs != last_rx_irqs) {
        last_rx_irqs = rx_irqs;
        t113_uart_puts("<q");
        t113_uart_putx(rx_irqs);
        t113_uart_putc('>');
    }
    if (ticks % 5u == 0)
        t113_uart_putc('.');
}
#endif

#if SCHED_STATUS_TRACE
static void status_line(void)
{
    /* Kept short (< 76 columns) so narrow terminals do not truncate it. */
    t113_uart_puts("st ");
    t113_uart_putx(ticks);
    t113_sched_debug_print();
    t113_uart_puts(" i");
    t113_uart_putx(t113_uart_ier());
    t113_uart_puts(" l");
    t113_uart_putx(t113_uart_lsr());
    t113_uart_puts(" u");
    t113_uart_putx(t113_uart_usr());
    t113_uart_puts(" g");
    t113_uart_putx(t113_gic_irq_state(T113_IRQ_UART3));
    t113_uart_puts(" h");
    t113_uart_putx(t113_gic_highest_pending());
    t113_uart_debug_print();
    t113_uart_putc('\n');
}
#endif

void t113_timer0_init(void)
{
    mmio_write32(TIMER0_CTRL, 0);
    mmio_write32(TIMER_IRQ_EN, 0);
    mmio_write32(TIMER_IRQ_STATUS, 1u);

    /* 24 MHz clock, no prescaler, continuous mode: one interrupt per second. */
    mmio_write32(TIMER0_INTERVAL, 24000000u);
    mmio_write32(TIMER0_CTRL, TIMER_CTRL_OSC24M | TIMER_CTRL_RELOAD);
    while (mmio_read32(TIMER0_CTRL) & TIMER_CTRL_RELOAD) { }

    mmio_write32(TIMER_IRQ_EN, 1u);
    t113_gic_enable_irq(T113_IRQ_TIMER0);
    mmio_write32(TIMER0_CTRL, TIMER_CTRL_OSC24M | TIMER_CTRL_ENABLE);
}

void t113_timer0_acknowledge(void)
{
    mmio_write32(TIMER_IRQ_STATUS, 1u);
}

uint32_t t113_timer_ticks(void)
{
    return ticks;
}

void t113_irq_handler(void)
{
    uint32_t ack = t113_gic_acknowledge();
    uint32_t irq = ack & 0x3ffu;

    if (irq == T113_IRQ_TIMER0) {
        t113_timer0_acknowledge();
        ++ticks;
        t113_uart_rx_watchdog();
#if SCHED_STATUS_TRACE
        status_line();
#endif
#if HEARTBEAT_TRACE
        heartbeat();
#endif
#ifdef CONFIG_DEBUG_TIMER_TICK
        t113_uart_puts("timer0 tick ");
        t113_uart_puthex(ticks);
        t113_uart_putc('\n');
#endif
    } else if (irq == T113_IRQ_UART3) {
        t113_uart_irq_handler();
    } else if (irq < 1020u) {
        t113_uart_puts("unexpected IRQ ");
        t113_uart_puthex(irq);
        t113_uart_putc('\n');
    }

    if (irq < 1020u)
        t113_gic_end_irq(ack);

    /* EOI must be visible before a context switch can leave this handler.
     * UART RX may have made a console reader runnable, so dispatch it now
     * instead of waiting for the next one-second timer tick. */
    if (irq == T113_IRQ_TIMER0)
        t113_sched_tick();
    else if (irq == T113_IRQ_UART3)
        t113_sched_yield();
}

/*
 * Platform driver binding for Timer0. The timer is still started by
 * t113_timer0_init() at the end of kernel_main(), once /init is loaded;
 * probe only checks the register window and IRQ match this file.
 */
static int t113_timer_probe(struct platform_device *pdev)
{
    const struct resource *mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);

    if (!mem || mem->start != T113_TIMER_BASE ||
        resource_size(mem) < 0x18u)
        return -ENODEV;
    if (platform_get_irq(pdev, 0) != (int)T113_IRQ_TIMER0)
        return -ENODEV;
    platform_set_drvdata(pdev, (void *)(uintptr_t)T113_TIMER_BASE);
    platform_dev_info(pdev, "bound (start deferred to t113_timer0_init)");
    return 0;
}

static const struct of_device_id t113_timer_of_match[] = {
    { .compatible = "allwinner,sun20i-d1-timer" },
    { .compatible = "allwinner,sun8i-a23-timer" },
    { 0 },
};

struct platform_driver t113_timer_driver = {
    .probe = t113_timer_probe,
    .driver = { .name = "sun4i-timer" },
    .of_match_table = t113_timer_of_match,
};
