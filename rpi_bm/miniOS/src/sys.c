#include "fork.h"
#include "printf.h"
#include "utils.h"
#include "sched.h"
#include "mm.h"
#include "mem.h"
#include <mmu.h>
#include "user.h"
void sys_write(char * buf){
	printf(buf);
}

int sys_clone(unsigned long stack){
	return copy_process(0, 0, 0, stack);
}

unsigned long sys_malloc(){
	unsigned long addr = get_free_pages(1);
	if (!addr) {
		return -1;
	}
	return addr;
}

void sys_exit(){
	exit_process();
}



void * const sys_call_table[] = {sys_write, sys_malloc, sys_clone, sys_exit};

void handle_data_abort(u64 addr, u64 esr) {
    u64 ec = esr >> 26;
    u64 iss = esr & 0x1FFFFFF; // Instruction Specific Syndrome

    if (ec == 0x24 || ec == 0x25) { // Data Abort
        if (iss & 0x40) { // 检查是否是权限错误（ISS[6]）
            printf("Permission fault at 0x%x", addr);
        } else {
            // 缺页异常：动态分配物理页并映射
            handle_user_page_fault(addr, esr);
        }
    }
}

void debug_pgd(pgd_t *pgd) {
    if (!pgd) {
        printf("Invalid PGD\n");
        return;
    }

    printf("\n----- Page Table Hierarchy Dump -----\n");
    printf("PGD Virtual: 0x%x, Physical: 0x%x\n", 
           (unsigned long)pgd, __pa(pgd));

    for (int i = 0; i < PTRS_PER_PGD; i++) {
        pgd_t pgd_entry = pgd[i];
        if (!pgd_present(pgd_entry)) 
            continue;

        printf("\nPGD[%d]: 0x%x\n", i, pgd_val(pgd_entry));
        
        pud_t *pud = pud_offset(&pgd_entry, i << PGDIR_SHIFT);
        printf("  PUD Virtual: 0x%x\n", (unsigned long)pud);

        for (int j = 0; j < PTRS_PER_PUD; j++) {
            if (!pud_present(pud[j])) 
                continue;

            printf("  PUD[%d]: 0x%x\n", j, pud_val(pud[j]));
            
            pmd_t *pmd = pmd_offset(&pud[j], j << PUDIR_SHIFT);
            for (int k = 0; k < PTRS_PER_PMD; k++) {
                if (!pmd_present(pmd[k])) 
                    continue;

                if (pmd_sect(pmd[k])) {  // 块映射（1GB/2MB）
                    printf("    PMD BLOCK[%d]: 0x%x\n", k, pmd_val(pmd[k]));
                    printf("      Mapped VA: 0x%x → PA: 0x%x\n",
                           (i << PGDIR_SHIFT) | (j << PUDIR_SHIFT) | (k << PMD_SHIFT),
                           pmd_val(pmd[k]) & PMD_SECT_MASK);
                } else {  // 页表映射（4KB）
                    pte_t *pte = pte_offset_map(&pmd[k], k << PMD_SHIFT);
                    for (int l = 0; l < PTRS_PER_PTE; l++) {
                        if (!pte_present(pte[l])) 
                            continue;

                        printf("    PTE[%d]: 0x%x\n", l, pte_val(pte[l]));
                        printf("      Mapped VA: 0x%x → PA: 0x%x, Flags: ",
                               (i << PGDIR_SHIFT) | (j << PUDIR_SHIFT) | 
                               (k << PMD_SHIFT) | (l << PAGE_SHIFT),
                               pte_val(pte[l]) & PAGE_MASK);
                        
                        // 解析PTE标志位
                        if (pte_val(pte[l]) & PTE_VALID) printf("VALID ");
                        if (pte_val(pte[l]) & PTE_USER) printf("USER ");
                        // ...其他标志位
                        printf("\n");
                    }
                }
            }
        }
    }
}

void do_page_fault(unsigned long addr, unsigned long esr) {
    printf("Page fault at 0x%x, ESR: 0x%x\n", addr, esr);
    printf("Fault context: PC=0x%x SP=0x%x\n", 
           get_elr_el1(), get_sp_el0());
    
    // 检查地址是否应用户空间
    if (addr < user_begin) {
        printf("Kernel accessed user address");
    }
   // debug_pgd(current->mm);
    // 打印当前页表项
   dump_pte(current->mm, addr);
}

void handle_user_page_fault(u64 addr, u64 esr) {
	do_page_fault(addr,esr);
    // 获取当前进程的页表
    pgd_t *pgd = current->mm->pgd;
    
    // 1. 检查地址合法性
    if (addr < user_begin || addr >= user_end) {
        printf("Invalid user address: 0x%x", addr);
    }

    // 2. 区分缺页类型
    u32 fault_type = esr & ESR_ELx_FSC_TYPE;
	
	unsigned long fault_page = addr & PAGE_MASK;
    
    // 3. 处理栈缺页
    if (fault_page >= USER_STACK_BASE - USER_STACK_SIZE && 
        fault_page < USER_STACK_BASE) {
        
        u64 phys_page = get_free_page();
        if (!phys_page) printf("OOM for stack");
        
        //map_page(pgd, addr & PAGE_MASK, phys_page, 
        //        PTE_USER | PTE_WRITE | PTE_UXN);
        
        //printf("Mapped stack page: VA=0x%x → PA=0x%x\n", 
        //       addr & PAGE_MASK, phys_page);
        goto success;
    }

    // 4. 处理代码段缺页（按需加载）
    if (addr >= USER_CODE_BASE && 
        addr < USER_CODE_BASE + PAGE_SIZE) {
        
        u64 phys_page = get_free_page();
        if (!phys_page) printf("OOM for code");
        
        // 从磁盘或内核拷贝代码到phys_page
       // load_user_code_page(phys_page, addr);
        
       // map_page(pgd, addr & PAGE_MASK, phys_page,
        //        PTE_USER | PTE_EXEC);
        
        printf("Mapped code page: VA=0x%x → PA=0x%x\n",
               addr & PAGE_MASK, phys_page);
        goto success;
    }

    // 5. 非法访问
    printf("Unhandled user page fault at 0x%x (ESR: 0x%x)", addr, esr);

success:
    flush_tlb_single(addr);
}
void flush_tlb_single(u64 va) {
    asm volatile(
        "dsb ishst\n"
        "tlbi vaae1is, %0\n"
        "dsb ish\n"
        "isb\n"
        : : "r" (va >> 12));
}
void old_handle_user_page_fault(u64 addr, u64 esr) {
    // 1. 检查地址是否属于用户栈区域
    if (addr >= USER_STACK_BASE - USER_STACK_SIZE && addr < USER_STACK_BASE) {
        u64 phys_page = get_free_pages(1);
        if (!phys_page) printf("Out of memory");
        
        // 2. 映射到用户页表（使用进程的 pgd）
       // map_user_page(current->pgd, addr & PAGE_MASK, phys_page, PTE_USER_RW_FLAGS);
        
        // 3. 刷新 TLB
        flush_tlb(addr);
        return;
    }
    printf("Invalid page fault at 0x%x", addr);
}
  void flush_tlb(u64 va) {
    asm volatile("tlbi vale1is, %0" : : "r" (va >> 12));  // 使指定 VA 的 TLB 条目失效
    asm volatile("dsb ish");  // 数据同步屏障，确保 TLB 操作完成
    asm volatile("isb");      // 指令同步屏障，确保后续指令看到更改
}

static int ind = 1;

int do_mem_abort(unsigned long addr, unsigned long esr) {
	unsigned long dfs = (esr & 0b111111);
	if ((dfs & 0b111100) == 0b100) {
		unsigned long page = get_free_page();
		if (page == 0) {
			return -1;
		}
		map_page(current, addr & PAGE_MASK, page);
		ind++;
		if (ind > 2){
			return -1;
		}
		return 0;
	}
	return -1;
}




