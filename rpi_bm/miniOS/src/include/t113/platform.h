#ifndef MINIOS_100ASK_T113_PLATFORM_H
#define MINIOS_100ASK_T113_PLATFORM_H

#include <stdint.h>

/* Allwinner T113-S3 / sun8iw20 addresses used by SyterKit v0.3.0.0. */
#define T113_CCU_BASE           0x02001000u
#define T113_PIO_BASE           0x02000000u
#define T113_UART3_BASE         0x02500c00u
#define T113_TIMER_BASE         0x02050000u
#define T113_GIC_BASE           0x03020000u
#define T113_GIC_DIST_BASE      (T113_GIC_BASE + 0x1000u)
#define T113_GIC_CPU_BASE       (T113_GIC_BASE + 0x2000u)

#define T113_UART3_SIZE         0x400u
#define T113_TIMER_SIZE         0xa0u
#define T113_GIC_DIST_SIZE      0x1000u
#define T113_GIC_CPU_SIZE       0x2000u

/* GIC interrupt IDs = 32 + SPI number (sun8i-t113s.dtsi). */
#define T113_IRQ_UART3          37u     /* GIC_SPI 5 */
#define T113_IRQ_TIMER0         91u     /* GIC_SPI 59 */
#define T113_IRQ_SMHC1          73u     /* GIC_SPI 41 */
#define T113_IRQ_VINC0          127u    /* GIC_SPI 95 */
#define T113_IRQ_CSI0           132u    /* GIC_SPI 100 */
#define T113_IRQ_GPIOB          101u    /* GIC_SPI 69 */

#define T113_CCU_UART_BGR       (T113_CCU_BASE + 0x090cu)
#define T113_CCU_TWI_BGR        (T113_CCU_BASE + 0x091cu) /* gate b0-3, rst b16-19 */
#define T113_CCU_CSI_CLK        (T113_CCU_BASE + 0x0c04u) /* CSI_TOP module clock */
#define T113_CCU_CSI_MCLK0      (T113_CCU_BASE + 0x0c08u) /* CSI master clock 0 */
#define T113_CCU_CSI_BGR        (T113_CCU_BASE + 0x0c1cu) /* gate b0, rst b16 */

/* TWI0..3, 0x400 apart (sun20i-d1 / sun8iw20). */
#define T113_TWI0_BASE          0x02502000u
#define T113_TWI_STRIDE         0x400u
#define T113_TWI_SIZE           0x400u
#define T113_TWI_BASE(n)        (T113_TWI0_BASE + (n) * T113_TWI_STRIDE)

/* SMHC0..2 (SD/MMC host), 0x1000 apart. SMHC1 = SDIO WiFi. */
#define T113_SMHC0_BASE         0x04020000u
#define T113_SMHC_STRIDE        0x1000u
#define T113_SMHC_SIZE          0x1000u
#define T113_SMHC_BASE(n)       (T113_SMHC0_BASE + (n) * T113_SMHC_STRIDE)

/* CSIC (VIN) blocks, from sun8iw20p1.dtsi vind0/csi0/vinc0 nodes. */
#define T113_CSI_TOP_BASE       0x05800000u
#define T113_CSI_TOP_SIZE       0x800u
#define T113_CSI0_BASE          0x05801000u     /* parallel parser 0 */
#define T113_CSI0_SIZE          0x1000u
#define T113_VINC0_BASE         0x05809000u     /* capture DMA 0 */
#define T113_VINC0_SIZE         0x200u

#define T113_GPIO_BANK_STRIDE   0x30u
#define T113_GPIO_PB_BASE       (T113_PIO_BASE + T113_GPIO_BANK_STRIDE)
#define T113_GPIO_CFG0          0x00u
#define T113_GPIO_MUX_UART3     7u

static inline uint32_t mmio_read32(uint32_t addr)
{
    return *(volatile uint32_t *)(uintptr_t)addr;
}

static inline void mmio_write32(uint32_t addr, uint32_t value)
{
    *(volatile uint32_t *)(uintptr_t)addr = value;
}

void t113_uart_init(void);
void t113_uart_putc(char c);
void t113_uart_puts(const char *s);
void t113_uart_puthex(uint32_t value);
int t113_uart_getc_nonblock(void);
int t113_uart_read(void *buffer, uint32_t count);
void t113_uart_irq_init(void);
void t113_uart_irq_handler(void);
void t113_uart_rx_watchdog(void);
uint32_t t113_uart_lsr(void);
uint32_t t113_uart_usr(void);
uint32_t t113_uart_ier(void);
/* Debug helpers: hex without 0x/padding, and RX-path counters
 * " q<irqs> r<head>/<tail> w<first waiter pid or ->". */
void t113_uart_putx(uint32_t value);
void t113_uart_debug_print(void);
uint32_t t113_uart_rx_irq_count(void);
char t113_uart_getc(void);
uint64_t t113_time_us(void);

void t113_gic_init(void);
void t113_gic_enable_irq(uint32_t irq);
uint32_t t113_gic_acknowledge(void);
void t113_gic_end_irq(uint32_t irq_ack);
/* Debug: bit0 pending, bit1 active, bit2 enabled for one interrupt ID. */
uint32_t t113_gic_irq_state(uint32_t irq);
uint32_t t113_gic_running_priority(void);
uint32_t t113_gic_highest_pending(void);

void t113_timer0_init(void);
void t113_timer0_acknowledge(void);
void t113_timer0_irq(uint32_t irq, void *data);
uint32_t t113_timer_ticks(void);
void t113_irq_handler(void);

/* Busy-wait using the ARMv7 generic counter (falls back to a spin loop). */
void t113_udelay(uint32_t us);
void t113_mdelay(uint32_t ms);

struct bootpack_entry;
const struct bootpack_entry *t113_bootpack_find(const char *name);
void t113_bootpack_dump(void);

void t113_mmu_init(void);
uint32_t t113_mmu_is_enabled(void);
uint32_t t113_mmu_ttbr0(void);
uint32_t t113_mmu_l1_entry(uint32_t va);

void t113_page_alloc_init(uint32_t base, uint32_t size);
void *t113_alloc_page(void);
void *t113_alloc_pages(uint32_t count, uint32_t align_pages);
void t113_free_pages(void *address, uint32_t count);
uint32_t t113_page_free_count(void);

void t113_sched_init(void);
void t113_sched_tick(void);
/* Debug: print " c<pid>:<state> <pid>:<state> ..." without a newline. */
void t113_sched_debug_print(void);

#endif
