#include "platform.h"

extern uint32_t __kernel_l1_table[];

#define L1_SECTION              0x2u
#define L1_SECTION_AP_PRIV_RW   (1u << 10)
#define L1_SECTION_TEX_NORMAL   (1u << 12)
#define L1_SECTION_CACHEABLE    (1u << 3)
#define L1_SECTION_BUFFERABLE   (1u << 2)
#define L1_SECTION_SHARED       (1u << 16)
#define L1_SECTION_XN           (1u << 4)

#define L1_NORMAL (L1_SECTION | L1_SECTION_AP_PRIV_RW | \
                   L1_SECTION_TEX_NORMAL | L1_SECTION_CACHEABLE | \
                   L1_SECTION_BUFFERABLE)
#define L1_DEVICE (L1_SECTION | L1_SECTION_AP_PRIV_RW | \
                   L1_SECTION_SHARED | L1_SECTION_XN | \
                   L1_SECTION_BUFFERABLE)

static void map_sections(uint32_t begin_mb, uint32_t end_mb, uint32_t flags)
{
    for (uint32_t mb = begin_mb; mb < end_mb; ++mb)
        __kernel_l1_table[mb] = (mb << 20) | flags;
}

void t113_mmu_init(void)
{
    uint32_t zero = 0;
    uint32_t ttbr0 = (uint32_t)(uintptr_t)__kernel_l1_table;
    uint32_t sctlr;

    for (uint32_t i = 0; i < 4096; ++i)
        __kernel_l1_table[i] = 0;

    /* SRAM/code and DRAM are Normal memory.  The SoC register aperture is
     * Device, shared, privileged RW and execute-never.  All mappings are 1:1. */
    map_sections(0x000u, 0x010u, L1_NORMAL);
    map_sections(0x010u, 0x400u, L1_DEVICE);
    map_sections(0x400u, 0xc00u, L1_NORMAL);

    __asm__ volatile(
        "dsb sy\n\t"
        "mcr p15, 0, %0, c8, c7, 0\n\t"  /* invalidate unified TLB */
        "mcr p15, 0, %0, c7, c5, 0\n\t"  /* invalidate I-cache */
        "mcr p15, 0, %0, c7, c5, 6\n\t"  /* invalidate branch predictor */
        "mcr p15, 0, %1, c2, c0, 0\n\t"  /* TTBR0 */
        "mcr p15, 0, %0, c2, c0, 2\n\t"  /* TTBCR: N=0, TTBR0 covers all */
        "mov r1, #1\n\t"
        "mcr p15, 0, r1, c3, c0, 0\n\t"  /* domain 0 client: enforce AP */
        "isb"
        :
        : "r"(zero), "r"(ttbr0)
        : "r1", "memory");

    __asm__ volatile("mrc p15, 0, %0, c1, c0, 0" : "=r"(sctlr));
    sctlr |= (1u << 23);  /* XP: ARMv7 extended section descriptors */
    sctlr &= ~(1u << 28); /* TRE=0: TEX/C/B use the direct encoding */
    sctlr &= ~(1u << 29); /* AFE=0: AP[0] remains an access permission bit */
    sctlr |= (1u << 0);   /* M: MMU */
    sctlr |= (1u << 12);  /* I: instruction cache */
    sctlr &= ~(1u << 2);  /* keep D-cache off until set/way maintenance exists */
    __asm__ volatile(
        "dsb sy\n\t"
        "mcr p15, 0, %0, c1, c0, 0\n\t"
        "isb"
        : : "r"(sctlr) : "memory");
}

uint32_t t113_mmu_is_enabled(void)
{
    uint32_t sctlr;
    __asm__ volatile("mrc p15, 0, %0, c1, c0, 0" : "=r"(sctlr));
    return sctlr;
}

uint32_t t113_mmu_ttbr0(void)
{
    uint32_t ttbr0;
    __asm__ volatile("mrc p15, 0, %0, c2, c0, 0" : "=r"(ttbr0));
    return ttbr0;
}

uint32_t t113_mmu_l1_entry(uint32_t va)
{
    return __kernel_l1_table[va >> 20];
}
