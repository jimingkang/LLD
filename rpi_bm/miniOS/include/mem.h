#pragma once

#include "common.h"

void *memcpy(void *dest, const void *src, u32 n);

#define GPU_CACHED_BASE		0x40000000
#define GPU_UNCACHED_BASE	0xC0000000
#define GPU_MEM_BASE	GPU_UNCACHED_BASE

#define BUS_ADDRESS(addr)	(((addr) & ~0xC0000000) | GPU_MEM_BASE)


typedef unsigned long pteval_t;

typedef struct { pteval_t pte; } pte_t;
typedef struct { pteval_t pmd; } pmd_t;
typedef struct { pteval_t pud; } pud_t;
typedef struct { pteval_t pgd; } pgd_t;
#define pte_val(x)      ((x).pte)
#define pmd_val(x)      ((x).pmd)
#define pud_val(x)      ((x).pud)
#define pgd_val(x)      ((x).pgd)
#define __pte(x)        ((pte_t) { (x) })
#define __pmd(x)        ((pmd_t) { (x) })
#define __pud(x)        ((pud_t) { (x) })
#define __pgd(x)        ((pgd_t) { (x) })


#define __pa(x) ((u64)(x) - KERNEL_VIRT_OFFSET)
#define __va(x) ((u64)(x) + KERNEL_VIRT_OFFSET)

#define TD_VALID            (1 << 0)
#define TD_TABLE            (1 << 1)
#define TD_ACCESS           (1 << 10)
#define TD_KERNEL_PERMS     (1L << 54)
#define TD_INNER_SHARABLE   (3 << 8)

#define TD_KERNEL_TABLE_FLAGS (TD_TABLE | TD_VALID)

// Page table entry attributes for ARMv8-A
#define PTE_TYPE_PAGE   (1UL << 1)   // Final-level descriptor (PTE)
#define PTE_TYPE_TABLE  (1UL << 1)   // Non-final, points to next-level table
#define PTE_TYPE_BLOCK  (0UL << 1)   // Block entry (used in PMD/PUD)
#define PTE_VALID          (1UL << 0)
#define PTE_TABLE          (1UL << 1)  // This is what you're missing
#define PTE_BLOCK          (0UL << 1)
#define PTE_PAGE           (1UL << 1)
#define PTE_AF             (1UL << 10)
#define PTE_NG             (1UL << 11)
#define PTE_USER           (1UL << 6)  // User-accessible
#define PTE_RDONLY         (1UL << 7)  // Read-only
#define PTE_WRITE      (1UL << 55)   // Writable (if not RDONLY)
#define PTE_SHARED         (3UL << 8)  // Inner shareable
#define PTE_UXN        (1UL << 54)   // User Execute Never
#define PTE_ATTRINDX(x)    ((x) << 2)  // Normal memory

#define PTE_SH_NONE   (0UL << 8)
#define PTE_SH_OUTER  (2UL << 8)
#define PTE_SH_INNER  (3UL << 8)   // 你要的这个

#define PTE_RW           (1 << 7)    // AP[2] = 0 (可写)
#define PTE_USER_RW_FLAGS (PTE_VALID | PTE_AF | PTE_SH_INNER | PTE_ATTRINDX(1) | PTE_USER | PTE_RW)
//#define PTE_USER_RW_FLAGS  (PTE_VALID | PTE_AF | PTE_SH_INNER | PTE_ATTRINDX(1) | (1 << 6)) 

#define KERNEL_EXEC_FLAGS  (PTE_VALID | PTE_AF | PTE_SH_INNER | PTE_ATTRINDX(1))


#define USER_STACK_TOP   0x4000000UL   // 顶部（SP 指向此） 原来是0x40000000太大,因为现在是identity映射
#define USER_STACK_SIZE  0x1000         // 一页大小（4KB）
#define USER_STACK_BASE  (USER_STACK_TOP - USER_STACK_SIZE)

// 定义页表层级（ARM64使用4级页表）
typedef enum {
    LEVEL_PGD = 0,  // Page Global Directory (L0)
    LEVEL_PUD = 1,  // Page Upper Directory (L1)
    LEVEL_PMD = 2,  // Page Middle Directory (L2)
    LEVEL_PTE = 3   // Page Table Entry (L3)
} PageTableLevel;
// MAIR_EL1 属性索引（需与初始化代码一致）
#define ATTR_S1_IDX_DEVICE  0  // 设备内存（nGnRnE）
#define ATTR_S1_IDX_NORMAL  1  // 普通内存（Write-Back）
 typedef unsigned long size_t;  // 64位

/* 代码段 */
extern char KERNEL_CODE_START[];
extern char KERNEL_CODE_END[];
/* 数据段 */
extern char KERNEL_DATA_START[];  // 添加数据段声明
extern char KERNEL_DATA_END[];
/* 物理地址（若在链接脚本中定义） */
//extern uintptr_t PHYS_CODE_START;
//extern uintptr_t PHYS_DATA_START;
#define PHYS_CODE_START 0x80000
#define PHYS_DATA_START 0x90000


 extern char KERNEL_BSS_START[];
extern char KERNEL_BSS_END[];

extern char __text_start[];
extern char __text_end[];



void *get_free_pages(int num_pages);
void *allocate_memory(int bytes);
void free_memory(void *base);
unsigned long allocate_kernel_page(); 
uint64_t *get_next_table(uint64_t *current_table, uint64_t vaddr, PageTableLevel level);



