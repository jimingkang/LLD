#include "process.h"
#include "mem.h"
#include "printf.h"
#include "timer.h"
#include "irq.h"
#include <string.h>

// Global process management state
static process_t processes[MAX_PROCESSES];
static process_t *ready_queue_head = NULL;
static process_t *ready_queue_tail = NULL;
static process_t *current_process = NULL;
static u32 next_pid = 1;
static bool process_system_initialized = false;

// Forward declarations for internal functions
static process_t *allocate_process_slot(void);
static void free_process_slot(process_t *proc);
static void add_to_ready_queue(process_t *proc);
static void remove_from_ready_queue(process_t *proc);

/**
 * Initialize the process management system
 */
void process_init(void) {
    // Initialize all process slots
    for (int i = 0; i < MAX_PROCESSES; i++) {
        processes[i].pid = 0;  // 0 indicates free slot
        processes[i].state = PROCESS_STATE_TERMINATED;
        processes[i].next = NULL;
    }
    
    ready_queue_head = NULL;
    ready_queue_tail = NULL;
    current_process = NULL;
    next_pid = 1;
    process_system_initialized = true;
    
    printf("Process management system initialized\n");
}

/**
 * Create a new kernel process
 */
process_t *process_create(const char *name, void (*entry_point)(void), u32 priority) {
    if (!process_system_initialized) {
        printf("Error: Process system not initialized\n");
        return NULL;
    }
    
    if (entry_point == NULL) {
        printf("Error: Invalid entry point\n");
        return NULL;
    }
    
    // Allocate a process slot
    process_t *proc = allocate_process_slot();
    if (proc == NULL) {
        printf("Error: No available process slots\n");
        return NULL;
    }
    
    // Allocate stack for the process
    void *stack = get_free_pages(PROCESS_STACK_SIZE / PAGE_SIZE);
    if (stack == NULL) {
        printf("Error: Cannot allocate stack for process\n");
        free_process_slot(proc);
        return NULL;
    }
    
    // Initialize process structure
    proc->pid = next_pid++;
    proc->state = PROCESS_STATE_READY;
    proc->stack_base = stack;
    proc->stack_size = PROCESS_STACK_SIZE;
    proc->entry_point = entry_point;
    proc->priority = priority;
    proc->next = NULL;
    
    // Copy process name
    if (name != NULL) {
        strncpy(proc->name, name, sizeof(proc->name) - 1);
        proc->name[sizeof(proc->name) - 1] = '\0';
    } else {
        snprintf(proc->name, sizeof(proc->name), "proc_%u", proc->pid);
    }
    
    // Initialize context for new process
    memset(&proc->context, 0, sizeof(process_context_t));
    
    // Set up initial stack pointer (stack grows downward)
    proc->context.sp = (u64)stack + PROCESS_STACK_SIZE - 16;
    
    // Set up program counter to entry point
    proc->context.pc = (u64)entry_point;
    
    // Set up processor state (SPSR_EL1h with interrupts enabled)
    proc->context.pstate = 0x00000005;  // EL1h mode
    
    printf("Created process '%s' (PID: %u) at 0x%p\n", proc->name, proc->pid, entry_point);
    
    return proc;
}

/**
 * Start a process (add it to the ready queue)
 */
void process_start(process_t *proc) {
    if (proc == NULL || proc->state != PROCESS_STATE_READY) {
        printf("Error: Invalid process or wrong state\n");
        return;
    }
    
    add_to_ready_queue(proc);
    printf("Started process '%s' (PID: %u)\n", proc->name, proc->pid);
}

/**
 * Destroy a process and free its resources
 */
void process_destroy(process_t *proc) {
    if (proc == NULL) {
        return;
    }
    
    printf("Destroying process '%s' (PID: %u)\n", proc->name, proc->pid);
    
    // Remove from ready queue if present
    if (proc->state == PROCESS_STATE_READY) {
        remove_from_ready_queue(proc);
    }
    
    // Free stack memory
    if (proc->stack_base != NULL) {
        free_memory(proc->stack_base);
    }
    
    // Mark process slot as free
    proc->state = PROCESS_STATE_TERMINATED;
    proc->pid = 0;
}

/**
 * Get the currently running process
 */
process_t *process_get_current(void) {
    return current_process;
}

/**
 * Get process by PID
 */
process_t *process_get_by_pid(u32 pid) {
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].pid == pid) {
            return &processes[i];
        }
    }
    return NULL;
}

/**
 * List all active processes
 */
void process_list_all(void) {
    printf("Active Processes:\n");
    printf("PID\tName\t\tState\t\tPriority\n");
    printf("---\t----\t\t-----\t\t--------\n");
    
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].pid != 0) {
            const char *state_str;
            switch (processes[i].state) {
                case PROCESS_STATE_READY: state_str = "READY"; break;
                case PROCESS_STATE_RUNNING: state_str = "RUNNING"; break;
                case PROCESS_STATE_BLOCKED: state_str = "BLOCKED"; break;
                case PROCESS_STATE_TERMINATED: state_str = "TERMINATED"; break;
                default: state_str = "UNKNOWN"; break;
            }
            
            printf("%u\t%-15s\t%-10s\t%u\n", 
                   processes[i].pid, 
                   processes[i].name, 
                   state_str, 
                   processes[i].priority);
        }
    }
}

/**
 * Simple round-robin scheduler
 */
void scheduler_tick(void) {
    if (ready_queue_head == NULL) {
        return;  // No processes to schedule
    }
    
    // Simple round-robin: move current process to end and get next
    if (current_process != NULL && current_process->state == PROCESS_STATE_RUNNING) {
        current_process->state = PROCESS_STATE_READY;
        // Move to end of queue
        remove_from_ready_queue(current_process);
        add_to_ready_queue(current_process);
    }
    
    // Get next process
    process_t *next_proc = scheduler_get_next();
    if (next_proc != NULL) {
        next_proc->state = PROCESS_STATE_RUNNING;
        current_process = next_proc;
        remove_from_ready_queue(next_proc);
    }
}

/**
 * Get the next process to run
 */
process_t *scheduler_get_next(void) {
    return ready_queue_head;
}

/**
 * Block a process
 */
void process_block(process_t *proc) {
    if (proc == NULL) return;
    
    proc->state = PROCESS_STATE_BLOCKED;
    remove_from_ready_queue(proc);
    
    if (current_process == proc) {
        current_process = NULL;
        scheduler_tick();  // Schedule next process
    }
}

/**
 * Unblock a process
 */
void process_unblock(process_t *proc) {
    if (proc == NULL || proc->state != PROCESS_STATE_BLOCKED) return;
    
    proc->state = PROCESS_STATE_READY;
    add_to_ready_queue(proc);
}

// Internal helper functions

static process_t *allocate_process_slot(void) {
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].pid == 0) {  // Free slot
            return &processes[i];
        }
    }
    return NULL;
}

static void free_process_slot(process_t *proc) {
    if (proc != NULL) {
        proc->pid = 0;
        proc->state = PROCESS_STATE_TERMINATED;
    }
}

static void add_to_ready_queue(process_t *proc) {
    if (proc == NULL) return;
    
    proc->next = NULL;
    
    if (ready_queue_head == NULL) {
        ready_queue_head = ready_queue_tail = proc;
    } else {
        ready_queue_tail->next = proc;
        ready_queue_tail = proc;
    }
}

static void remove_from_ready_queue(process_t *proc) {
    if (proc == NULL || ready_queue_head == NULL) return;
    
    if (ready_queue_head == proc) {
        ready_queue_head = proc->next;
        if (ready_queue_tail == proc) {
            ready_queue_tail = NULL;
        }
    } else {
        process_t *current = ready_queue_head;
        while (current->next != NULL && current->next != proc) {
            current = current->next;
        }
        
        if (current->next == proc) {
            current->next = proc->next;
            if (ready_queue_tail == proc) {
                ready_queue_tail = current;
            }
        }
    }
    
    proc->next = NULL;
}

// Example kernel processes for testing

void kernel_idle_process(void) {
    printf("Idle process started\n");
    while (1) {
        // Simple idle loop
        for (volatile int i = 0; i < 1000000; i++);
        printf("Idle process tick\n");
    }
}

void kernel_test_process_1(void) {
    printf("Test process 1 started\n");
    for (int i = 0; i < 10; i++) {
        printf("Test process 1: iteration %d\n", i);
        timer_sleep(500);  // Sleep for 500ms
    }
    printf("Test process 1 finished\n");
}

void kernel_test_process_2(void) {
    printf("Test process 2 started\n");
    for (int i = 0; i < 5; i++) {
        printf("Test process 2: iteration %d\n", i);
        timer_sleep(1000);  // Sleep for 1000ms
    }
    printf("Test process 2 finished\n");
}