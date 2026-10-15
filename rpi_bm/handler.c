#include "stdint.h"
#include "print.h"
#include "lib.h"
#include "irq.h"
#include "uart.h"
#include "handler.h"
#include "syscall.h"
#include "process.h"

void enable_timer(void);
uint32_t read_timer_status(void);
void set_timer_interval(uint32_t value);
uint32_t read_timer_freq(void);

static uint32_t timer_interval = 0;
static uint64_t ticks = 0;

uint64_t get_ticks(void)
{
    return ticks;
}

void init_interrupt_controller(void)
{
    out_word(DISABLE_BASIC_IRQS, 0xffffffff);
    out_word(DISABLE_IRQS_1, 0xffffffff);
    out_word(DISABLE_IRQS_2, 0xffffffff);

    out_word(ENABLE_IRQS_2, (1 << 25));
}

void init_timer(void)
{
    timer_interval = read_timer_freq() / 100;
    enable_timer();
    out_word(CNTP_EL0, (1 << 1));
}

void check_sleep_list(void)
{
    struct ProcessControl *pc = get_pc();
    struct List *cur = pc->wait_list.next;
    struct List *prev = (struct List*)&pc->wait_list;

    while (cur != 0) {

        struct Process *p = (struct Process*)cur;

        p->wait--;

        if (p->wait <= 0) {

            struct List *next = cur->next;

            prev->next = next;
            if (next == 0)
                pc->wait_list.tail = prev;

            p->state = PROC_READY;
            append_list_tail(&pc->ready_list, cur);

            cur = next;
            continue;
        }

        prev = cur;
        cur = cur->next;
    }
}

static void timer_interrupt_handler(void)
{
    uint32_t status = read_timer_status();
    if (status & (1 << 2)) {
        ticks++;
         wake_up(-1);
       // check_sleep_list();
        if (ticks % 100 == 0) {
           // printk("timer %d \r\n", ticks);
        }

        set_timer_interval(timer_interval);
    }
}

static uint32_t get_irq_number(void)
{
    return in_word(IRQ_BASIC_PENDING);
}

void handler(struct TrapFrame *tf)
{
    uint32_t irq;
    int schedule = 0;

    switch (tf->trapno) {
        case 1:
            printk("sync error at %x: %x\r\n", tf->elr, tf->esr);
            while (1) { }
            break;

        case 2:
            irq = in_word(CNTP_STATUS_EL0);
            if (irq & (1 << 1)) {
                timer_interrupt_handler();
                schedule = 1;
            }
            else {
                irq = get_irq_number();
                if (irq & (1 << 19)) {
                    uart_handler();
                }
                else {
                    printk("unknown irq\r\n");
                    while (1) { }
                }
            }
            break;

        case 3:
            system_call(tf);
            /*
             printk("---- syscall trapframe ----\n");
    printk(" tf=%x\n", tf);
    printk(" sp0   = 0x%x\n", tf->sp0);
    printk(" trapno= %d\n", tf->trapno);
    printk(" esr   = 0x%x\n", tf->esr);
    printk(" elr   = 0x%x\n", tf->elr);
    printk(" spsr  = 0x%x\n", tf->spsr);
    */
            break;

        default:
            printk("unknown exception\r\n");
            while (1) { }
    }

    if (schedule == 1) {
        yield();
    }
}