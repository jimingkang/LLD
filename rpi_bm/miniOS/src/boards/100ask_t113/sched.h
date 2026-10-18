#ifndef MINIOS_100ASK_T113_SCHED_H
#define MINIOS_100ASK_T113_SCHED_H

#include <stdint.h>

#define T113_TASK_RUNNING 0u
#define T113_TASK_IDLE    1u

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
    const char *name;
    void (*entry)(void *arg);
    void *arg;
    void *kernel_stack;
    struct t113_task *ready_prev;
    struct t113_task *ready_next;
};

extern struct t113_task *t113_current;
void t113_cpu_switch_to(struct t113_task *prev, struct t113_task *next);

#endif
