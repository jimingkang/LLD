#include "hardware.h"
#include "process.h" // Include process header for process related functions

static volatile unsigned int timer_ticks = 0;

extern void handle_syscall(uint64_t syscall_num, uint64_t arg1, uint64_t arg2, uint64_t arg3);

void irq_init(void) {
    // Disable all interrupts
    *IRQ_DISABLE_1 = 0xFFFFFFFF;
    *IRQ_DISABLE_2 = 0xFFFFFFFF;
    *IRQ_DISABLE_BASIC = 0xFFFFFFFF;
    
    // Enable timer interrupt (Timer 1)
    *IRQ_ENABLE_1 = (1 << 1);
    
    // Enable IRQs
    asm volatile("msr daifclr, #2");
}

void timer_init(void) {
    // Set timer 1 to fire in 1 second (1MHz timer)
    unsigned int current_time = *TIMER_CLO;
    *TIMER_C1 = current_time + 1000000; // 1 second
}

void handle_irq(void) {
    // Check if it's a timer interrupt
    if (*IRQ_PENDING_1 & (1 << 1)) {
        // Clear timer interrupt
        *TIMER_CS = (1 << 1);
        
        // Set next timer interrupt
        unsigned int current_time = *TIMER_CLO;
        *TIMER_C1 = current_time + 1000000; // Next second
        
        timer_ticks++;
        
        process_t* current = get_current_process();
        if (current) {
            save_user_context(&current->cpu_context);
            current->runtime++;
        }
        
        // Schedule next process every 10 ticks (10 seconds)
        if (timer_ticks % 10 == 0) {
            uart_puts("[KERNEL] Timer scheduling processes\n");
            process_schedule();
        }
        
        // Print tick message
        uart_puts("[KERNEL] Timer tick: ");
        uart_put_number(timer_ticks);
        if (current) {
            uart_puts(" [Process: ");
            uart_puts(current->name);
            uart_puts("]");
        }
        uart_puts("\n");
    }
}

void handle_sync_exception(uint64_t esr, uint64_t elr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x8) {
    // Extract exception class from ESR
    uint32_t ec = (esr >> 26) & 0x3F;
    
    if (ec == 0x15) { // SVC instruction from AArch64 state
        uart_puts("[KERNEL] System call received: ");
        uart_put_number(x8);
        uart_puts("\n");
        
        // Save current user context
        process_t* current = get_current_process();
        if (current) {
            save_user_context(&current->cpu_context);
        }
        
        // Handle the system call
        handle_syscall(x8, x0, x1, x2);
        
        // If process is still running, return to it
        if (current && current->state == PROCESS_RUNNING) {
            switch_to_user(&current->cpu_context);
        }
    } else {
        uart_puts("[KERNEL] Unhandled sync exception, ESR: ");
        uart_put_number(esr);
        uart_puts(", ELR: ");
        uart_put_number(elr);
        uart_puts("\n");
        
        // Terminate current process on unhandled exception
        process_t* current = get_current_process();
        if (current) {
            uart_puts("[KERNEL] Terminating process due to exception: ");
            uart_puts(current->name);
            uart_puts("\n");
            current->state = PROCESS_TERMINATED;
            process_schedule();
        }
    }
}

void handle_exception(void) {
    uart_puts("Exception occurred!\n");
    while (1) {
        // Halt on exception
    }
}

unsigned int get_timer_ticks(void) {
    return timer_ticks;
}
