#include "hardware.h"

extern uint64_t __page_table_start;

// Translation table entries
#define MM_TYPE_PAGE_TABLE    0x3
#define MM_TYPE_PAGE          0x3
#define MM_TYPE_BLOCK         0x1

// Memory attributes
#define MM_ACCESS             (0x1 << 10)
#define MM_ACCESS_PERMISSION  (0x1 << 6) 
#define MM_MEMORY_ATTRIBUTES  ((0x0 << 2) | (0x0 << 4)) // Device memory
#define MM_NORMAL_MEMORY      ((0x1 << 2) | (0x1 << 4)) // Normal memory

void mmu_init(void) {
    uint64_t *page_table = &__page_table_start;
    
    // Clear page table
    for (int i = 0; i < 512; i++) {
        page_table[i] = 0;
    }
    
    // Map first 1GB as normal memory (SDRAM)
    // 0x00000000 - 0x3F000000 (504 * 2MB blocks)
    for (int i = 0; i < 504; i++) {
        page_table[i] = (uint64_t)(i * 0x200000) | 
                       MM_TYPE_BLOCK | 
                       MM_ACCESS | 
                       MM_NORMAL_MEMORY;
    }
    
    // Map peripherals (0x3F000000 - 0x40000000) as device memory
    page_table[504] = 0x3F000000UL | 
                     MM_TYPE_BLOCK | 
                     MM_ACCESS | 
                     MM_MEMORY_ATTRIBUTES;
    
    // Set up MAIR (Memory Attribute Indirection Register)
    uint64_t mair = 0;
    mair |= (0x00UL << (0 * 8)); // Attribute 0: Device memory
    mair |= (0xFFUL << (1 * 8)); // Attribute 1: Normal memory, cacheable
    asm volatile("msr mair_el1, %0" :: "r"(mair));
    
    // Set up TCR (Translation Control Register)
    uint64_t tcr = 0;
    tcr |= (25UL << 0);   // T0SZ: 39-bit address space
    tcr |= (1UL << 8);    // IRGN0: Inner cacheable
    tcr |= (1UL << 10);   // ORGN0: Outer cacheable  
    tcr |= (3UL << 12);   // SH0: Inner Shareable
    tcr |= (0UL << 14);   // TG0: 4KB granule
    tcr |= (25UL << 16);  // T1SZ: Disable TTBR1
    asm volatile("msr tcr_el1, %0" :: "r"(tcr));
    
    // Set translation table base
    asm volatile("msr ttbr0_el1, %0" :: "r"((uint64_t)page_table));
    asm volatile("msr ttbr1_el1, %0" :: "r"(0));
    
    // Invalidate TLB and caches
    asm volatile("tlbi vmalle1is");
    asm volatile("dsb sy");
    asm volatile("isb");
    
    // Enable MMU
    uint64_t sctlr;
    asm volatile("mrs %0, sctlr_el1" : "=r"(sctlr));
    sctlr |= (1 << 0);  // Enable MMU
    sctlr |= (1 << 2);  // Enable data cache
    sctlr |= (1 << 12); // Enable instruction cache
    asm volatile("msr sctlr_el1, %0" :: "r"(sctlr));
    asm volatile("isb");
}
