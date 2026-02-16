#include "process.h"
#include "hardware.h"
#include <stddef.h>
 process_t processes[MAX_PROCESSES];
 process_t* current_process = NULL;
 process_t* ready_queue = NULL;
 int next_pid = 1;
 uint64_t process_stacks[MAX_PROCESSES][STACK_SIZE / 8] __attribute__((aligned(16)));
 uint64_t user_stacks[MAX_PROCESSES][STACK_SIZE / 8] __attribute__((aligned(16)));

void process_init(void) {
    // Initialize all processes as terminated
    for (int i = 0; i < MAX_PROCESSES; i++) {
        processes[i].pid = 0;
        processes[i].state = PROCESS_TERMINATED;
        processes[i].next = NULL;
    }
    
    current_process = NULL;
    ready_queue = NULL;
    next_pid = 1;
    
    uart_puts("User process management initialized\n");
}

// Find free process slot
static process_t* allocate_process(void) {
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].state == PROCESS_TERMINATED) {
            return &processes[i];
        }
    }
    return NULL;
}

// Add process to ready queue
static void add_to_ready_queue(process_t* proc) {
    proc->next = NULL;
    
    if (ready_queue == NULL) {
        ready_queue = proc;
        return;
    }
    
    // Insert by priority (higher priority first)
    if (proc->priority > ready_queue->priority) {
        proc->next = ready_queue;
        ready_queue = proc;
        return;
    }
    
    process_t* current = ready_queue;
    while (current->next && current->next->priority >= proc->priority) {
        current = current->next;
    }
    
    proc->next = current->next;
    current->next = proc;
}

// Remove process from ready queue
static process_t* remove_from_ready_queue(void) {
    if (ready_queue == NULL) {
        return NULL;
    }
    
    process_t* proc = ready_queue;
    ready_queue = ready_queue->next;
    proc->next = NULL;
    return proc;
}

// Initialize process stack and context
static void setup_process_stack(process_t* proc, process_func_t func) {
    // Calculate kernel stack top (stacks grow downward)
    int slot = proc - processes;
    uint64_t kernel_stack_top = (uint64_t)&process_stacks[slot][STACK_SIZE / 8];
    uint64_t user_stack_top = (uint64_t)&user_stacks[slot][STACK_SIZE / 8];
    
    proc->stack_base = kernel_stack_top;
    proc->user_stack_base = user_stack_top;
    
    // Initialize CPU context for user mode
    // Clear all general purpose registers
    proc->cpu_context.x0 = proc->cpu_context.x1 = 0;
    proc->cpu_context.x2 = proc->cpu_context.x3 = 0;
    proc->cpu_context.x4 = proc->cpu_context.x5 = 0;
    proc->cpu_context.x6 = proc->cpu_context.x7 = 0;
    proc->cpu_context.x8 = proc->cpu_context.x9 = 0;
    proc->cpu_context.x10 = proc->cpu_context.x11 = 0;
    proc->cpu_context.x12 = proc->cpu_context.x13 = 0;
    proc->cpu_context.x14 = proc->cpu_context.x15 = 0;
    proc->cpu_context.x16 = proc->cpu_context.x17 = 0;
    proc->cpu_context.x18 = proc->cpu_context.x19 = 0;
    proc->cpu_context.x20 = proc->cpu_context.x21 = 0;
    proc->cpu_context.x22 = proc->cpu_context.x23 = 0;
    proc->cpu_context.x24 = proc->cpu_context.x25 = 0;
    proc->cpu_context.x26 = proc->cpu_context.x27 = 0;
    proc->cpu_context.x28 = proc->cpu_context.fp = 0;
    proc->cpu_context.lr = 0;
    
    // Set kernel stack pointer
    proc->cpu_context.sp = kernel_stack_top;
    
    // Set user mode execution context
    proc->cpu_context.elr_el1 = (uint64_t)func;  // User function entry point
    proc->cpu_context.sp_el0 = user_stack_top;   // User stack pointer
    
    // Set SPSR for user mode (EL0) with interrupts enabled
    proc->cpu_context.spsr_el1 = 0x0;  // EL0t, interrupts enabled
}

int process_create(const char* name, process_func_t func, int priority) {
    process_t* proc = allocate_process();
    if (proc == NULL) {
        uart_puts("Error: No free process slots\n");
        return -1;
    }
    
    // Initialize process
    proc->pid = next_pid++;
    strncpy(proc->name, name, PROCESS_NAME_LEN - 1);
    proc->name[PROCESS_NAME_LEN - 1] = '\0';
    proc->state = PROCESS_READY;
    proc->priority = priority;
    proc->runtime = 0;
    
    // Setup stack and context
    setup_process_stack(proc, func);
    
    // Add to ready queue
    add_to_ready_queue(proc);
    
    uart_puts("Created process: ");
    uart_puts(proc->name);
    uart_puts(" (PID: ");
    uart_put_number(proc->pid);
    uart_puts(")\n");
    
    return proc->pid;
}

void process_schedule(void) {
    process_t* next_process = remove_from_ready_queue();
    
    if (next_process == NULL) {
        // No processes to run, return to kernel
        current_process = NULL;
        return;
    }
    
    process_t* prev_process = current_process;
    
    // If there's a current process, save it back to ready queue
    if (current_process && current_process->state == PROCESS_RUNNING) {
        current_process->state = PROCESS_READY;
        add_to_ready_queue(current_process);
    }
    
    // Switch to next process
    current_process = next_process;
    current_process->state = PROCESS_RUNNING;
    
    uart_puts("Switching to user process: ");
    uart_puts(current_process->name);
    uart_puts("\n");
    
    // Switch to user mode
    switch_to_user(&current_process->cpu_context);
}

void process_yield(void) {
    if (current_process) {
        current_process->state = PROCESS_READY;
        process_schedule();
    }
}

void process_exit(void) {
    if (current_process) {
        uart_puts("Process ");
        uart_puts(current_process->name);
        uart_puts(" exiting\n");
        
        current_process->state = PROCESS_TERMINATED;
        current_process = NULL;
        process_schedule();
    }
}

process_t* get_current_process(void) {
    return current_process;
}

void print_process_list(void) {
    uart_puts("\n=== Process List ===\n");
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].state != PROCESS_TERMINATED) {
            uart_puts("PID: ");
            uart_put_number(processes[i].pid);
            uart_puts(", Name: ");
            uart_puts(processes[i].name);
            uart_puts(", State: ");
            
            switch (processes[i].state) {
                case PROCESS_READY: uart_puts("READY"); break;
                case PROCESS_RUNNING: uart_puts("RUNNING"); break;
                case PROCESS_BLOCKED: uart_puts("BLOCKED"); break;
                default: uart_puts("UNKNOWN"); break;
            }
            
            uart_puts(", Priority: ");
            uart_put_number(processes[i].priority);
            uart_puts("\n");
        }
    }
    uart_puts("==================\n\n");
}

// Helper function for string copy
 void strncpy(char* dest, const char* src, int n) {
    int i;
    for (i = 0; i < n - 1 && src[i] != '\0'; i++) {
        dest[i] = src[i];
    }
    dest[i] = '\0';
}

void syscall_yield(void) {
    if (current_process) {
        current_process->state = PROCESS_READY;
        process_schedule();
    }
}

void syscall_exit(void) {
    if (current_process) {
        uart_puts("User process ");
        uart_puts(current_process->name);
        uart_puts(" exiting\n");
        
        current_process->state = PROCESS_TERMINATED;
        current_process = NULL;
        process_schedule();
    }
}

void syscall_print(const char* msg) {
    uart_puts("[USER] ");
    uart_puts(msg);
}
