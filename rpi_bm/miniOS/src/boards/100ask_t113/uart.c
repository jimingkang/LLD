/* UART3 PB6/PB7 setup follows SyterKit v0.3.0.0 100ask-t113s3 board.c. */
#include "platform.h"
#include "platform_device.h"
#include "board.h"
#include "fs/devfs.h"
#include "fs/chrdev.h"
#include "irq.h"
#include "wait.h"
#include "sched.h"

typedef struct {
    volatile uint32_t rbr_thr_dll;
    volatile uint32_t ier_dlh;
    volatile uint32_t iir_fcr;
    volatile uint32_t lcr;
    volatile uint32_t mcr;
    volatile uint32_t lsr;
    volatile uint32_t msr;
    volatile uint32_t sch;
} uart_regs_t;

static uart_regs_t *const uart3 = (uart_regs_t *)(uintptr_t)T113_UART3_BASE;
#define UART_USR       (*(volatile uint32_t *)(uintptr_t)(T113_UART3_BASE + 0x7cu))
#define UART_USR_BUSY  (1u << 0)
#define UART_USR_TFNF  (1u << 1)
#define UART_USR_RFNE  (1u << 3)
#define UART_LSR_DR    (1u << 0)
#define UART_IER_ERBFI (1u << 0)
#define UART_IIR_NO_INT (1u << 0)
#define UART_IIR_ID_MASK 0x0fu
#define UART_IIR_BUSY   0x07u   /* DW APB: LCR written while USR.BUSY */
#define UART_FCR_TX_RESET 0x05u /* FIFO enable + transmit FIFO reset */
/* One byte takes ~87 us at 115200; a TX FIFO that frees no slot for 10 ms
 * has stopped draining.  Bound the wait so a stalled transmitter cannot
 * freeze the CPU (putc also runs in IRQ context with IRQs masked). */
#define UART_TX_STALL_US 10000u
#define UART_RX_BUFFER_SIZE 256u
static uint8_t rx_buffer[UART_RX_BUFFER_SIZE];
static uint32_t rx_head;
static uint32_t rx_tail;
static uint32_t rx_irq_enabled;
static uint32_t rx_watchdog_reported;
static struct wait_queue_head rx_wait = WAIT_QUEUE_HEAD_INIT;
static uint32_t tx_stall_count;
static uint32_t tx_stall_usr;
static uint32_t tx_stall_lsr;
static uint32_t tx_stall_pending;
static uint32_t tx_stall_reporting;
static uint32_t rx_irq_count;

static void t113_uart_irq(uint32_t irq, void *data);

static int uart_hw_getc_nonblock(void)
{
    uint32_t lsr = uart3->lsr;
    uint32_t usr = UART_USR;
    if (!(lsr & UART_LSR_DR) && !(usr & UART_USR_RFNE))
        return -1;
    return (int)(uart3->rbr_thr_dll & 0xffu);
}

/* Interrupt-side RX must only consume bytes certified by LSR.DR. USR.RFNE
 * is useful for early polling but can remain asserted briefly after RBR is
 * emptied on some DW APB UART integrations. */
static int uart_irq_getc_nonblock(void)
{
    if (!(uart3->lsr & UART_LSR_DR))
        return -1;
    return (int)(uart3->rbr_thr_dll & 0xffu);
}

static int rx_buffer_get_locked(void)
{
    if (rx_head == rx_tail)
        return -1;
    int character = rx_buffer[rx_tail];
    rx_tail = (rx_tail + 1u) & (UART_RX_BUFFER_SIZE - 1u);
    return character;
}

static void gpio_set_uart3(void)
{
    uint32_t cfg = mmio_read32(T113_GPIO_PB_BASE + T113_GPIO_CFG0);
    cfg &= ~((0xfu << 24) | (0xfu << 28)); /* PB6, PB7 */
    cfg |= (T113_GPIO_MUX_UART3 << 24) | (T113_GPIO_MUX_UART3 << 28);
    mmio_write32(T113_GPIO_PB_BASE + T113_GPIO_CFG0, cfg);
}

void t113_uart_init(void)
{
    uint32_t gate = mmio_read32(T113_CCU_UART_BGR);
    gate &= ~((1u << 3) | (1u << 19));
    mmio_write32(T113_CCU_UART_BGR, gate);
    for (volatile unsigned int i = 0; i < 100; ++i) { }
    gate |= (1u << 3) | (1u << 19); /* UART3 gate + reset deassert */
    mmio_write32(T113_CCU_UART_BGR, gate);

    gpio_set_uart3();

    uart3->mcr = 0x3;
    uart3->lcr = 0x80;              /* divisor latch access */
    uart3->rbr_thr_dll = 13;        /* 24 MHz / (16 * 115200) */
    uart3->ier_dlh = 0;
    uart3->lcr = 0x03;              /* 8 data bits, 1 stop, no parity */
    uart3->iir_fcr = 0x07;          /* enable and reset FIFOs */
    rx_head = rx_tail = 0;
    rx_irq_enabled = 0;
    rx_watchdog_reported = 0;
    init_waitqueue_head(&rx_wait);
}

static void uart_tx_wait_slot(void)
{
    for (uint32_t us = 0; !(UART_USR & UART_USR_TFNF); ++us) {
        if (us >= UART_TX_STALL_US) {
            /* Snapshot why TX stopped, then reset only the TX FIFO so the
             * RX FIFO and its pending input survive. */
            tx_stall_usr = UART_USR;
            tx_stall_lsr = uart3->lsr;
            ++tx_stall_count;
            tx_stall_pending = 1u;
            uart3->iir_fcr = UART_FCR_TX_RESET;
            return;
        }
        t113_udelay(1);
    }
}

static void uart_tx_report_stall(void)
{
    if (!tx_stall_pending || tx_stall_reporting)
        return;
    tx_stall_reporting = 1u;
    tx_stall_pending = 0;
    t113_uart_puts("\nuart3: TX stall #");
    t113_uart_puthex(tx_stall_count);
    t113_uart_puts(" USR=");
    t113_uart_puthex(tx_stall_usr);
    t113_uart_puts(" LSR=");
    t113_uart_puthex(tx_stall_lsr);
    t113_uart_puts(" (TX FIFO reset)\n");
    tx_stall_reporting = 0;
}

void t113_uart_putc(char c)
{
    if (c == '\n')
        t113_uart_putc('\r');
    uart_tx_wait_slot();
    uart3->rbr_thr_dll = (uint32_t)(uint8_t)c;
    uart_tx_report_stall();
}

int t113_uart_getc_nonblock(void)
{
    uint32_t flags = spin_lock_irqsave(&rx_wait.lock);
    int character = rx_buffer_get_locked();
    uint32_t irq_mode = rx_irq_enabled;
    spin_unlock_irqrestore(&rx_wait.lock, flags);
    if (character >= 0 || irq_mode)
        return character;
    return uart_hw_getc_nonblock();
}

int t113_uart_read(void *buffer, uint32_t count)
{
    uint8_t *bytes = (uint8_t *)buffer;
    uint32_t done = 0;
    if (!buffer || !count)
        return 0;

    while (done < count) {
        uint32_t flags = spin_lock_irqsave(&rx_wait.lock);
        int character = rx_buffer_get_locked();
        if (character >= 0) {
            bytes[done++] = (uint8_t)character;
            spin_unlock_irqrestore(&rx_wait.lock, flags);
            /* A terminal read may return as soon as one byte is available. */
            break;
        }
        if (!rx_irq_enabled) {
            spin_unlock_irqrestore(&rx_wait.lock, flags);
            character = uart_hw_getc_nonblock();
            if (character >= 0) {
                bytes[done++] = (uint8_t)character;
                break;
            }
            __asm__ volatile("yield" ::: "memory");
            continue;
        }
        /* The FIFO-empty check and waiter insertion share rx_wait.lock with
         * the IRQ producer, preventing a character/wakeup from being lost. */
        wait_queue_sleep_locked(&rx_wait, flags);
    }
    return (int)done;
}

void t113_uart_irq_init(void)
{
    if (t113_request_irq(T113_IRQ_UART3, t113_uart_irq, 0) < 0) {
        t113_uart_puts("uart3: cannot request IRQ\n");
        return;
    }
    uint32_t flags = spin_lock_irqsave(&rx_wait.lock);
    rx_irq_enabled = 1u;
    spin_unlock_irqrestore(&rx_wait.lock, flags);
    uart3->ier_dlh = UART_IER_ERBFI;
    __asm__ volatile("dsb sy" ::: "memory");
    t113_gic_enable_irq(T113_IRQ_UART3);
}

static void t113_uart_irq(uint32_t irq, void *data)
{
    (void)irq;
    (void)data;
    t113_uart_irq_handler();
}

static uint32_t uart_rx_drain(void)
{
    uint32_t received = 0;
    /* Drain by FIFO state, not by IIR.  On this DesignWare UART IIR may say
     * "no interrupt pending" immediately after the first RBR read although
     * RFNE/DR still reports more bytes from the same terminal burst. */
    for (uint32_t guard = 0; guard < UART_RX_BUFFER_SIZE; ++guard) {
        int character = uart_irq_getc_nonblock();
        if (character < 0) {
            (void)uart3->lsr; /* acknowledge a possible line-status cause */
            break;
        }
        uint32_t flags = spin_lock_irqsave(&rx_wait.lock);
        uint32_t next = (rx_head + 1u) & (UART_RX_BUFFER_SIZE - 1u);
        if (next != rx_tail) {
            rx_buffer[rx_head] = (uint8_t)character;
            rx_head = next;
            received = 1u;
        }
        spin_unlock_irqrestore(&rx_wait.lock, flags);
    }
    /* Keep RX armed explicitly. This is harmless on standard 16550 parts
     * and avoids a lost enable on DW variants after timeout/line-status
     * interrupt service. */
    uart3->ier_dlh = UART_IER_ERBFI;
    __asm__ volatile("dsb sy" ::: "memory");
    if (received)
        wake_up_all(&rx_wait);
    return received;
}

void t113_uart_irq_handler(void)
{
    /* Reading IIR snapshots/acknowledges the DW interrupt reason, but do not
     * trust a transient NO_INT value over the architected LSR.DR bit.
     * Busy-detect is the one cause that only a USR read clears; left
     * pending it keeps the level IRQ asserted. */
    ++rx_irq_count;
    if ((uart3->iir_fcr & UART_IIR_ID_MASK) == UART_IIR_BUSY)
        (void)UART_USR;
    (void)uart_rx_drain();
}

void t113_uart_rx_watchdog(void)
{
    if (!(uart3->lsr & UART_LSR_DR))
        return;
    if (uart_rx_drain() && !rx_watchdog_reported) {
        rx_watchdog_reported = 1u;
        t113_uart_puts("uart3: recovered missed RX interrupt\n");
    }
}

uint32_t t113_uart_lsr(void)
{
    return uart3->lsr;
}

uint32_t t113_uart_usr(void)
{
    return UART_USR;
}

uint32_t t113_uart_ier(void)
{
    return uart3->ier_dlh;
}

void t113_uart_putx(uint32_t value)
{
    static const char digits[] = "0123456789abcdef";
    int shift = 28;
    while (shift > 0 && !((value >> shift) & 0xfu))
        shift -= 4;
    for (; shift >= 0; shift -= 4)
        t113_uart_putc(digits[(value >> shift) & 0xfu]);
}

uint32_t t113_uart_rx_irq_count(void)
{
    return rx_irq_count;
}

void t113_uart_debug_print(void)
{
    t113_uart_puts(" q");
    t113_uart_putx(rx_irq_count);
    t113_uart_puts(" r");
    t113_uart_putx(rx_head);
    t113_uart_putc('/');
    t113_uart_putx(rx_tail);
    t113_uart_puts(" w");
    if (rx_wait.head)
        t113_uart_putx(rx_wait.head->pid);
    else
        t113_uart_putc('-');
}

static int console_read(struct file *file, void *buffer, uint32_t count)
{
    (void)file;
    return t113_uart_read(buffer, count);
}

static int console_write(struct file *file, const void *buffer, uint32_t count)
{
    (void)file;
    const uint8_t *bytes = (const uint8_t *)buffer;
    for (uint32_t i = 0; i < count; ++i)
        t113_uart_putc((char)bytes[i]);
    return (int)count;
}

static const struct file_operations console_fops = {
    .read = console_read,
    .write = console_write,
};

char t113_uart_getc(void)
{
    int c;
    while ((c = t113_uart_getc_nonblock()) < 0)
        __asm__ volatile("yield");
    return (char)c;
}

void t113_uart_puts(const char *s)
{
    while (*s)
        t113_uart_putc(*s++);
}

void t113_uart_puthex(uint32_t value)
{
    static const char digits[] = "0123456789abcdef";

    t113_uart_puts("0x");
    for (int shift = 28; shift >= 0; shift -= 4)
        t113_uart_putc(digits[(value >> shift) & 0xfu]);
}

/*
 * Platform driver binding for the UART3 platform device. The port is already
 * running as the early console (t113_uart_init() is the first thing
 * kernel_main() does), so probe only checks that the board description
 * matches the hard-wired console registers and records them as drvdata.
 */
static int t113_uart_probe(struct platform_device *pdev)
{
    const struct resource *mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);

    if (!mem || mem->start != T113_UART3_BASE ||
        resource_size(mem) < sizeof(uart_regs_t))
        return -ENODEV;     /* only the early-console port is supported */
    if (platform_get_irq(pdev, 0) < 0)
        return -ENODEV;
    platform_set_drvdata(pdev, uart3);
    if (t113_chrdev_register(1u, 0u, &console_fops) < 0 ||
        t113_chrdev_register(3u, 0u, &console_fops) < 0 ||
        t113_devfs_create_chrdev("console", 1u, 0u) < 0 ||
        t113_devfs_create_chrdev("ttyS0", 3u, 0u) < 0)
        return -ENOSPC;
    platform_dev_info(pdev, "early console bound (hw already up)");
    return 0;
}

static const struct of_device_id t113_uart_of_match[] = {
    { .compatible = "allwinner,sun20i-d1-uart" },
    { .compatible = "snps,dw-apb-uart" },
    { 0 },
};

struct platform_driver t113_uart_driver = {
    .probe = t113_uart_probe,
    .driver = { .name = "t113-uart" },
    .of_match_table = t113_uart_of_match,
};
