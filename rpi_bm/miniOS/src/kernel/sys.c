#include "utils.h"
#include "types.h"
#include "fork.h"
#include "mm.h"
#include "sched.h"
#include "sys.h"
#include "printf.h"
#include "fork.h"

void * sys_call_table[] = {sys_write, sys_fork, sys_exit};

void sys_write(char * buf)
{
  //  main_output(MU, buf);
}

int sys_fork(u64 stack)
{
 //   return copy_process(UTHREAD, 0, 0);
}

void sys_exit()
{
    exit_process();
}

void sys_call_table_relocate()
{
    for (int i = 0; i < NR_SYSCALLS; i++) {
        sys_call_table[i] = (void *)((u64)sys_call_table[i] + (u64)KERNEL_START);
    }
}



void do_page_fault(unsigned long addr, unsigned long esr) {

    struct pt_regs *regs= task_pt_regs(current);;
      printf("=== 🚨 Page Fault Exception ===\r\n");


    // 打印触发异常的指令地址（EL0 的 PC）
    printf("  ELR_EL1 (PC)      : 0x%x\r\n", regs->pc);

    // 打印用户 SP（EL0 栈）
    printf("  SP_EL0            : 0x%x\r\n", regs->sp);

    // 打印 PSTATE
    printf("  SPSR_EL1 (PSTATE) : 0x%x\r\n", regs->pstate);

    // 打印 ESR 解码
    uint64_t ec = (esr >> 26) & 0x3f;
    uint64_t iss = esr & 0xffffff;
    printf("  ESR               : 0x%lx (EC=0x%x, ISS=0x%x)\r\n", esr, ec, iss);

    // 打印当前进程
    if (current) {
        printf("  Process mm->pgd   : 0x%x\n", current->mm->pgd);
    } else {
        printf("  No current process context! ⚠️\n");
    }

    printf("Page fault at 0x%x, ESR: 0x%x\r\n", addr, esr);
    printf("Fault context: PC=0x%x SP=0x%x\r\n", 
           get_elr_el1(), get_sp_el0());
    
    // 检查地址是否应用户空间
   // if (addr < user_begin) {
    //    printf("Kernel accessed user address");
   // }
   // debug_pgd(current->mm);
    // 打印当前页表项
//   dump_pte(current->mm, addr);
}

void handle_user_page_fault(u64 addr, u64 esr) {
    printf("handle_user_page_fault: 0x%x", addr);
	do_page_fault(addr,esr);
    // 获取当前进程的页表
    pgd_t *pgd = current->mm->pgd;
    
    // 1. 检查地址合法性
 //   if (addr < user_begin || addr >= user_end) {
   //     printf("Invalid user address: 0x%x", addr);
  //  }

    // 2. 区分缺页类型
    u32 fault_type = esr & ESR_ELx_FSC_TYPE;
	
	unsigned long fault_page = addr & PAGE_MASK;
    
    // 3. 处理栈缺页
    if (fault_page >= USER_STACK_BASE - USER_STACK_SIZE && 
        fault_page < USER_STACK_BASE) {
        
        u64 phys_page = get_free_page();
        if (!phys_page) printf("OOM for stack");
        
        map_page(pgd, addr & PAGE_MASK, phys_page); //                PTE_USER | PTE_WRITE | PTE_UXN
        
        printf("User Mapped stack page: VA=0x%x → PA=0x%x\n", 
               addr & PAGE_MASK, phys_page);
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
