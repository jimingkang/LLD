#pragma once

#define PAGE_SHIFT 12
#define TABLE_SHIFT 9
#define SECTION_SHIFT (PAGE_SHIFT + TABLE_SHIFT)
#define PAGE_SIZE (1 << PAGE_SHIFT)
#define SECTION_SIZE (1 << SECTION_SHIFT)

#define LOW_MEMORY     (4*2 * SECTION_SIZE) //(4*2 * SECTION_SIZE)=4*4MB (0x00400000)  //#define LOW_MEMORY 0x40000 //jimmy chang to 0x80000

#define HIGH_MEMORY             	0x40000000
#define PAGING_MEMORY 			(HIGH_MEMORY - LOW_MEMORY)
#define PAGING_PAGES 			(PAGING_MEMORY/PAGE_SIZE)

#define BLOCK_SIZE 0x40000000
//#define KERNEL_VIRT_OFFSET 0xFFFF000000000000UL  // 高地址映射
#define KERNEL_VIRT_OFFSET 0x0UL
#define ENTRIES_PER_TABLE 512

#define __pa(x)    ((u64)(x) - KERNEL_VIRT_OFFSET)  // 假设你内核高映射


#define PAGE_MASK  (~(PAGE_SIZE - 1))
#ifndef __ASSEMBLER__

void memzero(unsigned long src, unsigned int n);


#endif
