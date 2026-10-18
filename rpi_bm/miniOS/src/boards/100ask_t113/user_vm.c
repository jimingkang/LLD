#include "platform.h"
#include "user_vm.h"

#define L1_COARSE       0x1u
#define L2_SMALL        0x2u
#define L2_XN           0x1u
#define L2_B            (1u << 2)
#define L2_C            (1u << 3)
#define L2_AP_USER_RO   (2u << 4)
#define L2_AP_USER_RW   (3u << 4)
#define L2_TEX_NORMAL   (1u << 6)
#define L2_SHARED       (1u << 10)
#define L2_NG           (1u << 11)

#define MAX_USER_VMS 4u

static struct t113_user_vm user_vms[MAX_USER_VMS];
static uint32_t user_vm_count;
extern uint32_t __kernel_l1_table[];

static void zero_words(void *address, uint32_t bytes)
{
    uint32_t *p = (uint32_t *)address;
    for (uint32_t i = 0; i < bytes / sizeof(uint32_t); ++i)
        p[i] = 0;
}

static void copy_bytes(void *destination, const void *source, uint32_t bytes)
{
    uint8_t *dst = (uint8_t *)destination;
    const uint8_t *src = (const uint8_t *)source;
    for (uint32_t i = 0; i < bytes; ++i)
        dst[i] = src[i];
}

static uint32_t l2_flags(uint32_t writable, uint32_t executable)
{
    uint32_t flags = L2_SMALL | L2_B | L2_C | L2_TEX_NORMAL |
                     L2_SHARED | L2_NG;
    flags |= writable ? L2_AP_USER_RW : L2_AP_USER_RO;
    if (!executable)
        flags |= L2_XN;
    return flags;
}

static void install_l2(uint32_t *l1, uint32_t va, uint32_t *l2)
{
    l1[va >> 20] = ((uint32_t)(uintptr_t)l2 & 0xfffffc00u) | L1_COARSE;
}

static void map_user_page(uint32_t *l2, uint32_t va, void *page,
                          uint32_t writable, uint32_t executable)
{
    l2[(va >> 12) & 0xffu] =
        ((uint32_t)(uintptr_t)page & 0xfffff000u) |
        l2_flags(writable, executable);
}

static uint32_t walk_user_pa(const struct t113_user_vm *vm, uint32_t va)
{
    uint32_t l1e = vm->l1[va >> 20];
    if ((l1e & 3u) != L1_COARSE)
        return 0;
    uint32_t *l2 = (uint32_t *)(uintptr_t)(l1e & 0xfffffc00u);
    uint32_t l2e = l2[(va >> 12) & 0xffu];
    if ((l2e & 2u) == 0)
        return 0;
    return (l2e & 0xfffff000u) | (va & 0xfffu);
}

static void sync_user_code(void *address, uint32_t size)
{
    uint32_t start = (uint32_t)(uintptr_t)address & ~31u;
    uint32_t end = ((uint32_t)(uintptr_t)address + size + 31u) & ~31u;
    for (uint32_t p = start; p < end; p += 32u)
        __asm__ volatile("mcr p15, 0, %0, c7, c14, 1" : : "r"(p) : "memory");
    __asm__ volatile(
        "dsb sy\n\t"
        "mov r0, #0\n\t"
        "mcr p15, 0, r0, c7, c5, 0\n\t"
        "dsb sy\n\t"
        "isb"
        : : : "r0", "memory");
}

struct t113_user_vm *t113_user_vm_create(const void *image,
                                         uint32_t image_size)
{
    if (!image || image_size == 0 || image_size > 4096u ||
        user_vm_count >= MAX_USER_VMS)
        return 0;

    struct t113_user_vm *vm = &user_vms[user_vm_count++];
    vm->l1 = (uint32_t *)t113_alloc_pages(4, 4);
    vm->code_l2 = (uint32_t *)t113_alloc_page();
    vm->stack_l2 = (uint32_t *)t113_alloc_page();
    vm->code_page = t113_alloc_page();
    vm->stack_page = t113_alloc_page();

    if (!vm->l1 || !vm->code_l2 || !vm->stack_l2 ||
        !vm->code_page || !vm->stack_page)
        return 0;

    zero_words(vm->l1, 0x4000u);
    zero_words(vm->code_l2, 0x1000u);
    zero_words(vm->stack_l2, 0x1000u);
    zero_words(vm->code_page, 0x1000u);
    zero_words(vm->stack_page, 0x1000u);

    /* Retain privileged kernel/MMIO sections; their AP bits deny User mode. */
    for (uint32_t i = 0; i < 4096; ++i)
        vm->l1[i] = __kernel_l1_table[i];

    install_l2(vm->l1, USER_CODE_VA, vm->code_l2);
    install_l2(vm->l1, USER_STACK_VA, vm->stack_l2);
    map_user_page(vm->code_l2, USER_CODE_VA, vm->code_page, 0, 1);
    map_user_page(vm->stack_l2, USER_STACK_VA, vm->stack_page, 1, 0);
    copy_bytes(vm->code_page, image, image_size);
    sync_user_code(vm->code_page, image_size);

    t113_uart_puts("user vm: L1=");
    t113_uart_puthex((uint32_t)(uintptr_t)vm->l1);
    t113_uart_puts(" code VA=");
    t113_uart_puthex(USER_CODE_VA);
    t113_uart_puts("->PA=");
    t113_uart_puthex(walk_user_pa(vm, USER_CODE_VA));
    t113_uart_puts(" stack VA=");
    t113_uart_puthex(USER_STACK_VA);
    t113_uart_puts("->PA=");
    t113_uart_puthex(walk_user_pa(vm, USER_STACK_VA));
    t113_uart_puts(" free-pages=");
    t113_uart_puthex(t113_page_free_count());
    t113_uart_putc('\n');
    return vm;
}

static void switch_ttbr0(uint32_t table)
{
    __asm__ volatile(
        "dsb sy\n\t"
        "mcr p15, 0, %0, c2, c0, 0\n\t"
        "mov r1, #0\n\t"
        "mcr p15, 0, r1, c8, c7, 0\n\t"
        "dsb sy\n\t"
        "isb"
        : : "r"(table) : "r1", "memory");
}

void t113_switch_user_vm(struct t113_user_vm *vm)
{
    if (vm)
        switch_ttbr0((uint32_t)(uintptr_t)vm->l1);
}

void t113_switch_kernel_vm(void)
{
    switch_ttbr0((uint32_t)(uintptr_t)__kernel_l1_table);
}
