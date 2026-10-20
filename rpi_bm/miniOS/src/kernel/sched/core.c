#include "platform.h"
#include "sched.h"
#include "user_vm.h"
#include "fs/vfs.h"
#include "spinlock.h"

#define TASK_STACK_SIZE 4096u
#define ARM_MODE_USR    0x10u

static struct t113_task boot_context;
static uint32_t next_pid = 1u;
struct t113_task *t113_current = &boot_context;
static struct t113_task *init_task;
static struct t113_task *task_head;
static struct t113_task *task_tail;
static struct t113_task *ready_head;
static spinlock_t sched_lock = SPINLOCK_INIT;

_Static_assert(__builtin_offsetof(struct arm32_trapframe, user_sp) == 52,
               "fork_entry.S TF_USER_SP offset mismatch");
_Static_assert(__builtin_offsetof(struct arm32_trapframe, pc) == 60,
               "fork_entry.S TF_PC offset mismatch");
_Static_assert(__builtin_offsetof(struct arm32_trapframe, cpsr) == 64,
               "fork_entry.S TF_CPSR offset mismatch");
_Static_assert(__builtin_offsetof(struct t113_task, cpu_context) == 0,
               "switch.S requires cpu_context at task offset zero");

static struct t113_task *alloc_process_common(void)
{
    struct t113_task *task = (struct t113_task *)t113_alloc_page();
    uint8_t *stack = (uint8_t *)t113_alloc_page();
    if (!task || !stack) {
        if (task)
            t113_free_pages(task, 1);
        if (stack)
            t113_free_pages(stack, 1);
        return 0;
    }

    uint32_t irq_flags = spin_lock_irqsave(&sched_lock);
    task->pid = next_pid++;
    spin_unlock_irqrestore(&sched_lock, irq_flags);
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

static void task_list_append(struct t113_task *task)
{
    task->task_prev = task_tail;
    task->task_next = 0;
    if (task_tail)
        task_tail->task_next = task;
    else
        task_head = task;
    task_tail = task;
}

static void task_list_remove(struct t113_task *task)
{
    if (task->task_prev)
        task->task_prev->task_next = task->task_next;
    else
        task_head = task->task_next;
    if (task->task_next)
        task->task_next->task_prev = task->task_prev;
    else
        task_tail = task->task_prev;
    task->task_prev = task->task_next = 0;
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

static void ready_remove(struct t113_task *task)
{
    if (!task->ready_next)
        return;
    if (task->ready_next == task) {
        ready_head = 0;
    } else {
        task->ready_prev->ready_next = task->ready_next;
        task->ready_next->ready_prev = task->ready_prev;
        if (ready_head == task)
            ready_head = task->ready_next;
    }
    task->ready_prev = task->ready_next = 0;
}

static void free_unlinked_task(struct t113_task *task)
{
    if (!task)
        return;
    if (task->kernel_stack)
        t113_free_pages(task->kernel_stack, 1);
    t113_free_pages(task, 1);
}

int t113_create_kernel_thread(const char *name, void (*fn)(void *), void *arg)
{
    return (int)t113_kernel_clone(T113_CLONE_KTHREAD, 0, name, fn, arg);
}

int t113_create_init_user_process(const void *image, uint32_t image_size)
{
    struct t113_task *task = alloc_process_common();
    if (!task)
        return -1;

    task->flags = PF_USER;
    task->name = "init-user";
    uint32_t entry;
    task->mm = t113_user_vm_create_elf(image, image_size, &entry);
    if (!task->mm) {
        free_unlinked_task(task);
        return -1;
    }

    task->trapframe->pc = entry;
    task->trapframe->user_sp = USER_STACK_TOP;
    task->trapframe->cpsr = ARM_MODE_USR;
    init_task = task;
    uint32_t irq_flags = spin_lock_irqsave(&sched_lock);
    task_list_append(task);
    ready_append(task);
    spin_unlock_irqrestore(&sched_lock, irq_flags);
    return (int)task->pid;
}

int32_t t113_kernel_clone(uint32_t clone_flags,
                          struct arm32_trapframe *parent_tf,
                          const char *name, void (*kernel_fn)(void *),
                          void *kernel_arg)
{
    uint32_t supported = T113_CLONE_VM | T113_CLONE_VFORK |
                         T113_CLONE_KTHREAD;
    if (clone_flags & ~supported)
        return -1;
    if ((clone_flags & T113_CLONE_VFORK) &&
        !(clone_flags & T113_CLONE_VM))
        return -1;
    if (!(clone_flags & T113_CLONE_KTHREAD) &&
        (!parent_tf || !(t113_current->flags & PF_USER)))
        return -1;

    struct t113_task *child = alloc_process_common();
    if (!child)
        return -1;

    child->name = name;
    if (clone_flags & T113_CLONE_KTHREAD) {
        child->flags = PF_KTHREAD;
        child->entry = kernel_fn;
        child->arg = kernel_arg;
        child->cpu_context.r5 = (uint32_t)(uintptr_t)kernel_fn;
        child->cpu_context.r6 = (uint32_t)(uintptr_t)kernel_arg;
    } else {
        child->flags = PF_USER;
        child->parent = t113_current;
        child->mm = (clone_flags & T113_CLONE_VM)
                  ? t113_current->mm
                  : t113_user_vm_clone(t113_current->mm);
        if (!child->mm) {
            free_unlinked_task(child);
            return -1;
        }
        if (clone_flags & T113_CLONE_VM)
            t113_user_vm_get(child->mm);
        if (clone_flags & T113_CLONE_VFORK)
            child->vfork_parent = t113_current;

        for (uint32_t i = 0; i < sizeof(*parent_tf) / sizeof(uint32_t); ++i)
            ((uint32_t *)child->trapframe)[i] =
                ((const uint32_t *)parent_tf)[i];
        child->trapframe->r[0] = 0; /* clone returns zero in the child. */
        for (uint32_t i = 0; i < T113_MAX_FDS; ++i) {
            child->files[i] = t113_current->files[i];
            t113_vfs_file_get(child->files[i]);
        }
    }
    uint32_t irq_flags = spin_lock_irqsave(&sched_lock);
    if (clone_flags & T113_CLONE_VFORK)
        t113_current->state = T113_TASK_WAITING;
    task_list_append(child);
    ready_append(child);
    spin_unlock_irqrestore(&sched_lock, irq_flags);
    if (clone_flags & T113_CLONE_VFORK) {
        t113_uart_puts("vfork: parent=");
        t113_uart_puthex(child->parent->pid);
        t113_uart_puts(" child=");
        t113_uart_puthex(child->pid);
        t113_uart_puts(" shared-L1=");
        t113_uart_puthex((uint32_t)(uintptr_t)child->mm->l1);
        t113_uart_putc('\n');
    }
    return (int32_t)child->pid;
}

int32_t t113_fork_user(struct arm32_trapframe *parent_tf)
{
    return t113_kernel_clone(0, parent_tf, "fork-child", 0, 0);
}

int32_t t113_vfork_user(struct arm32_trapframe *parent_tf)
{
    int32_t pid = t113_kernel_clone(T113_CLONE_VM | T113_CLONE_VFORK,
                                    parent_tf, "vfork-child", 0, 0);
    if (pid < 0)
        return pid;

    /* vfork does not return in the parent until the child has either
     * installed a new address space with exec or exited. */
    t113_sched_yield();
    return pid;
}

void t113_vfork_complete(struct t113_task *task)
{
    uint32_t irq_flags = spin_lock_irqsave(&sched_lock);
    if (!task || !task->vfork_parent)
    {
        spin_unlock_irqrestore(&sched_lock, irq_flags);
        return;
    }
    if (task->vfork_parent->state == T113_TASK_WAITING)
        task->vfork_parent->state = T113_TASK_RUNNING;
    task->vfork_parent = 0;
    spin_unlock_irqrestore(&sched_lock, irq_flags);
}

void t113_sleep_seconds(uint32_t seconds)
{
    if (seconds == 0)
        return;
    uint32_t irq_flags = spin_lock_irqsave(&sched_lock);
    t113_current->wake_tick = t113_timer_ticks() + seconds;
    t113_current->state = T113_TASK_SLEEPING;
    spin_unlock_irqrestore(&sched_lock, irq_flags);
    t113_sched_yield();
}

int32_t t113_wait_child(int32_t *status)
{
    for (;;) {
        int have_child = 0;
        struct t113_task *zombie = 0;
        uint32_t irq_flags = spin_lock_irqsave(&sched_lock);
        for (struct t113_task *child = task_head; child;
             child = child->task_next) {
            if (child->parent != t113_current)
                continue;
            have_child = 1;
            if (child->state == T113_TASK_ZOMBIE) {
                zombie = child;
                child->parent = 0;
                ready_remove(child);
                task_list_remove(child);
                break;
            }
        }
        if (zombie) {
            int32_t pid = (int32_t)zombie->pid;
            int32_t exit_status = zombie->exit_status;
            spin_unlock_irqrestore(&sched_lock, irq_flags);
            if (status)
                *status = exit_status;
            t113_user_vm_put(zombie->mm);
            zombie->mm = 0;
            free_unlinked_task(zombie);
            return pid;
        }
        if (!have_child) {
            spin_unlock_irqrestore(&sched_lock, irq_flags);
            return -1;
        }
        t113_current->state = T113_TASK_WAITING;
        spin_unlock_irqrestore(&sched_lock, irq_flags);
        t113_sched_yield();
    }
}

void t113_exit_current(int32_t status)
{
    struct t113_task *task = t113_current;
    t113_vfork_complete(task);
    for (uint32_t i = 0; i < T113_MAX_FDS; ++i) {
        t113_vfs_close(task->files[i]);
        task->files[i] = 0;
    }
    uint32_t irq_flags = spin_lock_irqsave(&sched_lock);
    /* As in xv6, init adopts orphaned children and eventually reaps any
     * that are already zombies. */
    for (struct t113_task *child = task_head; child;
         child = child->task_next) {
        if (child->parent != task)
            continue;
        child->parent = init_task;
        if (init_task && child->state == T113_TASK_ZOMBIE &&
            init_task->state == T113_TASK_WAITING)
            init_task->state = T113_TASK_RUNNING;
    }
    task->exit_status = status;
    task->state = T113_TASK_ZOMBIE;
    if (task->parent && task->parent->state == T113_TASK_WAITING)
        task->parent->state = T113_TASK_RUNNING;
    spin_unlock_irqrestore(&sched_lock, irq_flags);
    t113_sched_yield();
    for (;;)
        __asm__ volatile("wfi");
}

uint32_t t113_finish_fork(struct t113_task *task)
{
    if (task->flags & PF_KTHREAD) {
        t113_switch_kernel_vm();
        return PF_KTHREAD;
    }

    t113_switch_user_vm(task->mm);
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
    spin_lock_init(&sched_lock);
    boot_context.pid = 0;
    boot_context.state = T113_TASK_IDLE;
    boot_context.flags = PF_KTHREAD;
    boot_context.name = "boot-context";
    task_head = task_tail = ready_head = 0;
    next_pid = 1u;
}

static void switch_task_mm(struct t113_task *task)
{
    if (task->flags & PF_USER)
        t113_switch_user_vm(task->mm);
    else
        t113_switch_kernel_vm();
}

static void schedule_next(void)
{
    uint32_t irq_flags = local_irq_save();
    spin_lock(&sched_lock);
    struct t113_task *prev = t113_current;
    struct t113_task *next = (prev->state == T113_TASK_IDLE || !prev->ready_next)
                           ? ready_head : prev->ready_next;
    if (next) {
        struct t113_task *start = next;
        while (next->state != T113_TASK_RUNNING) {
            next = next->ready_next;
            if (next == start) {
                next = 0;
                break;
            }
        }
    }
    /* boot_context is not a process and is never linked into task_head.
     * It resumes kernel_main's WFI loop whenever every real task blocks. */
    if (!next)
        next = &boot_context;
    if (next == prev) {
        spin_unlock(&sched_lock);
        local_irq_restore(irq_flags);
        return;
    }

    t113_current = next;
    spin_unlock(&sched_lock);
    switch_task_mm(next);
    t113_cpu_switch_to(prev, next);
    local_irq_restore(irq_flags);
}

void t113_sched_tick(void)
{
    uint32_t now = t113_timer_ticks();
    uint32_t irq_flags = spin_lock_irqsave(&sched_lock);
    for (struct t113_task *task = task_head; task;
         task = task->task_next) {
        if (task->state == T113_TASK_SLEEPING &&
            (int32_t)(now - task->wake_tick) >= 0)
            task->state = T113_TASK_RUNNING;
    }
    spin_unlock_irqrestore(&sched_lock, irq_flags);
    schedule_next();
}

void t113_sched_yield(void)
{
    schedule_next();
}

/* Called from the timer IRQ with IRQs masked; reads only. */
void t113_sched_debug_print(void)
{
    t113_uart_puts(" c");
    t113_uart_putx(t113_current->pid);
    t113_uart_putc(':');
    t113_uart_putx(t113_current->state);
    for (struct t113_task *task = task_head; task; task = task->task_next) {
        t113_uart_putc(' ');
        t113_uart_putx(task->pid);
        t113_uart_putc(':');
        t113_uart_putx(task->state);
    }
}
