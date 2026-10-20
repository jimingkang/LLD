#include "platform.h"
#include "user_vm.h"

#ifndef ELF_LOAD_TRACE
#define ELF_LOAD_TRACE 0
#endif

#define PAGE_SIZE       4096u
#define PAGE_MASK       0xfffff000u
#define ELF_MAGIC       0x464c457fu
#define ELFCLASS32      1u
#define ELFDATA2LSB     1u
#define ET_EXEC         2u
#define EM_ARM          40u
#define PT_LOAD         1u
#define PF_X            1u
#define PF_W            2u

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

struct elf32_ehdr {
    uint8_t ident[16];
    uint16_t type, machine;
    uint32_t version, entry, phoff, shoff, flags;
    uint16_t ehsize, phentsize, phnum, shentsize, shnum, shstrndx;
};

struct elf32_phdr {
    uint32_t type, offset, vaddr, paddr;
    uint32_t filesz, memsz, flags, align;
};

extern uint32_t __kernel_l1_table[];

static void zero_bytes(void *address, uint32_t bytes)
{
    uint8_t *p = (uint8_t *)address;
    for (uint32_t i = 0; i < bytes; ++i)
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

static uint32_t *get_l2(struct t113_user_vm *vm, uint32_t va, int create)
{
    uint32_t index = va >> 20;
    for (uint32_t i = 0; i < vm->l2_count; ++i)
        if (vm->l2_index[i] == index)
            return vm->l2[i];
    if (!create || vm->l2_count >= T113_MAX_USER_L2)
        return 0;
    uint32_t *l2 = (uint32_t *)t113_alloc_page();
    if (!l2)
        return 0;
    zero_bytes(l2, PAGE_SIZE);
    vm->l2[vm->l2_count] = l2;
    vm->l2_index[vm->l2_count++] = index;
    vm->l1[index] = ((uint32_t)(uintptr_t)l2 & 0xfffffc00u) | L1_COARSE;
    return l2;
}

static struct t113_user_page *find_page(struct t113_user_vm *vm, uint32_t va)
{
    va &= PAGE_MASK;
    for (uint32_t i = 0; i < vm->page_count; ++i)
        if (vm->pages[i].va == va)
            return &vm->pages[i];
    return 0;
}

static struct t113_user_page *map_page(struct t113_user_vm *vm, uint32_t va,
                                       uint32_t writable, uint32_t executable)
{
    va &= PAGE_MASK;
    struct t113_user_page *page = find_page(vm, va);
    if (page) {
        page->writable |= writable;
        page->executable |= executable;
    } else {
        if (vm->page_count >= T113_MAX_USER_PAGES)
            return 0;
        page = &vm->pages[vm->page_count++];
        page->va = va;
        page->pa = t113_alloc_page();
        page->writable = writable;
        page->executable = executable;
        if (!page->pa)
            return 0;
        zero_bytes(page->pa, PAGE_SIZE);
    }
    uint32_t *l2 = get_l2(vm, va, 1);
    if (!l2)
        return 0;
    l2[(va >> 12) & 0xffu] =
        ((uint32_t)(uintptr_t)page->pa & PAGE_MASK) |
        l2_flags(page->writable, page->executable);
    return page;
}

static int copy_to_user(struct t113_user_vm *vm, uint32_t va,
                        const uint8_t *source, uint32_t bytes)
{
    while (bytes) {
        struct t113_user_page *page = find_page(vm, va);
        if (!page)
            return -1;
        uint32_t offset = va & (PAGE_SIZE - 1u);
        uint32_t chunk = PAGE_SIZE - offset;
        if (chunk > bytes)
            chunk = bytes;
        copy_bytes((uint8_t *)page->pa + offset, source, chunk);
        va += chunk;
        source += chunk;
        bytes -= chunk;
    }
    return 0;
}

static void sync_executable_pages(struct t113_user_vm *vm)
{
    for (uint32_t i = 0; i < vm->page_count; ++i) {
        if (!vm->pages[i].executable)
            continue;
        uint32_t start = (uint32_t)(uintptr_t)vm->pages[i].pa;
        for (uint32_t p = start; p < start + PAGE_SIZE; p += 32u)
            __asm__ volatile("mcr p15, 0, %0, c7, c14, 1"
                             : : "r"(p) : "memory");
    }
    __asm__ volatile(
        "dsb sy\n\t"
        "mov r0, #0\n\t"
        "mcr p15, 0, r0, c7, c5, 0\n\t"
        "dsb sy\n\t"
        "isb"
        : : : "r0", "memory");
}

static int elf_header_valid(const struct elf32_ehdr *elf, uint32_t size)
{
    if (size < sizeof(*elf))
        return 0;
    uint32_t magic;
    copy_bytes(&magic, elf->ident, sizeof(magic));
    if (magic != ELF_MAGIC ||
        elf->ident[4] != ELFCLASS32 || elf->ident[5] != ELFDATA2LSB ||
        elf->type != ET_EXEC || elf->machine != EM_ARM ||
        elf->phentsize != sizeof(struct elf32_phdr))
        return 0;
    if (elf->phoff > size ||
        (uint32_t)elf->phnum * sizeof(struct elf32_phdr) > size - elf->phoff)
        return 0;
    return 1;
}

struct t113_user_vm *t113_user_vm_create_elf(const void *image,
                                             uint32_t image_size,
                                             uint32_t *entry)
{
    const uint8_t *bytes = (const uint8_t *)image;
    const struct elf32_ehdr *elf = (const struct elf32_ehdr *)image;
    if (!image || !entry ||
        !elf_header_valid(elf, image_size)) {
        t113_uart_puts("ELF: invalid ARM32 executable\n");
        return 0;
    }

    struct t113_user_vm *vm = (struct t113_user_vm *)t113_alloc_page();
    if (!vm)
        return 0;
    vm->references = 1u;
    vm->l1 = (uint32_t *)t113_alloc_pages(4, 4);
    if (!vm->l1)
        return 0;
    zero_bytes(vm->l1, 4u * PAGE_SIZE);
    for (uint32_t i = 0; i < 4096; ++i)
        vm->l1[i] = __kernel_l1_table[i];

    const struct elf32_phdr *program =
        (const struct elf32_phdr *)(bytes + elf->phoff);
    uint32_t loaded = 0;
    uint32_t image_end = USER_CODE_VA;
    for (uint32_t i = 0; i < elf->phnum; ++i, ++program) {
        if (program->type != PT_LOAD)
            continue;
        if (program->memsz == 0)
            continue;
        if (program->filesz > program->memsz ||
            program->offset > image_size ||
            program->filesz > image_size - program->offset ||
            program->vaddr + program->memsz < program->vaddr ||
            program->vaddr < USER_CODE_VA ||
            program->vaddr + program->memsz > USER_STACK_VA)
            return 0;

        uint32_t begin = program->vaddr & PAGE_MASK;
        uint32_t end = (program->vaddr + program->memsz + PAGE_SIZE - 1u) & PAGE_MASK;
        for (uint32_t va = begin; va < end; va += PAGE_SIZE)
            if (!map_page(vm, va, program->flags & PF_W,
                          program->flags & PF_X))
                return 0;
        if (copy_to_user(vm, program->vaddr, bytes + program->offset,
                         program->filesz) < 0)
            return 0;
        if (program->vaddr + program->memsz > image_end)
            image_end = program->vaddr + program->memsz;

#if ELF_LOAD_TRACE
        t113_uart_puts("ELF: PT_LOAD va=");
        t113_uart_puthex(program->vaddr);
        t113_uart_puts(" filesz=");
        t113_uart_puthex(program->filesz);
        t113_uart_puts(" memsz=");
        t113_uart_puthex(program->memsz);
        t113_uart_puts(" flags=");
        t113_uart_puthex(program->flags);
        t113_uart_putc('\n');
#endif
        ++loaded;
    }
    if (!loaded || !find_page(vm, elf->entry))
        return 0;
    if (!map_page(vm, USER_STACK_VA, 1, 0))
        return 0;
    vm->heap_base = (image_end + PAGE_SIZE - 1u) & PAGE_MASK;
    vm->brk = vm->heap_base;
    sync_executable_pages(vm);
    *entry = elf->entry;

#if ELF_LOAD_TRACE
    t113_uart_puts("ELF: entry=");
    t113_uart_puthex(*entry);
    t113_uart_puts(" pages=");
    t113_uart_puthex(vm->page_count);
    t113_uart_puts(" L1=");
    t113_uart_puthex((uint32_t)(uintptr_t)vm->l1);
    t113_uart_puts(" free-pages=");
    t113_uart_puthex(t113_page_free_count());
    t113_uart_putc('\n');
#endif
    return vm;
}

struct t113_user_vm *t113_user_vm_clone(const struct t113_user_vm *source)
{
    if (!source)
        return 0;

    struct t113_user_vm *vm = (struct t113_user_vm *)t113_alloc_page();
    if (!vm)
        return 0;
    vm->references = 1u;
    vm->l1 = (uint32_t *)t113_alloc_pages(4, 4);
    if (!vm->l1)
        return 0;
    zero_bytes(vm->l1, 4u * PAGE_SIZE);
    for (uint32_t i = 0; i < 4096; ++i)
        vm->l1[i] = __kernel_l1_table[i];

    for (uint32_t i = 0; i < source->page_count; ++i) {
        const struct t113_user_page *src = &source->pages[i];
        struct t113_user_page *dst = map_page(vm, src->va,
                                              src->writable,
                                              src->executable);
        if (!dst)
            return 0;
        copy_bytes(dst->pa, src->pa, PAGE_SIZE);
    }
    vm->heap_base = source->heap_base;
    vm->brk = source->brk;
    sync_executable_pages(vm);
    return vm;
}

void t113_user_vm_get(struct t113_user_vm *vm)
{
    if (vm)
        ++vm->references;
}

void t113_user_vm_put(struct t113_user_vm *vm)
{
    if (!vm || !vm->references || --vm->references)
        return;
    for (uint32_t i = 0; i < vm->page_count; ++i)
        if (vm->pages[i].pa)
            t113_free_pages(vm->pages[i].pa, 1);
    for (uint32_t i = 0; i < vm->l2_count; ++i)
        if (vm->l2[i])
            t113_free_pages(vm->l2[i], 1);
    if (vm->l1)
        t113_free_pages(vm->l1, 4);
    t113_free_pages(vm, 1);
}

int t113_user_vm_range_mapped(const struct t113_user_vm *vm,
                              uint32_t address, uint32_t length)
{
    if (!vm || address + length < address)
        return 0;
    if (length == 0)
        return 1;
    uint32_t page = address & PAGE_MASK;
    uint32_t last = (address + length - 1u) & PAGE_MASK;
    for (;;) {
        if (!find_page((struct t113_user_vm *)vm, page))
            return 0;
        if (page == last)
            return 1;
        page += PAGE_SIZE;
    }
}

int t113_user_vm_range_writable(const struct t113_user_vm *vm,
                                uint32_t address, uint32_t length)
{
    if (!vm || address + length < address)
        return 0;
    if (length == 0)
        return 1;
    uint32_t page = address & PAGE_MASK;
    uint32_t last = (address + length - 1u) & PAGE_MASK;
    for (;;) {
        struct t113_user_page *mapping =
            find_page((struct t113_user_vm *)vm, page);
        if (!mapping || !mapping->writable)
            return 0;
        if (page == last)
            return 1;
        page += PAGE_SIZE;
    }
}

void t113_user_vm_descriptors(const struct t113_user_vm *vm, uint32_t va,
                              uint32_t *l1, uint32_t *l2)
{
    *l1 = 0;
    *l2 = 0;
    if (!vm || !vm->l1)
        return;
    *l1 = vm->l1[va >> 20];
    if ((*l1 & 3u) != L1_COARSE)
        return;
    const uint32_t *table = (const uint32_t *)(uintptr_t)(*l1 & 0xfffffc00u);
    *l2 = table[(va >> 12) & 0xffu];
}

int t113_user_vm_copyout(struct t113_user_vm *vm, uint32_t address,
                         const void *source, uint32_t length)
{
    if ((!source && length) ||
        !t113_user_vm_range_writable(vm, address, length))
        return -1;
    return copy_to_user(vm, address, (const uint8_t *)source, length);
}

int32_t t113_user_vm_sbrk(struct t113_user_vm *vm, int32_t increment)
{
    if (!vm || increment < 0)
        return -1;
    uint32_t old = vm->brk;
    uint32_t next = old + (uint32_t)increment;
    if (next < old || next >= USER_STACK_VA)
        return -1;
    uint32_t page = (old + PAGE_SIZE - 1u) & PAGE_MASK;
    uint32_t end = (next + PAGE_SIZE - 1u) & PAGE_MASK;
    while (page < end) {
        if (!find_page(vm, page) && !map_page(vm, page, 1, 0))
            return -1;
        page += PAGE_SIZE;
    }
    vm->brk = next;
    return (int32_t)old;
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
