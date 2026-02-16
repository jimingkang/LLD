#include "process.h"
#include "mem.h"
#include "printf.h"
#include "timer.h"
#include "irq.h"
#include "utils.h"

// Global process management variables
process_t processes[MAX_PROCESSES];
process_t *current_process = NULL;
process_t *ready_queue_head = NULL;
u32 next_pid = 1;  // PID 0 reserved for kernel thread
bool scheduler_enabled = false;

// Process queue management functions
static void add_to_ready_queue(process_t *process);
static void remove_from_ready_queue(process_t *process);
static process_t* get_next_ready_process(void);
static void init_process_context(process_t *process, process_func_t func);

void process_init(void) {
    // Initialize all process slots
    for (int i = 0; i < MAX_PROCESSES; i++) {
        processes[i].pid = 0;
        processes[i].state = PROCESS_STATE_TERMINATED;
        processes[i].next = NULL;
        processes[i].prev = NULL;
    }
    
    // Create kernel thread (PID 0)
    processes[0].pid = KERNEL_THREAD_PID;
    processes[0].state = PROCESS_STATE_RUNNING;
    processes[0].priority = 0;  // Highest priority
    processes[0].time_slice = PROCESS_TIME_SLICE_MS;
    processes[0].total_time = 0;
    processes[0].stack_base = NULL;  // Kernel uses current stack
    processes[0].stack_size = 0;
    processes[0].next = NULL;
    processes[0].prev = NULL;
    strcpy(processes[0].name, "kernel");
    
    current_process = &processes[0];
    ready_queue_head = NULL;
    
    printf("Process management initialized\n");
}

u32 process_create(process_func_t func, const char *name, u32 priority) {
    if (!func || !name) {
        printf("process_create: Invalid parameters\n");
        return 0;
    }
    
    // Find free process slot
    int slot = -1;
    for (int i = 1; i < MAX_PROCESSES; i++) {  // Start from 1, skip kernel thread
        if (processes[i].state == PROCESS_STATE_TERMINATED) {
            slot = i;
            break;
        }
    }
    
    if (slot == -1) {
        printf("process_create: No free process slots\n");
        return 0;
    }
    
    process_t *process = &processes[slot];
    
    // Allocate stack for the process
    void *stack_base = get_free_pages(PROCESS_STACK_SIZE / PAGE_SIZE);
    if (!stack_base) {
        printf("process_create: Failed to allocate stack\n");
        return 0;
    }
    
    // Initialize process structure
    process->pid = next_pid++;
    process->state = PROCESS_STATE_READY;
    process->stack_base = stack_base;
    process->stack_size = PROCESS_STACK_SIZE;
    process->priority = priority;
    process->time_slice = PROCESS_TIME_SLICE_MS;
    process->total_time = 0;
    process->next = NULL;
    process->prev = NULL;
    strncpy(process->name, name, sizeof(process->name) - 1);
    process->name[sizeof(process->name) - 1] = '\0';
    
    // Initialize process context
    init_process_context(process, func);
    
    // Add to ready queue
    add_to_ready_queue(process);
    
    printf("Created process PID %d: %s (priority %d)\n", 
           process->pid, process->name, process->priority);
    
    return process->pid;
}

void process_terminate(u32 pid) {
    if (pid == KERNEL_THREAD_PID) {
        printf("process_terminate: Cannot terminate kernel thread\n");
        return;
    }
    
    process_t *process = get_process_by_pid(pid);
    if (!process || process->state == PROCESS_STATE_TERMINATED) {
        printf("process_terminate: Process PID %d not found or already terminated\n", pid);
        return;
    }
    
    // Remove from ready queue if it's there
    if (process->state == PROCESS_STATE_READY) {
        remove_from_ready_queue(process);
    }
    
    // Free the process stack
    if (process->stack_base) {
        free_memory(process->stack_base);
        process->stack_base = NULL;
    }
    
    // Mark as terminated
    process->state = PROCESS_STATE_TERMINATED;
    process->pid = 0;
    
    printf("Terminated process PID %d: %s\n", pid, process->name);
    
    // If we're terminating the current process, schedule next one
    if (process == current_process) {
        schedule();
    }
}

void process_self_terminate(void) {
    if (current_process && current_process->pid != KERNEL_THREAD_PID) {
        u32 pid = current_process->pid;
        process_terminate(pid);
    }
}

void process_yield(void) {
    if (!scheduler_enabled) {
        return;
    }
    
    // Reset time slice and schedule
    if (current_process) {
        current_process->time_slice = PROCESS_TIME_SLICE_MS;
    }
    schedule();
}

void schedule(void) {
    if (!scheduler_enabled) {
        return;
    }
    
    process_t *next_process = get_next_ready_process();
    
    // If no ready process, continue with current (should be kernel thread)
    if (!next_process) {
        if (current_process && current_process->state == PROCESS_STATE_RUNNING) {
            return;  // Keep running current process
        }
        
        // Fall back to kernel thread
        next_process = &processes[KERNEL_THREAD_PID];
    }
    
    // If it's the same process, no need to switch
    if (next_process == current_process) {
        return;
    }
    
    process_t *old_process = current_process;
    
    // Update states
    if (old_process && old_process->state == PROCESS_STATE_RUNNING) {
        if (old_process->pid != KERNEL_THREAD_PID) {
            old_process->state = PROCESS_STATE_READY;
            add_to_ready_queue(old_process);
        }
    }
    
    next_process->state = PROCESS_STATE_RUNNING;
    next_process->time_slice = PROCESS_TIME_SLICE_MS;
    remove_from_ready_queue(next_process);
    
    current_process = next_process;
    
    // Perform context switch if we have an old process
    if (old_process && old_process != next_process) {
        context_switch(&old_process->context, &next_process->context);
    }
}

void scheduler_tick(void) {
    if (!scheduler_enabled || !current_process) {
        return;
    }
    
    // Update process time statistics
    current_process->total_time++;
    
    // Decrement time slice
    if (current_process->time_slice > 0) {
        current_process->time_slice--;
    }
    
    // If time slice expired, schedule next process
    if (current_process->time_slice == 0) {
        schedule();
    }
}

process_t* get_current_process(void) {
    return current_process;
}

process_t* get_process_by_pid(u32 pid) {
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].pid == pid && processes[i].state != PROCESS_STATE_TERMINATED) {
            return &processes[i];
        }
    }
    return NULL;
}

void print_process_info(void) {
    printf("\n=== Process Information ===\n");
    printf("Current Process: PID %d (%s)\n", 
           current_process ? current_process->pid : 0,
           current_process ? current_process->name : "none");
    
    printf("Active Processes:\n");
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].state != PROCESS_STATE_TERMINATED) {
            printf("  PID %d: %s (state: %d, priority: %d, time: %llu)\n",
                   processes[i].pid, processes[i].name, 
                   processes[i].state, processes[i].priority,
                   processes[i].total_time);
        }
    }
    
    printf("Ready Queue: ");
    process_t *p = ready_queue_head;
    while (p) {
        printf("PID %d ", p->pid);
        p = p->next;
    }
    printf("\n");
}

// Static helper functions

static void add_to_ready_queue(process_t *process) {
    if (!process || process->state == PROCESS_STATE_RUNNING) {
        return;
    }
    
    // Remove from queue first if already in it
    remove_from_ready_queue(process);
    
    process->next = NULL;
    process->prev = NULL;
    
    // If queue is empty
    if (!ready_queue_head) {
        ready_queue_head = process;
        return;
    }
    
    // Insert based on priority (lower number = higher priority)
    process_t *current = ready_queue_head;
    process_t *prev = NULL;
    
    while (current && current->priority <= process->priority) {
        prev = current;
        current = current->next;
    }
    
    // Insert between prev and current
    process->next = current;
    process->prev = prev;
    
    if (prev) {
        prev->next = process;
    } else {
        ready_queue_head = process;
    }
    
    if (current) {
        current->prev = process;
    }
}

static void remove_from_ready_queue(process_t *process) {
    if (!process) {
        return;
    }
    
    if (process->prev) {
        process->prev->next = process->next;
    } else {
        ready_queue_head = process->next;
    }
    
    if (process->next) {
        process->next->prev = process->prev;
    }
    
    process->next = NULL;
    process->prev = NULL;
}

static process_t* get_next_ready_process(void) {
    return ready_queue_head;
}

static void init_process_context(process_t *process, process_func_t func) {
    // Clear the context
    memset(&process->context, 0, sizeof(cpu_context_t));
    
    // Set up stack pointer (top of allocated stack)
    process->context.sp = (u64)process->stack_base + process->stack_size;
    
    // Set up program counter to process function
    process->context.pc = (u64)func;
    
    // Set up processor state for EL1h with interrupts enabled
    process->context.pstate = 0x5;  // SPSR_EL1h
    
    // Set up link register to process exit handler
    process->context.x30 = (u64)process_exit_cleanup;
}

void enable_scheduler(void) {
    scheduler_enabled = true;
    printf("Process scheduler enabled\n");
}

void disable_scheduler(void) {
    scheduler_enabled = false;
    printf("Process scheduler disabled\n");
}