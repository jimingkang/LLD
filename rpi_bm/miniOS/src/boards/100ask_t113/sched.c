#include "platform.h"
#include "sched.h"

#define TASK_COUNT 3u
#define TASK_STACK_SIZE 4096u

static struct t113_task tasks[TASK_COUNT];
struct t113_task *t113_current = &tasks[0];
static struct t113_task *ready_head;

static void kernel_thread_entry(void) __attribute__((noreturn));

static void worker(void *arg)
{
    const char *name = (const char *)arg;

    for (;;) {
        t113_uart_puts("running ");
        t113_uart_puts(name);
        t113_uart_puts(" pid=");
        t113_uart_puthex(t113_current->pid);
        t113_uart_puts(" sp=");
        uint32_t sp;
        __asm__ volatile("mov %0, sp" : "=r"(sp));
        t113_uart_puthex(sp);
        t113_uart_putc('\n');
        __asm__ volatile("wfi");
    }
}

static void init_task(struct t113_task *task, uint32_t pid, const char *name,
                      void (*entry)(void *), void *arg)
{
    uint8_t *stack = (uint8_t *)t113_alloc_page();

    if (!stack) {
        t113_uart_puts("PANIC: no page for kernel stack\n");
        for (;;)
            __asm__ volatile("wfi");
    }

    task->pid = pid;
    task->state = T113_TASK_RUNNING;
    task->name = name;
    task->entry = entry;
    task->arg = arg;
    task->kernel_stack = stack;
    task->cpu_context.sp = ((uint32_t)(uintptr_t)(stack + TASK_STACK_SIZE)) & ~7u;
    task->cpu_context.lr = (uint32_t)(uintptr_t)kernel_thread_entry;
}

static void print_task_layout(const struct t113_task *task)
{
    t113_uart_puts("task pid=");
    t113_uart_puthex(task->pid);
    t113_uart_puts(" task/context=");
    t113_uart_puthex((uint32_t)(uintptr_t)task);
    t113_uart_puts(" initial-sp=");
    t113_uart_puthex(task->cpu_context.sp);
    t113_uart_puts(" entry-lr=");
    t113_uart_puthex(task->cpu_context.lr);
    t113_uart_putc('\n');
}

static void ready_append(struct t113_task *task)
{
    if (!ready_head) {
        ready_head = task;
        task->ready_prev = task;
        task->ready_next = task;
        return;
    }

    struct t113_task *tail = ready_head->ready_prev;
    task->ready_prev = tail;
    task->ready_next = ready_head;
    tail->ready_next = task;
    ready_head->ready_prev = task;
}

void t113_sched_init(void)
{
    tasks[0].pid = 0;
    tasks[0].state = T113_TASK_IDLE;
    tasks[0].name = "boot-idle";

    init_task(&tasks[1], 1, "kernel-thread-A", worker,
              (void *)"kernel-thread-A");
    init_task(&tasks[2], 2, "kernel-thread-B", worker,
              (void *)"kernel-thread-B");
    ready_append(&tasks[1]);
    ready_append(&tasks[2]);

    t113_uart_puts("scheduler: two ARM32 kernel threads ready\n");
    print_task_layout(&tasks[1]);
    print_task_layout(&tasks[2]);
}

void t113_sched_tick(void)
{
    struct t113_task *prev = t113_current;
    struct t113_task *next = (prev->state == T113_TASK_IDLE)
                           ? ready_head : prev->ready_next;

    if (!next || next->state != T113_TASK_RUNNING)
        return;

    t113_current = next;
    t113_uart_puts("schedule: ");
    t113_uart_puthex(prev->pid);
    t113_uart_puts(" -> ");
    t113_uart_puthex(next->pid);
    t113_uart_putc('\n');
    t113_cpu_switch_to(prev, next);
}

static void kernel_thread_entry(void)
{
    /* A new context did not arrive through RFE; explicitly permit IRQs. */
    __asm__ volatile("cpsie i" ::: "memory");
    t113_current->entry(t113_current->arg);
    for (;;)
        __asm__ volatile("wfi");
}
