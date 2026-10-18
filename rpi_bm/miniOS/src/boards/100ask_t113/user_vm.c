#include "platform.h"

#define USER_CODE_VA  0x00100000u
#define USER_STACK_VA 0x008ff000u

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

struct user_address_space {
    uint32_t *l1;
    uint32_t *code_l2;
    uint32_t *stack_l2;
    void *code_page;
    void *stack_page;
};

static struct user_address_space demo_vm;
extern uint32_t __kernel_l1_table[];

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

static uint32_t walk_user_pa(const struct user_address_space *vm, uint32_t va)
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

void t113_user_vm_demo_init(void)
{
    /* A short-descriptor L1 table is 16 KiB and must be 16 KiB aligned. */
    demo_vm.l1 = (uint32_t *)t113_alloc_pages(4, 4);
    demo_vm.code_l2 = (uint32_t *)t113_alloc_page();
    demo_vm.stack_l2 = (uint32_t *)t113_alloc_page();
    demo_vm.code_page = t113_alloc_page();
    demo_vm.stack_page = t113_alloc_page();

    if (!demo_vm.l1 || !demo_vm.code_l2 || !demo_vm.stack_l2 ||
        !demo_vm.code_page || !demo_vm.stack_page) {
        t113_uart_puts("PANIC: user address-space allocation failed\n");
        for (;;)
            __asm__ volatile("wfi");
    }

    /* Each process receives the privileged 1:1 kernel map.  Domain 0 is
     * Client, so AP bits prevent User mode from touching those sections. */
    for (uint32_t i = 0; i < 4096; ++i)
        demo_vm.l1[i] = __kernel_l1_table[i];

    install_l2(demo_vm.l1, USER_CODE_VA, demo_vm.code_l2);
    install_l2(demo_vm.l1, USER_STACK_VA, demo_vm.stack_l2);
    map_user_page(demo_vm.code_l2, USER_CODE_VA, demo_vm.code_page, 0, 1);
    map_user_page(demo_vm.stack_l2, USER_STACK_VA, demo_vm.stack_page, 1, 0);

    t113_uart_puts("user vm: L1=");
    t113_uart_puthex((uint32_t)(uintptr_t)demo_vm.l1);
    t113_uart_puts(" code VA=");
    t113_uart_puthex(USER_CODE_VA);
    t113_uart_puts("->PA=");
    t113_uart_puthex(walk_user_pa(&demo_vm, USER_CODE_VA));
    t113_uart_puts(" stack VA=");
    t113_uart_puthex(USER_STACK_VA);
    t113_uart_puts("->PA=");
    t113_uart_puthex(walk_user_pa(&demo_vm, USER_STACK_VA));
    t113_uart_puts(" free-pages=");
    t113_uart_puthex(t113_page_free_count());
    t113_uart_putc('\n');
}
