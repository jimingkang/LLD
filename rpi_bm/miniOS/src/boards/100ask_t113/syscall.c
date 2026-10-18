#include "platform.h"
#include "sched.h"
#include "syscall.h"
#include "user_vm.h"

#define SYSCALL_WRITE_LIMIT 256u

static int user_range_ok(uint32_t address, uint32_t length)
{
    if (length > SYSCALL_WRITE_LIMIT || address + length < address)
        return 0;

    if (address >= USER_CODE_VA &&
        address + length <= USER_CODE_VA + 0x1000u)
        return 1;
    if (address >= USER_STACK_VA &&
        address + length <= USER_STACK_TOP)
        return 1;
    return 0;
}

static int32_t sys_write(uint32_t address, uint32_t length)
{
    if (!user_range_ok(address, length))
        return -1;

    const char *text = (const char *)(uintptr_t)address;
    for (uint32_t i = 0; i < length; ++i)
        t113_uart_putc(text[i]);
    return (int32_t)length;
}

void t113_syscall_dispatch(struct arm32_trapframe *tf)
{
    uint32_t number = tf->r[7];
    int32_t result;

    switch (number) {
    case T113_SYS_WRITE:
        result = sys_write(tf->r[0], tf->r[1]);
        break;
    case T113_SYS_GETPID:
        result = (int32_t)t113_current->pid;
        break;
    case T113_SYS_YIELD:
        result = 0;
        tf->r[0] = (uint32_t)result;
        t113_sched_yield();
        return;
    default:
        result = -38; /* -ENOSYS */
        break;
    }

    tf->r[0] = (uint32_t)result;
}
