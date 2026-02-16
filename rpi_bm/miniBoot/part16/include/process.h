#pragma once

#include "common.h"
#include "mm.h"

#define MAX_PROCESSES 64
#define PROCESS_STACK_SIZE (4 * PAGE_SIZE)  // 16KB stack per process

typedef enum {
    PROCESS_STATE_READY = 0,
    PROCESS_STATE_RUNNING,
    PROCESS_STATE_BLOCKED,
    PROCESS_STATE_TERMINATED
} process_state_t;

typedef struct {
    u64 x0, x1, x2, x3, x4, x5, x6, x7, x8, x9;
    u64 x10, x11, x12, x13, x14, x15, x16, x17, x18, x19;
    u64 x20, x21, x22, x23, x24, x25, x26, x27, x28, x29;
    u64 x30;           // Link register
    u64 sp;            // Stack pointer
    u64 pc;            // Program counter
    u64 pstate;        // Processor state
} process_context_t;

typedef struct process {
    u32 pid;                           // Process ID
    process_state_t state;             // Process state
    process_context_t context;         // CPU context
    void *stack_base;                  // Stack base address
    u32 stack_size;                    // Stack size
    void (*entry_point)(void);         // Process entry point
    u32 priority;                      // Process priority (0 = highest)
    struct process *next;              // Next process in list
    char name[32];                     // Process name
} process_t;

// Process management functions
void process_init(void);
process_t *process_create(const char *name, void (*entry_point)(void), u32 priority);
void process_destroy(process_t *proc);
void process_start(process_t *proc);
void process_yield(void);
void process_block(process_t *proc);
void process_unblock(process_t *proc);
process_t *process_get_current(void);
process_t *process_get_by_pid(u32 pid);
void process_list_all(void);

// Scheduler functions
void scheduler_init(void);
void scheduler_add_process(process_t *proc);
void scheduler_remove_process(process_t *proc);
process_t *scheduler_get_next(void);
void scheduler_tick(void);

// Context switching functions
void context_switch(process_context_t *old_context, process_context_t *new_context);
void save_context(process_context_t *context);
void restore_context(process_context_t *context);

#endif