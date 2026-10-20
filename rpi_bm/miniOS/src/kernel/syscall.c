#include "platform.h"
#include "sched.h"
#include "syscall.h"
#include "user_vm.h"
#include "fs/vfs.h"
#include "fs/minifs.h"
#include "exception.h"

#define SYSCALL_WRITE_LIMIT 256u
#define SYSCALL_PATH_LIMIT  128u
#define EXEC_IMAGE_PAGES    16u
#define EXEC_MAX_ARGS       16u
#define EXEC_ARG_BYTES      256u
/* 1: print a checkpoint on every successful exec, just before the return
 * to User mode (see exec_checkpoint). */
#ifndef EXEC_TRACE
#define EXEC_TRACE          0
#endif

/* Character-at-a-time console tracing is useful while bringing UART RX up,
 * but it serialises several dozen bytes at 115200 baud for every key press.
 * Keep it available without making the normal interactive shell sluggish. */
#ifndef STDIN_TRACE
#define STDIN_TRACE         0
#endif

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
    if (flags != VFS_O_RDONLY && flags != VFS_O_RDWR)
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
    if (fd == 0u) {
        if (!count || !t113_user_vm_range_writable(t113_current->mm,
                                                    address, count)) {
            t113_uart_puts("read: invalid stdin buffer pid=");
            t113_uart_puthex(t113_current->pid);
            t113_uart_puts(" address=");
            t113_uart_puthex(address);
            t113_uart_puts(" count=");
            t113_uart_puthex(count);
            t113_uart_putc('\n');
            return -1;
        }
        char *buffer = (char *)(uintptr_t)address;
#if STDIN_TRACE
        static int stdin_wait_reported;
        if (!stdin_wait_reported) {
            stdin_wait_reported = 1;
            t113_uart_puts("stdin: waiting, LSR=");
            t113_uart_puthex(t113_uart_lsr());
            t113_uart_puts(" USR=");
            t113_uart_puthex(t113_uart_usr());
            t113_uart_putc('\n');
        }
        uint64_t heartbeat = t113_time_us() + 3000000u;
#endif
        int received = t113_uart_read(buffer, count);
#if STDIN_TRACE
        (void)heartbeat;
        t113_uart_puts("stdin: received=");
        t113_uart_puthex((uint32_t)received);
        t113_uart_putc('\n');
#endif
        return received;
    }
    if (fd < 3u || fd >= 3u + T113_MAX_FDS)
        return -1;
    uint32_t slot = fd - 3u;
    if (!t113_current->files[slot] ||
        !t113_user_vm_range_writable(t113_current->mm, address, count))
        return -1;
    return t113_vfs_read(t113_current->files[slot],
                         (void *)(uintptr_t)address, count);
}

static int32_t sys_readdir(uint32_t user_path, uint32_t index,
                           uint32_t user_result)
{
    char path[SYSCALL_PATH_LIMIT];
    struct vfs_dirent entry;
    if (copy_user_string(path, user_path, sizeof(path)) < 0 ||
        !t113_user_vm_range_writable(t113_current->mm, user_result,
                                     sizeof(entry)))
        return -1;
    int result = t113_vfs_readdir(path, index, &entry);
    if (result > 0) {
        struct t113_minifs_user_dirent user_entry;
        user_entry.inum = entry.id;
        user_entry.type = entry.type;
        user_entry.size = entry.size;
        for (uint32_t i = 0; i < sizeof(user_entry.name); ++i)
            user_entry.name[i] = entry.name[i];
        *(struct t113_minifs_user_dirent *)(uintptr_t)user_result = user_entry;
    }
    return result;
}

static int32_t sys_getcwd(uint32_t address, uint32_t size)
{
    if (size < 2u || !t113_user_vm_range_writable(t113_current->mm,
                                                   address, 2u))
        return -1;
    char *buffer = (char *)(uintptr_t)address;
    buffer[0] = '/';
    buffer[1] = 0;
    return (int32_t)address;
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

#if EXEC_TRACE
static void exec_putdec(uint32_t v)
{
    char b[11];
    int i = 10;
    b[i] = '\0';
    do {
        b[--i] = (char)('0' + v % 10u);
        v /= 10u;
    } while (v && i);
    t113_uart_puts(b + i);
}

static void exec_check_va(const struct t113_user_vm *vm, const char *what,
                          uint32_t va, int write)
{
    uint32_t l1, l2;
    t113_user_vm_descriptors(vm, va, &l1, &l2);
    t113_uart_puts("exec:   ");
    t113_uart_puts(what);
    t113_uart_putc(' ');
    t113_uart_puthex(va);
    t113_uart_puts(" L1=");
    t113_uart_puthex(l1);
    t113_uart_puts(" L2=");
    t113_uart_puthex(l2);
    if (l2 & 2u) {
        uint32_t ap = (l2 >> 4) & 3u;
        t113_uart_puts(ap == 3u ? " user-RW" : ap == 2u ? " user-RO" : " no-user");
        t113_uart_puts(l2 & 1u ? " XN" : " X");
    }
    t113_uart_puts(" hw:");
    t113_mmu_probe_print(t113_mmu_probe(va, 1, write));
    t113_uart_putc('\n');
}

/*
 * Last stop before arm32_return_to_user: the new address space is live in
 * TTBR0, so check through the real MMU that the entry point and the user
 * stack are reachable from User mode, and show the first instructions and
 * the argc/argv words the new image will see.
 */
static void exec_checkpoint(const char *path, const struct t113_user_vm *vm,
                            const struct arm32_trapframe *tf)
{
    t113_uart_puts("exec: checkpoint ");
    t113_uart_puts(path);
    t113_uart_puts(" pid=");
    exec_putdec(t113_current->pid);
    t113_uart_puts(" entry=");
    t113_uart_puthex(tf->pc);
    t113_uart_puts(" sp=");
    t113_uart_puthex(tf->user_sp);
    t113_uart_puts(" cpsr=");
    t113_uart_puthex(tf->cpsr);
    t113_uart_puts(" argc=");
    exec_putdec(tf->r[0]);
    t113_uart_puts(" argv=");
    t113_uart_puthex(tf->r[1]);
    t113_uart_puts("\nexec:   TTBR0=");
    t113_uart_puthex(t113_mmu_ttbr0());
    t113_uart_puts(" vm-L1=");
    t113_uart_puthex((uint32_t)(uintptr_t)vm->l1);
    t113_uart_puts(" pages=");
    exec_putdec(vm->page_count);
    t113_uart_puts(" brk=");
    t113_uart_puthex(vm->brk);
    t113_uart_putc('\n');

    exec_check_va(vm, "entry", tf->pc, 0);
    exec_check_va(vm, "sp   ", tf->user_sp, 1);

    if (tf->pc & 3u)
        t113_uart_puts("exec:   WARNING entry not word aligned (Thumb entry with ARM cpsr?)\n");
    if (tf->user_sp & 7u)
        t113_uart_puts("exec:   WARNING user sp not 8-byte aligned\n");
    if ((tf->cpsr & 0x1fu) != 0x10u || (tf->cpsr & 0xc0u))
        t113_uart_puts("exec:   WARNING cpsr is not User mode with IRQ/FIQ enabled\n");

    if (!(t113_mmu_probe(tf->pc, 1, 0) & 1u)) {
        const volatile uint32_t *insn =
            (const volatile uint32_t *)(uintptr_t)(tf->pc & ~3u);
        t113_uart_puts("exec:   insn:");
        for (uint32_t i = 0; i < 4u; ++i) {
            if (t113_mmu_probe((uint32_t)(uintptr_t)&insn[i], 1, 0) & 1u)
                break;
            t113_uart_putc(' ');
            t113_uart_puthex(insn[i]);
        }
        t113_uart_putc('\n');
    }
    if (!(t113_mmu_probe(tf->user_sp, 1, 0) & 1u)) {
        const volatile uint32_t *sp =
            (const volatile uint32_t *)(uintptr_t)tf->user_sp;
        t113_uart_puts("exec:   stack: argc=");
        exec_putdec(sp[0]);
        if (tf->r[1] && !(t113_mmu_probe(tf->r[1], 1, 0) & 1u)) {
            const volatile uint32_t *argv =
                (const volatile uint32_t *)(uintptr_t)tf->r[1];
            t113_uart_puts(" argv[0]=");
            t113_uart_puthex(argv[0]);
            if (argv[0] && !(t113_mmu_probe(argv[0], 1, 0) & 1u)) {
                t113_uart_puts(" \"");
                const volatile char *a = (const volatile char *)(uintptr_t)argv[0];
                for (uint32_t i = 0; i < 32u && a[i]; ++i)
                    t113_uart_putc(a[i]);
                t113_uart_putc('"');
            }
        }
        t113_uart_putc('\n');
    }
    t113_uart_puts("exec: return to user\n");
}
#endif

static int32_t sys_exec(uint32_t user_path, uint32_t user_argv,
                        struct arm32_trapframe *tf)
{
    char path[SYSCALL_PATH_LIMIT];
    char args[EXEC_ARG_BYTES];
    uint32_t offsets[EXEC_MAX_ARGS];
    uint32_t argc, arg_bytes;
    if (copy_user_string(path, user_path, sizeof(path)) < 0) {
        t113_uart_puts("exec: invalid user path\n");
        return -1;
    }
    if (copy_exec_args(user_argv, args, offsets, &argc, &arg_bytes) < 0) {
        t113_uart_puts("exec: invalid argv for ");
        t113_uart_puts(path);
        t113_uart_putc('\n');
        return -1;
    }
    struct vfs_file *file = t113_vfs_open(path, VFS_O_RDONLY);
    if (!file || t113_vfs_file_size(file) > EXEC_IMAGE_PAGES * 4096u) {
        t113_uart_puts(file ? "exec: image too large: " : "exec: not found: ");
        t113_uart_puts(path);
        t113_uart_putc('\n');
        t113_vfs_close(file);
        return -1;
    }
    void *image = t113_alloc_pages(EXEC_IMAGE_PAGES, 1);
    if (!image) {
        t113_uart_puts("exec: no memory for image: ");
        t113_uart_puts(path);
        t113_uart_putc('\n');
        t113_vfs_close(file);
        return -1;
    }
    int size = t113_vfs_read(file, image, t113_vfs_file_size(file));
    t113_vfs_close(file);
    uint32_t entry = 0;
    struct t113_user_vm *vm = size < 0 ? 0 :
        t113_user_vm_create_elf(image, (uint32_t)size, &entry);
    t113_free_pages(image, EXEC_IMAGE_PAGES);
    if (!vm) {
        t113_uart_puts("exec: invalid ELF or no VM memory: ");
        t113_uart_puts(path);
        t113_uart_putc('\n');
        return -1;
    }

    uint32_t user_sp, new_argv;
    if (build_exec_stack(vm, args, offsets, argc, arg_bytes,
                         &user_sp, &new_argv) < 0) {
        t113_uart_puts("exec: cannot build user stack: ");
        t113_uart_puts(path);
        t113_uart_putc('\n');
        t113_user_vm_put(vm);
        return -1;
    }
    struct t113_user_vm *old_vm = t113_current->mm;
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
#if EXEC_TRACE
    exec_checkpoint(path, vm, tf);
#endif
    t113_user_vm_put(old_vm);
    return 0;
}

static int user_range_ok(uint32_t address, uint32_t length)
{
    if (length > SYSCALL_WRITE_LIMIT || address + length < address)
        return 0;

    return t113_user_vm_range_mapped(t113_current->mm, address, length);
}

static int32_t sys_write(uint32_t fd, uint32_t address, uint32_t length)
{
    if (!user_range_ok(address, length))
        return -1;

    const char *text = (const char *)(uintptr_t)address;
    if (fd == 1u || fd == 2u) {
        for (uint32_t i = 0; i < length; ++i)
            t113_uart_putc(text[i]);
        return (int32_t)length;
    }
    if (fd < 3u || fd >= 3u + T113_MAX_FDS ||
        !t113_current->files[fd - 3u])
        return -1;
    return t113_vfs_write(t113_current->files[fd - 3u], text, length);
}

void t113_syscall_dispatch(struct arm32_trapframe *tf)
{
    uint32_t number = tf->r[7];
    int32_t result;

    switch (number) {
    case T113_SYS_WRITE:
        result = sys_write(tf->r[0], tf->r[1], tf->r[2]);
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
    case T113_SYS_READDIR:
        result = sys_readdir(tf->r[0], tf->r[1], tf->r[2]);
        break;
    case T113_SYS_GETCWD:
        result = sys_getcwd(tf->r[0], tf->r[1]);
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
