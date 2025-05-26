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
#define KERNEL_VIRT_OFFSET 0xFFFF000000000000UL  // 高地址映射
//#define KERNEL_VIRT_OFFSET 0xFFFFFF8000000000UL
//#define KERNEL_VIRT_OFFSET 0x0UL
#define ENTRIES_PER_TABLE 512

#define __pa(x)    ((u64)(x) - KERNEL_VIRT_OFFSET)  // 假设你内核高映射


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
#define VA_START 			KERNEL_VIRT_OFFSET
#define PTRS_PER_TABLE			(1 << TABLE_SHIFT)

#define PGD_SHIFT			PAGE_SHIFT + 3*TABLE_SHIFT
#define PUD_SHIFT			PAGE_SHIFT + 2*TABLE_SHIFT
#define PMD_SHIFT			PAGE_SHIFT + TABLE_SHIFT

#define PG_DIR_SIZE			(3 * PAGE_SIZE)


unsigned long get_free_page();
void free_page(unsigned long p);


#endif
