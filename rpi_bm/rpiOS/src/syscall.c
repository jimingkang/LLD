#include "process.h"
#include "hardware.h"

// System call numbers
#define SYS_YIELD  0
#define SYS_EXIT   1
#define SYS_PRINT  2

// Handle system calls from user mode
void handle_syscall(uint64_t syscall_num, uint64_t arg1, uint64_t arg2, uint64_t arg3) {
    switch (syscall_num) {
        case SYS_YIELD:
            syscall_yield();
            break;
            
        case SYS_EXIT:
            syscall_exit();
            break;
            
        case SYS_PRINT:
            syscall_print((const char*)arg1);
            break;
            
        default:
            uart_puts("Unknown system call: ");
            uart_put_number(syscall_num);
            uart_puts("\n");
            break;
    }
}

// User mode system call wrappers (to be called from user processes)
void user_yield(void) {
    asm volatile("mov x8, #0; svc #0" ::: "x8");
}

void user_exit(void) {
    asm volatile("mov x8, #1; svc #0" ::: "x8");
}

void user_print(const char* msg) {
    asm volatile("mov x8, #2; mov x0, %0; svc #0" :: "r"(msg) : "x8", "x0");
}
