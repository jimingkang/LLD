#ifndef SYSCALL_H
#define SYSCALL_H

#include <stdint.h>

// System call handler
void handle_syscall(uint64_t syscall_num, uint64_t arg1, uint64_t arg2, uint64_t arg3);

// User mode system call wrappers
void user_yield(void);
void user_exit(void);
void user_print(const char* msg);

#endif
