#include "platform.h"
#include "sched.h"
#include "user_vm.h"

#define TASK_COUNT      4u
#define TASK_STACK_SIZE 4096u
#define ARM_MODE_USR    0x10u

static struct t113_task tasks[TASK_COUNT];
static uint32_t next_task_slot = 1u;
struct t113_task *t113_current = &tasks[0];
static struct t113_task *ready_head;

_Static_assert(__builtin_offsetof(struct arm32_trapframe, user_sp) == 52,
               "fork_entry.S TF_USER_SP offset mismatch");
_Static_assert(__builtin_offsetof(struct arm32_trapframe, pc) == 60,
               "fork_entry.S TF_PC offset mismatch");
_Static_assert(__builtin_offsetof(struct arm32_trapframe, cpsr) == 64,
               "fork_entry.S TF_CPSR offset mismatch");
_Static_assert(__builtin_offsetof(struct t113_task, cpu_context) == 0,
               "switch.S requires cpu_context at task offset zero");

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

static struct t113_task *alloc_process_common(void)
{
    if (next_task_slot >= TASK_COUNT)
        return 0;

    struct t113_task *task = &tasks[next_task_slot++];
    uint8_t *stack = (uint8_t *)t113_alloc_page();
    if (!stack)
        return 0;

    for (uint32_t i = 0; i < sizeof(*task) / sizeof(uint32_t); ++i)
        ((uint32_t *)task)[i] = 0;

    task->pid = next_task_slot - 1u;
    task->state = T113_TASK_RUNNING;
    task->kernel_stack = stack;
    task->trapframe = (struct arm32_trapframe *)(
        stack + TASK_STACK_SIZE - sizeof(struct arm32_trapframe));
    for (uint32_t i = 0; i < sizeof(*task->trapframe) / sizeof(uint32_t); ++i)
        ((uint32_t *)task->trapframe)[i] = 0;

    /* Every new task takes the same first-run path.  r4-r6 are callee-saved
     * and form miniOS's private ret_from_fork convention. */
    task->cpu_context.r4 = (uint32_t)(uintptr_t)task;
    task->cpu_context.sp = (uint32_t)(uintptr_t)task->trapframe;
    task->cpu_context.lr = (uint32_t)(uintptr_t)ret_from_fork;
    return task;
}

static void print_task_layout(const struct t113_task *task)
{
    t113_uart_puts("task pid=");
    t113_uart_puthex(task->pid);
    t113_uart_puts(" flags=");
    t113_uart_puthex(task->flags);
    t113_uart_puts(" task/context=");
    t113_uart_puthex((uint32_t)(uintptr_t)task);
    t113_uart_puts(" kernel-stack=[");
    t113_uart_puthex((uint32_t)(uintptr_t)task->kernel_stack);
    t113_uart_putc(',');
    t113_uart_puthex((uint32_t)(uintptr_t)task->kernel_stack + TASK_STACK_SIZE);
    t113_uart_puts(") tf=");
    t113_uart_puthex((uint32_t)(uintptr_t)task->trapframe);
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

int t113_create_kernel_thread(const char *name, void (*fn)(void *), void *arg)
{
    struct t113_task *task = alloc_process_common();
    if (!task)
        return -1;

    task->flags = PF_KTHREAD;
    task->name = name;
    task->entry = fn;
    task->arg = arg;
    task->cpu_context.r5 = (uint32_t)(uintptr_t)fn;
    task->cpu_context.r6 = (uint32_t)(uintptr_t)arg;
    ready_append(task);
    print_task_layout(task);
    return (int)task->pid;
}

int t113_create_init_user_process(const void *image, uint32_t image_size,
                                  uint32_t entry)
{
    struct t113_task *task = alloc_process_common();
    if (!task)
        return -1;

    task->flags = PF_USER;
    task->name = "init-user";
    task->mm = t113_user_vm_create(image, image_size);
    if (!task->mm)
        return -1;

    task->trapframe->pc = entry;
    task->trapframe->user_sp = USER_STACK_TOP;
    task->trapframe->cpsr = ARM_MODE_USR;
    ready_append(task);
    print_task_layout(task);
    return (int)task->pid;
}

uint32_t t113_finish_fork(struct t113_task *task)
{
    if (task->flags & PF_KTHREAD) {
        t113_switch_kernel_vm();
        return PF_KTHREAD;
    }

    t113_switch_user_vm(task->mm);
    t113_uart_puts("ret_from_fork: user pid=");
    t113_uart_puthex(task->pid);
    t113_uart_puts(" TTBR0=");
    t113_uart_puthex(t113_mmu_ttbr0());
    t113_uart_puts(" pc=");
    t113_uart_puthex(task->trapframe->pc);
    t113_uart_puts(" sp=");
    t113_uart_puthex(task->trapframe->user_sp);
    t113_uart_putc('\n');
    return PF_USER;
}

struct arm32_trapframe *t113_task_trapframe(struct t113_task *task)
{
    return task->trapframe;
}

void t113_task_exit(void)
{
    t113_current->state = T113_TASK_IDLE;
    __asm__ volatile("cpsid i" ::: "memory");
    for (;;)
        __asm__ volatile("wfi");
}

void t113_sched_init(void)
{
    tasks[0].pid = 0;
    tasks[0].state = T113_TASK_IDLE;
    tasks[0].flags = PF_KTHREAD;
    tasks[0].name = "boot-idle";

    if (t113_create_kernel_thread("kernel-thread-A", worker,
                                  (void *)"kernel-thread-A") < 0 ||
        t113_create_kernel_thread("kernel-thread-B", worker,
                                  (void *)"kernel-thread-B") < 0) {
        t113_uart_puts("PANIC: cannot create kernel threads\n");
        for (;;)
            __asm__ volatile("wfi");
    }
    t113_uart_puts("scheduler: two ARM32 kernel threads ready\n");
}

static void switch_task_mm(struct t113_task *task)
{
    if (task->flags & PF_USER)
        t113_switch_user_vm(task->mm);
    else
        t113_switch_kernel_vm();
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
    switch_task_mm(next);
    t113_cpu_switch_to(prev, next);
}
