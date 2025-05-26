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

#define KERNEL_VIRT_OFFSET 0xFFFF000000000000UL  // 高地址映射
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
#define PTRS_PER_PTE 512

#define PTE_VALID  (1UL << 0) // 第0位为1表示页表项有效
#define pte_valid(pte)  ((pte_val(pte) & PTE_VALID) != 0)

#define PMD_TYPE_TABLE   (3UL << 0)  // 页中间目录项类型
#define PUD_TYPE_TABLE   (3UL << 0)  // 页上层目录项类型

#define PTE_RW           (1 << 7)    // AP[2] = 0 (可写)
#define PTE_USER_RW_FLAGS (PTE_VALID | PTE_AF | PTE_SH_INNER | PTE_ATTRINDX(1) | PTE_USER | PTE_RW)
//#define PTE_USER_RW_FLAGS  (PTE_VALID | PTE_AF | PTE_SH_INNER | PTE_ATTRINDX(1) | (1 << 6)) 

#define KERNEL_EXEC_FLAGS  (PTE_VALID | PTE_AF | PTE_SH_INNER | PTE_ATTRINDX(1))


#define USER_STACK_TOP   0x4000000UL   // 顶部（SP 指向此） 原来是0x40000000太大,因为现在是identity映射
#define USER_STACK_SIZE  0x1000         // 一页大小（4KB）
#define USER_STACK_BASE  (USER_STACK_TOP - USER_STACK_SIZE)

#define VMALLOC_START   0xffffffff00000000//  0xffff000000000000UL   // typical kernel virtual base

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





#define PMD_SHIFT        21          // AArch64: 2MB alignment
#define PTRS_PER_PMD     512         // AArch64: 512 entries per PMD
#define PAGE_MASK        (~(4096-1)) // 4KB pages

#define PGD_VALID (1UL << 0)  // Valid entry
#define PGD_TABLE (1UL << 1)  // Points to next level
#define pgd_present(pgd)     (pgd_val(pgd) & PGD_VALID)
#define pgd_none(pgd)        (!pgd_val(pgd))
#define PUD_VALID    (1 << 0)
#define pud_present(pud)  (pud_val(pud) & PUD_VALID)

#define GFP_KERNEL    0x01  // 普通优先级分配
#define GFP_ATOMIC    0x02  // 原子分配（不可睡眠）

#define PGD_TYPE_TABLE  0x3   // 指向下级页表的描述符
#define PGD_TYPE_SECT   0x1   // 1GB块映射描述符
#define PGD_TYPE_VALID  (1 << 0)  // 有效位
#define PGD_TYPE_MASK       0x0000000000000003
#define PGD_TABLE_BIT       (1 << 1)

#define PMD_SHIFT      21   // 1 << 21 = 2MB
#define PMD_INDEX_MASK 0x1FF
#define PMD_TYPE_MASK     (3UL << 0)

#define PAGE_SHIFT   12
#define PTE_SHIFT    PAGE_SHIFT
#define PTE_INDEX(addr) (((addr) >> PTE_SHIFT) & 0x1FF)
#define PGD_INDEX(addr) (((addr) >> PGD_SHIFT) & 0x1FF)
#define PMD_INDEX(addr) (((addr) >> PMD_SHIFT) & 0x1FF)
#define PUD_INDEX(addr) (((addr) >> PUD_SHIFT) & 0x1FF)

#define is_pmd_table(pmd)  (((pmd_val(pmd) & PMD_TYPE_MASK) == PMD_TYPE_TABLE))

#define pgd_page_vaddr(pgd)    ((unsigned long)__va(pgd_val(pgd) & PTE_ADDR_MASK))

#ifndef phys_addr_t
#define phys_addr_t unsigned long
#endif
/* ARM64 physical address mask (48-bit addressing) */
#ifndef PHYS_MASK
#define PHYS_MASK 0x0000ffffffffffffUL
#endif

//#define VA_START        0xFFFF000000000000  // 内核虚拟地址基址
#define KERNEL_SIZE     (1* 1024 * 1024)   // 内核映像大小
#define DEVICE_BASE     0x3F000000          // 外设物理基址（树莓派3）
#define DEVICE_END      (DEVICE_BASE + 0x01000000)


#define AP_RW_RW   (0b11 << 6)  // 内核和用户态可读写
#define AP_RW_RO   (0b10 << 6)  // 内核可读写，用户态只读
#define AP_RW_NA   (0b01 << 6)  // 仅内核可读写
#define AP_RW_NONE (0b00 << 6)  // 无访问权限
 extern char KERNEL_BSS_START[];
extern char KERNEL_BSS_END[];

extern char __text_start[];
extern char __text_end[];


void *get_free_pages(int num_pages);
void *allocate_memory(int bytes);
void free_memory(void *base);
unsigned long allocate_kernel_page(); 
uint64_t *get_next_table(uint64_t *current_table, uint64_t vaddr, PageTableLevel level);
void *pud_page_vaddr(pud_t pud);
void *pmd_page_vaddr(pmd_t pmd);
unsigned long pmd_index(unsigned long addr);
