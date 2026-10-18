#include "platform.h"
#include "sched.h"
#include "syscall.h"
#include "user_vm.h"
#include "fs/vfs.h"

#define SYSCALL_WRITE_LIMIT 256u
#define SYSCALL_PATH_LIMIT  128u
#define EXEC_IMAGE_PAGES    16u
#define EXEC_MAX_ARGS       16u
#define EXEC_ARG_BYTES      256u

static int copy_user_string(char *destination, uint32_t address,
                            uint32_t capacity)
{
    if (!address || capacity == 0)
        return -1;
    for (uint32_t i = 0; i < capacity; ++i) {
        if (!t113_user_vm_range_mapped(t113_current->mm, address + i, 1))
            return -1;
        destination[i] = *(const char *)(uintptr_t)(address + i);
        if (destination[i] == '\0')
            return 0;
    }
    destination[capacity - 1u] = '\0';
    return -1;
}

static int32_t sys_open(uint32_t user_path, uint32_t flags)
{
    if (flags != 0)
        return -1;
    char path[SYSCALL_PATH_LIMIT];
    if (copy_user_string(path, user_path, sizeof(path)) < 0)
        return -1;
    struct vfs_file *file = t113_vfs_open(path, flags);
    if (!file)
        return -1;
    for (uint32_t i = 0; i < T113_MAX_FDS; ++i) {
        if (t113_current->files[i])
            continue;
        t113_current->files[i] = file;
        return (int32_t)(i + 3u);
    }
    t113_vfs_close(file);
    return -1;
}

static int32_t sys_read(uint32_t fd, uint32_t address, uint32_t count)
{
    if (fd < 3u || fd >= 3u + T113_MAX_FDS)
        return -1;
    uint32_t slot = fd - 3u;
    if (!t113_current->files[slot] ||
        !t113_user_vm_range_writable(t113_current->mm, address, count))
        return -1;
    return t113_vfs_read(t113_current->files[slot],
                         (void *)(uintptr_t)address, count);
}

static int32_t sys_close(uint32_t fd)
{
    if (fd < 3u || fd >= 3u + T113_MAX_FDS ||
        !t113_current->files[fd - 3u])
        return -1;
    t113_vfs_close(t113_current->files[fd - 3u]);
    t113_current->files[fd - 3u] = 0;
    return 0;
}

static int copy_exec_args(uint32_t user_argv, char args[EXEC_ARG_BYTES],
                          uint32_t offsets[EXEC_MAX_ARGS], uint32_t *argc,
                          uint32_t *bytes)
{
    *argc = 0;
    *bytes = 0;
    if (!user_argv)
        return 0;

    for (uint32_t i = 0; i < EXEC_MAX_ARGS; ++i) {
        uint32_t slot = user_argv + i * sizeof(uint32_t);
        uint32_t argument;
        if (!t113_user_vm_range_mapped(t113_current->mm, slot,
                                       sizeof(argument)))
            return -1;
        argument = *(const uint32_t *)(uintptr_t)slot;
        if (!argument)
            return 0;
        offsets[i] = *bytes;
        if (copy_user_string(args + *bytes, argument,
                             EXEC_ARG_BYTES - *bytes) < 0)
            return -1;
        while (args[*bytes] != '\0')
            ++*bytes;
        ++*bytes;
        ++*argc;
    }
    return -1; /* argv must be NULL terminated. */
}

static int build_exec_stack(struct t113_user_vm *vm,
                            const char args[EXEC_ARG_BYTES],
                            const uint32_t offsets[EXEC_MAX_ARGS],
                            uint32_t argc, uint32_t bytes,
                            uint32_t *user_sp, uint32_t *user_argv)
{
    uint32_t strings = (USER_STACK_TOP - bytes) & ~3u;
    uint32_t vector_bytes = (argc + 1u) * sizeof(uint32_t);
    uint32_t argv = (strings - vector_bytes) & ~7u;
    uint32_t sp = (argv - sizeof(uint32_t)) & ~7u;
    uint32_t pointers[EXEC_MAX_ARGS + 1u];

    if (sp < USER_STACK_VA)
        return -1;
    for (uint32_t i = 0; i < argc; ++i)
        pointers[i] = strings + offsets[i];
    pointers[argc] = 0;
    if (t113_user_vm_copyout(vm, strings, args, bytes) < 0 ||
        t113_user_vm_copyout(vm, argv, pointers, vector_bytes) < 0 ||
        t113_user_vm_copyout(vm, sp, &argc, sizeof(argc)) < 0)
        return -1;
    *user_sp = sp;
    *user_argv = argv;
    return 0;
}

static int32_t sys_exec(uint32_t user_path, uint32_t user_argv,
                        struct arm32_trapframe *tf)
{
    char path[SYSCALL_PATH_LIMIT];
    char args[EXEC_ARG_BYTES];
    uint32_t offsets[EXEC_MAX_ARGS];
    uint32_t argc, arg_bytes;
    if (copy_user_string(path, user_path, sizeof(path)) < 0)
        return -1;
    if (copy_exec_args(user_argv, args, offsets, &argc, &arg_bytes) < 0)
        return -1;
    struct vfs_file *file = t113_vfs_open(path, VFS_O_RDONLY);
    if (!file || t113_vfs_file_size(file) > EXEC_IMAGE_PAGES * 4096u) {
        t113_vfs_close(file);
        return -1;
    }
    void *image = t113_alloc_pages(EXEC_IMAGE_PAGES, 1);
    if (!image)
    {
        t113_vfs_close(file);
        return -1;
    }
    int size = t113_vfs_read(file, image, t113_vfs_file_size(file));
    t113_vfs_close(file);
    uint32_t entry = 0;
    struct t113_user_vm *vm = size < 0 ? 0 :
        t113_user_vm_create_elf(image, (uint32_t)size, &entry);
    t113_free_pages(image, EXEC_IMAGE_PAGES);
    if (!vm)
        return -1;

    uint32_t user_sp, new_argv;
    if (build_exec_stack(vm, args, offsets, argc, arg_bytes,
                         &user_sp, &new_argv) < 0)
        return -1;
    t113_current->mm = vm;
    for (uint32_t i = 0; i < 13; ++i)
        tf->r[i] = 0;
    tf->r[0] = argc;
    tf->r[1] = new_argv;
    tf->user_sp = user_sp;
    tf->user_lr = 0;
    tf->pc = entry;
    tf->cpsr = 0x10u;
    t113_vfork_complete(t113_current);
    t113_switch_user_vm(vm);
    return 0;
}

static int user_range_ok(uint32_t address, uint32_t length)
{
    if (length > SYSCALL_WRITE_LIMIT || address + length < address)
        return 0;

    return t113_user_vm_range_mapped(t113_current->mm, address, length);
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
    case T113_SYS_FORK:
        result = t113_fork_user(tf);
        break;
    case T113_SYS_VFORK:
        result = t113_vfork_user(tf);
        break;
    case T113_SYS_SLEEP:
        t113_sleep_seconds(tf->r[0]);
        result = 0;
        break;
    case T113_SYS_WAIT:
        if (tf->r[0] != 0 &&
            !t113_user_vm_range_writable(t113_current->mm, tf->r[0],
                                         sizeof(int32_t)))
            result = -1;
        else
            result = t113_wait_child((int32_t *)(uintptr_t)tf->r[0]);
        break;
    case T113_SYS_EXIT:
        t113_exit_current((int32_t)tf->r[0]);
        __builtin_unreachable();
    case T113_SYS_OPEN:
        result = sys_open(tf->r[0], tf->r[1]);
        break;
    case T113_SYS_READ:
        result = sys_read(tf->r[0], tf->r[1], tf->r[2]);
        break;
    case T113_SYS_CLOSE:
        result = sys_close(tf->r[0]);
        break;
    case T113_SYS_UPTIME:
        result = (int32_t)t113_timer_ticks();
        break;
    case T113_SYS_EXEC:
        result = sys_exec(tf->r[0], tf->r[1], tf);
        if (result == 0)
            return; /* Preserve argc/argv installed in the new trapframe. */
        break;
    case T113_SYS_SBRK:
        result = t113_user_vm_sbrk(t113_current->mm, (int32_t)tf->r[0]);
        break;
    default:
        result = -38; /* -ENOSYS */
        break;
    }

    tf->r[0] = (uint32_t)result;
}
