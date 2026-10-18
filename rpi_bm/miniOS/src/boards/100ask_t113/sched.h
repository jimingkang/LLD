#ifndef MINIOS_100ASK_T113_SCHED_H
#define MINIOS_100ASK_T113_SCHED_H

#include <stdint.h>

#define T113_TASK_RUNNING 0u
#define T113_TASK_IDLE    1u
#define T113_TASK_SLEEPING 2u
#define T113_TASK_WAITING  3u
#define T113_TASK_ZOMBIE   4u

#define PF_USER           0x00000001u
#define PF_KTHREAD        0x00000002u

struct arm32_trapframe {
    uint32_t r[13];
    uint32_t user_sp;
    uint32_t user_lr;
    uint32_t pc;
    uint32_t cpsr;
};

struct t113_user_vm;

struct t113_cpu_context {
    uint32_t r4;
    uint32_t r5;
    uint32_t r6;
    uint32_t r7;
    uint32_t r8;
    uint32_t r9;
    uint32_t r10;
    uint32_t r11;
    uint32_t sp;
    uint32_t lr;
};

struct t113_task {
    /* Must stay first: switch.S receives task pointers as context pointers. */
    struct t113_cpu_context cpu_context;
    uint32_t pid;
    uint32_t state;
    uint32_t flags;
    const char *name;
    void (*entry)(void *arg);
    void *arg;
    void *kernel_stack;
    struct arm32_trapframe *trapframe;
    struct t113_user_vm *mm;
    struct t113_task *ready_prev;
    struct t113_task *ready_next;
    struct t113_task *parent;
    uint32_t wake_tick;
    int32_t exit_status;
};

extern struct t113_task *t113_current;
void t113_cpu_switch_to(struct t113_task *prev, struct t113_task *next);
void ret_from_fork(void);
void kernel_svc_entry(void);

int t113_create_kernel_thread(const char *name, void (*fn)(void *), void *arg);
int t113_create_init_user_process(const void *image, uint32_t image_size);
int32_t t113_fork_user(struct arm32_trapframe *parent_tf);
void t113_sleep_seconds(uint32_t seconds);
int32_t t113_wait_child(int32_t *status);
void t113_exit_current(int32_t status) __attribute__((noreturn));
uint32_t t113_finish_fork(struct t113_task *task);
struct arm32_trapframe *t113_task_trapframe(struct t113_task *task);
void t113_task_exit(void) __attribute__((noreturn));
void t113_sched_yield(void);

#endif
