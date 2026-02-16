#ifndef HARDWARE_H
#define HARDWARE_H

#include <stdint.h>
#include <stdint.h>
#include <stdbool.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef volatile u32 reg32;

// Base addresses
#define PERIPHERAL_BASE   0x3F000000
#define GPIO_BASE        (PERIPHERAL_BASE + 0x200000)
#define UART0_BASE       (PERIPHERAL_BASE + 0x201000)
#define IRQ_BASE         (PERIPHERAL_BASE + 0x00B000)
#define TIMER_BASE       (PERIPHERAL_BASE + 0x003000)

// GPIO registers
#define GPFSEL0          ((volatile uint32_t*)(GPIO_BASE + 0x00))
#define GPFSEL1          ((volatile uint32_t*)(GPIO_BASE + 0x04))
#define GPFSEL2          ((volatile uint32_t*)(GPIO_BASE + 0x08))
#define GPSET0           ((volatile uint32_t*)(GPIO_BASE + 0x1C))
#define GPCLR0           ((volatile uint32_t*)(GPIO_BASE + 0x28))
#define GPPUD            ((volatile uint32_t*)(GPIO_BASE + 0x94))
#define GPPUDCLK0        ((volatile uint32_t*)(GPIO_BASE + 0x98))

// UART registers
#define UART0_DR         ((volatile uint32_t*)(UART0_BASE + 0x00))
#define UART0_RSRECR     ((volatile uint32_t*)(UART0_BASE + 0x04))
#define UART0_FR         ((volatile uint32_t*)(UART0_BASE + 0x18))
#define UART0_ILPR       ((volatile uint32_t*)(UART0_BASE + 0x20))
#define UART0_IBRD       ((volatile uint32_t*)(UART0_BASE + 0x24))
#define UART0_FBRD       ((volatile uint32_t*)(UART0_BASE + 0x28))
#define UART0_LCRH       ((volatile uint32_t*)(UART0_BASE + 0x2C))
#define UART0_CR         ((volatile uint32_t*)(UART0_BASE + 0x30))
#define UART0_IFLS       ((volatile uint32_t*)(UART0_BASE + 0x34))
#define UART0_IMSC       ((volatile uint32_t*)(UART0_BASE + 0x38))
#define UART0_RIS        ((volatile uint32_t*)(UART0_BASE + 0x3C))
#define UART0_MIS        ((volatile uint32_t*)(UART0_BASE + 0x40))
#define UART0_ICR        ((volatile uint32_t*)(UART0_BASE + 0x44))

//mini_uart
struct AuxRegs {
    reg32 irq_status;
    reg32 enables;
    reg32 reserved[14];
    reg32 mu_io;
    reg32 mu_ier;
    reg32 mu_iir;
    reg32 mu_lcr;
    reg32 mu_mcr;
    reg32 mu_lsr;
    reg32 mu_msr;
    reg32 mu_scratch;
    reg32 mu_control;
    reg32 mu_status;
    reg32 mu_baud_rate;
};
#define REGS_AUX ((struct AuxRegs *) (PERIPHERAL_BASE + 0x00215000))
struct GpioPinData {
    reg32 reserved;
    reg32 data[2];
};

struct GpioRegs {
    reg32 func_select[6];
    struct GpioPinData output_set;
    struct GpioPinData output_clear;
    struct GpioPinData level;
    struct GpioPinData ev_detect_status;
    struct GpioPinData re_detect_enable;
    struct GpioPinData fe_detect_enable;
    struct GpioPinData hi_detect_enable;
    struct GpioPinData lo_detect_enable;
    struct GpioPinData async_re_detect;
    struct GpioPinData async_fe_detect;
    reg32 reserved;
    reg32 pupd_enable;
    reg32 pupd_enable_clocks[2];
};

#define REGS_GPIO ((struct GpioRegs *)(PERIPHERAL_BASE + 0x00200000))
typedef enum _GpioFunc {
    GFInput = 0,
    GFOutput = 1,
    GFAlt0 = 4,
    GFAlt1 = 5,
    GFAlt2 = 6,
    GFAlt3 = 7,
    GFAlt4 = 3,
    GFAlt5 = 2
} GpioFunc;

// IRQ registers
#define IRQ_BASIC_PENDING  ((volatile uint32_t*)(IRQ_BASE + 0x200))
#define IRQ_PENDING_1      ((volatile uint32_t*)(IRQ_BASE + 0x204))
#define IRQ_PENDING_2      ((volatile uint32_t*)(IRQ_BASE + 0x208))
#define IRQ_FIQ_CONTROL    ((volatile uint32_t*)(IRQ_BASE + 0x20C))
#define IRQ_ENABLE_1       ((volatile uint32_t*)(IRQ_BASE + 0x210))
#define IRQ_ENABLE_2       ((volatile uint32_t*)(IRQ_BASE + 0x214))
#define IRQ_ENABLE_BASIC   ((volatile uint32_t*)(IRQ_BASE + 0x218))
#define IRQ_DISABLE_1      ((volatile uint32_t*)(IRQ_BASE + 0x21C))
#define IRQ_DISABLE_2      ((volatile uint32_t*)(IRQ_BASE + 0x220))
#define IRQ_DISABLE_BASIC  ((volatile uint32_t*)(IRQ_BASE + 0x224))

// Timer registers
#define TIMER_CS         ((volatile uint32_t*)(TIMER_BASE + 0x00))
#define TIMER_CLO        ((volatile uint32_t*)(TIMER_BASE + 0x04))
#define TIMER_CHI        ((volatile uint32_t*)(TIMER_BASE + 0x08))
#define TIMER_C0         ((volatile uint32_t*)(TIMER_BASE + 0x0C))
#define TIMER_C1         ((volatile uint32_t*)(TIMER_BASE + 0x10))
#define TIMER_C2         ((volatile uint32_t*)(TIMER_BASE + 0x14))
#define TIMER_C3         ((volatile uint32_t*)(TIMER_BASE + 0x18))

// Function prototypes
void gpio_init(void);
void uart_init(void);
void miniuart_init(void);
void irq_init(void);
void timer_init(void);
void mmu_init(void);
void hardware_init(void);

// GPIO functions
void gpio_pin_set_func(unsigned int pin, unsigned int func);
void gpio_pin_set_output(unsigned int pin);
void gpio_pin_set_input(unsigned int pin);
void gpio_pin_set(unsigned int pin);
void gpio_pin_clear(unsigned int pin);

void new_gpio_pin_set_func(u8 pinNumber, GpioFunc func);
void new_gpio_pin_enable(u8 pinNumber);


// UART functions
void uart_putc(unsigned char c);
void uart_puts(const char* str);
unsigned char uart_getc(void);
void uart_put_number(unsigned int num);

// Utility functions
void delay(unsigned int count);

// Interrupt and timer functions for process scheduling
void handle_irq(void);
void handle_exception(void);
void handle_sync_exception(uint64_t esr, uint64_t elr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x8);
unsigned int get_timer_ticks(void);

#endif
