#ifndef MINIOS_100ASK_T113_SYSCALL_H
#define MINIOS_100ASK_T113_SYSCALL_H

#include "sched.h"

#define T113_SYS_WRITE  1u
#define T113_SYS_GETPID 2u
#define T113_SYS_YIELD  3u

void t113_syscall_dispatch(struct arm32_trapframe *tf);

#endif
