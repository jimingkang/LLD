#include "fork.h"
#include "printf.h"
#include "utils.h"
#include "sched.h"
#include "mm.h"
#include "mem.h"
#include <mmu.h>
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

void handle_user_page_fault(u64 addr, u64 esr) {
    // 1. 检查地址是否属于用户栈区域
    if (addr >= USER_STACK_TOP - USER_STACK_SIZE && addr < USER_STACK_TOP) {
        u64 phys_page = get_free_pages(1);
        if (!phys_page) printf("Out of memory");
        
        // 2. 映射到用户页表（使用进程的 pgd）
        map_user_page(current->pgd, addr & PAGE_MASK, phys_page, PTE_USER_RW_FLAGS);
        
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