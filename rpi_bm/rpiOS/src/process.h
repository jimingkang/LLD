#ifndef PROCESS_H
#define PROCESS_H

#include <stdint.h>

#define MAX_PROCESSES 4
#define STACK_SIZE 4096
#define PROCESS_NAME_LEN 32

// Process states
typedef enum {
    PROCESS_READY = 0,
    PROCESS_RUNNING,
    PROCESS_BLOCKED,
    PROCESS_TERMINATED
} process_state_t;

typedef struct {
    uint64_t x0, x1, x2, x3, x4, x5, x6, x7, x8, x9;
    uint64_t x10, x11, x12, x13, x14, x15, x16, x17, x18;
    uint64_t x19, x20, x21, x22, x23, x24, x25, x26, x27, x28;
    uint64_t fp, lr, sp;
    uint64_t elr_el1;           // Exception Link Register (user PC)
    uint64_t spsr_el1;          // Saved Program Status Register
    uint64_t sp_el0;            // User mode stack pointer
} cpu_context_t;

// Process Control Block
typedef struct process {
    int pid;                        // Process ID
    char name[PROCESS_NAME_LEN];    // Process name
    process_state_t state;          // Process state
    int priority;                   // Process priority (0-10, higher = more priority)
    uint64_t stack_base;            // Stack base address
    uint64_t user_stack_base;       // User stack base address
    cpu_context_t cpu_context;      // Saved CPU context
    uint64_t runtime;               // Total runtime in ticks
    struct process* next;           // Next process in queue
} process_t;

// Process function pointer type
typedef void (*process_func_t)(void);

// Process management functions
void process_init(void);
int process_create(const char* name, process_func_t func, int priority);
void process_schedule(void);
void process_yield(void);
void process_exit(void);
void process_sleep(int ticks);
process_t* get_current_process(void);
void print_process_list(void);

#define schedule() process_schedule()
extern process_t* current_process;

void syscall_yield(void);
void syscall_exit(void);
void syscall_print(const char* msg);

// Context switching (implemented in assembly)
extern void switch_to_user(cpu_context_t* context);
extern void save_user_context(cpu_context_t* context);

#endif
