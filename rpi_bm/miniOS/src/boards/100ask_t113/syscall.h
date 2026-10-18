#ifndef MINIOS_100ASK_T113_SYSCALL_H
#define MINIOS_100ASK_T113_SYSCALL_H

#include "sched.h"

#define T113_SYS_WRITE  1u
#define T113_SYS_GETPID 2u
#define T113_SYS_YIELD  3u
#define T113_SYS_FORK   4u
#define T113_SYS_SLEEP  5u
#define T113_SYS_WAIT   6u
#define T113_SYS_EXIT   7u

void t113_syscall_dispatch(struct arm32_trapframe *tf);

#endif
