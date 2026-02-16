#pragma once

#include "common.h"
#include "mm.h"

#define MAX_PROCESSES       64
#define PROCESS_STACK_SIZE  (4 * PAGE_SIZE)  // 16KB stack per process
#define KERNEL_THREAD_PID   0

// Process states
typedef enum {
    PROCESS_STATE_RUNNING = 0,
    PROCESS_STATE_READY,
    PROCESS_STATE_BLOCKED,
    PROCESS_STATE_TERMINATED
} process_state_t;

// CPU context structure - matches the stack frame in entry.S
typedef struct {
    u64 x0, x1, x2, x3, x4, x5, x6, x7;
    u64 x8, x9, x10, x11, x12, x13, x14, x15;
    u64 x16, x17, x18, x19, x20, x21, x22, x23;
    u64 x24, x25, x26, x27, x28, x29, x30;  // x30 is link register (LR)
    u64 sp;     // Stack pointer
    u64 pc;     // Program counter (ELR_EL1)
    u64 pstate; // Processor state (SPSR_EL1)
} cpu_context_t;

// Process Control Block (PCB)
typedef struct process {
    u32 pid;                    // Process ID
    process_state_t state;      // Process state
    cpu_context_t context;      // Saved CPU context
    void *stack_base;           // Base of process stack
    u64 stack_size;             // Size of process stack
    u32 priority;               // Process priority (0-255, lower is higher priority)
    u64 time_slice;             // Remaining time slice
    u64 total_time;             // Total CPU time used
    struct process *next;       // Next process in ready queue
    struct process *prev;       // Previous process in ready queue
    char name[32];              // Process name for debugging
} process_t;

// Process function pointer type
typedef void (*process_func_t)(void);

// Global process management functions
void process_init(void);
u32 process_create(process_func_t func, const char *name, u32 priority);
void process_terminate(u32 pid);
void process_yield(void);
void process_block(u32 pid);
void process_unblock(u32 pid);
void schedule(void);
process_t* get_current_process(void);
process_t* get_process_by_pid(u32 pid);

// Context switching functions (implemented in assembly)
void context_switch(cpu_context_t *old_context, cpu_context_t *new_context);
void process_start(process_func_t func, void *stack_top);
void process_exit_cleanup(void);

// Scheduler functions
void scheduler_tick(void);
void print_process_info(void);
void enable_scheduler(void);
void disable_scheduler(void);
void process_self_terminate(void);

// Internal process management
extern process_t processes[MAX_PROCESSES];
extern process_t *current_process;
extern process_t *ready_queue_head;
extern u32 next_pid;
extern bool scheduler_enabled;

#define PROCESS_TIME_SLICE_MS   10  // 10ms time slice per process