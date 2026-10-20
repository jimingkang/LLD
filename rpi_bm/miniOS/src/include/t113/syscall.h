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
#define T113_SYS_OPEN   8u
#define T113_SYS_READ   9u
#define T113_SYS_CLOSE  10u
#define T113_SYS_UPTIME 11u
#define T113_SYS_EXEC   12u
#define T113_SYS_SBRK   13u
#define T113_SYS_VFORK  14u
#define T113_SYS_READDIR 15u
#define T113_SYS_GETCWD  16u
#define T113_SYS_TFTP    17u
#define T113_SYS_NETCTL  18u
#define T113_SYS_DUP     19u

/* T113_SYS_NETCTL commands; arguments are user strings. */
#define NETCTL_STATUS    0u      /* print interface state */
#define NETCTL_DHCP      1u
#define NETCTL_PING      2u      /* a1 = address */
#define NETCTL_STATIC    3u      /* a1 = address, a2 = netmask, a3 = gateway */
#define NETCTL_WIFI      4u      /* (re)connect WiFi */

void t113_syscall_dispatch(struct arm32_trapframe *tf);

#endif
