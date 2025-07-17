#pragma once
#define PAGE_SHIFT 12
#define TABLE_SHIFT 9
#define PGDIR_SHIFT     39      // 使用 4 级页表时的 PGD 位移量
#define SECTION_SHIFT (PAGE_SHIFT + TABLE_SHIFT)
#define PAGE_SIZE (1 << PAGE_SHIFT)
#define SECTION_SIZE (1 << SECTION_SHIFT)
//#define PGDIR_SIZE      (_AC(1, UL) << PGDIR_SHIFT)  // 512GB
#define PGDIR_SIZE      ((unsigned long)(1) << PGDIR_SHIFT)
#define PGDIR_MASK      (~(PGDIR_SIZE - 1))

#define LOW_MEMORY     (4*2 * SECTION_SIZE) //(4*2 * SECTION_SIZE)=4*4MB (0x00400000)  //#define LOW_MEMORY 0x40000 //jimmy chang to 0x80000

#define HIGH_MEMORY             	0x40000000
#define PAGING_MEMORY 			(HIGH_MEMORY - LOW_MEMORY)
#define PAGING_PAGES 			(PAGING_MEMORY/PAGE_SIZE)

#define BLOCK_SIZE 0x40000000

#define KERNEL_VIRT_BASE 0xFFFFFF8000000000UL
#define KERNEL_PHYS_BASE 0x80000UL
#define KERNEL_VIRT_OFFSET  (0xFFFFFF8000000000UL - 0x80000UL)
#define __pa(x) ((u64)(x) - KERNEL_VIRT_OFFSET)
#define __va(x) ((u64)(x) + KERNEL_VIRT_OFFSET)
#define VA_START 			KERNEL_VIRT_OFFSET
#define ENTRIES_PER_TABLE 512



#define PAGE_MASK  (~(PAGE_SIZE - 1))
#ifndef __ASSEMBLER__

void memzero(unsigned long src, unsigned long n);
//void memcpy(unsigned long dst, unsigned long src, unsigned long n);
//user vir mem

#define PTRS_PER_PGD      512  // PGD 条目总数
#define VA_BITS           48   // 虚拟地址位数
// 内核空间起始索引（高位地址）
#define KERNEL_PGD_INDEX  (PTRS_PER_PGD / 2)  // 通常为 256

#define PHYS_MEMORY_SIZE 		0x40000000	

#define PTRS_PER_TABLE			(1 << TABLE_SHIFT)

#define PGD_SHIFT			PAGE_SHIFT + 3*TABLE_SHIFT
#define PUD_SHIFT			PAGE_SHIFT + 2*TABLE_SHIFT
#define PMD_SHIFT			PAGE_SHIFT + TABLE_SHIFT

#define PG_DIR_SIZE			(3 * PAGE_SIZE)


unsigned long get_free_page();
void free_page(unsigned long p);


#endif
// copy from rythm16
#define PAGE_MASK  0xfffffffffffff000
#define PAGE_SHIFT 12
#define TABLE_SHIFT 9
#define SECTION_SHIFT (PAGE_SHIFT + TABLE_SHIFT)
#define PAGE_SIZE (1 << PAGE_SHIFT)
#define SECTION_SIZE (1 << SECTION_SHIFT)

//#define LOW_MEMORY (2* SECTION_SIZE)

#define ID_MAP_PAGES           3
#define HIGH_MAP_PAGES         6
#define ID_MAP_TABLE_SIZE      (3 * (1<<12))
#define HIGH_MAP_TABLE_SIZE    (6 *  (1<<12))
#define ENTRIES_PER_TABLE      512
#define PGD_SHIFT              (PAGE_SHIFT + 3 * TABLE_SHIFT)
#define PUD_SHIFT              (PAGE_SHIFT + 2 * TABLE_SHIFT)
#define PMD_SHIFT              (PAGE_SHIFT + TABLE_SHIFT)
#define PUD_ENTRY_MAP_SIZE     (1 << PUD_SHIFT)
#define ID_MAP_SIZE            (8 * (1<<21))

#define HIGH_MAP_FIRST_START   (0x0 + LINEAR_MAP_BASE)
#define HIGH_MAP_FIRST_END     (0x3B400000 + LINEAR_MAP_BASE)
#define HIGH_MAP_SECOND_START  (0x40000000 + LINEAR_MAP_BASE)
#define HIGH_MAP_SECOND_END    (0x80000000 + LINEAR_MAP_BASE)
#define HIGH_MAP_THIRD_START   (0x80000000 + LINEAR_MAP_BASE)
#define HIGH_MAP_THIRD_END     (0xC0000000 + LINEAR_MAP_BASE)
#define HIGH_MAP_FOURTH_START  (0xC0000000 + LINEAR_MAP_BASE)
#define HIGH_MAP_FOURTH_END    (0xFC000000 + LINEAR_MAP_BASE)
#define HIGH_MAP_DEVICE_START  (0xFC000000 + LINEAR_MAP_BASE)
#define HIGH_MAP_DEVICE_END    (0x100000000 + LINEAR_MAP_BASE)

#define FIRST_START   (0x0)
#define FIRST_END     (0x3B400000)
#define SECOND_START  (0x40000000)
#define SECOND_END    (0x80000000)
#define THIRD_START   (0x80000000)
#define THIRD_END     (0xC0000000)
#define FOURTH_START  (0xC0000000)
#define FOURTH_END    (0xFC000000)
#define DEVICE_START  (0xFC000000)
#define DEVICE_END    (0x100000000)


#define LINEAR_MAP_BASE KERNEL_VIRT_OFFSET
#define PA_TO_KVA(pa)   ((pa) + LINEAR_MAP_BASE)
#define KVA_TO_PA(kva)  ((kva) - LINEAR_MAP_BASE)

#define SCTLR_EL1_RESERVED           (3 << 28) | (3 << 22) | (1 << 20) | (1 << 11)
#define SCTLR_EL1_EE_LITTLE_ENDIAN   (0 << 25)
#define SCTLR_EL1_EOE_LITTLE_ENDIAN  (0 << 24)
#define SCTLR_EL1_I_CACHE_DISABLED   (0 << 12)
#define SCTLR_EL1_D_CACHE_DISABLED   (0 << 2)
#define SCTLR_EL1_MMU_DISABLED       (0 << 0)
#define SCTLR_EL1_MMU_ENABLED        (1 << 0)


