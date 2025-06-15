#include "mm.h"
#include "mem.h"
#include "sched.h"
#include "fork.h"
#include "entry.h"
#include "printf.h"
#include "user.h"
#define PF_KTHREAD		            	0x00000002
#define KERNEL_VIRT_BASE  0xFFFFFF8000000000ULL
#define KERNEL_PHYS_BASE  0x0000000000080000ULL  /* 物理镜像起点 */
extern pg_dir;
int copy_process_inkernel(unsigned long fn, unsigned long arg)
{
	preempt_disable();
	struct task_struct *p;

	p = (struct task_struct *) get_free_page();
	if (!p)
		return 1;
	p->priority = current->priority;
	p->state = TASK_RUNNING;
	p->counter = p->priority;
	p->preempt_count = 1; //disable preemtion until schedule_tail

	p->cpu_context.x19 = fn;
	p->cpu_context.x20 = arg;
	p->cpu_context.pc = (unsigned long)ret_from_fork;
	p->cpu_context.sp = (unsigned long)p + THREAD_SIZE;
	int pid = nr_tasks++;
	task[pid] = p;	
	preempt_enable();
	return 0;
}
int copy_process(unsigned long clone_flags, unsigned long fn, unsigned long arg, unsigned long stack)
{

	
	printf("first in copy_process%x\n\r",fn);
	preempt_disable();
	struct task_struct *p;
	unsigned long page = allocate_kernel_page();
	printf("allocate_kernel_page in copy_process%x\n\r",page);
	p = (struct task_struct *)page ;
	if (!p) {
		printf("Error while get_free_pages in copy_process\n\r");
		return -1;
	}

	
	unsigned long kernel_stack = allocate_kernel_page(); // 分配内核栈
    if (!kernel_stack) {
        printf("Failed to allocate kernel stack\n\r");
      //  free_kernel_page(page); // 释放已分配的task_struct
        return -1;
    }
	p->stack = kernel_stack; // 所有任务都设置内核栈指针
    printf("Allocated kernel stack at 0x%x\n\r", kernel_stack);




	struct pt_regs *childregs = task_pt_regs(p);
	memzero((unsigned long)childregs, sizeof(struct pt_regs));
	memzero((unsigned long)&p->cpu_context, sizeof(struct cpu_context));
	//printf("after  memzero in copy_process\n\r");
	
	if (clone_flags & PF_KTHREAD) {
		p->cpu_context.x19 = fn;
		p->cpu_context.x20 = arg;

	} else {
		struct pt_regs * cur_regs = task_pt_regs(current);
		*childregs=	*cur_regs; 	
		childregs->regs[0] = 0;
      //  copy_virt_memory(p);

        unsigned long user_kstack = allocate_kernel_page();  // 返回 KVA
        if (!user_kstack) return -1;
        p->stack = user_kstack;  // 把 p->stack 设成新分配的内核栈虚拟地址
        childregs->sp = user_kstack + PAGE_SIZE;
		//childregs->sp = stack + PAGE_SIZE; 
		//p->stack = stack;
		printf("else in copy_process\n\r");
        p->cpu_context.x19 = 0;
        p->cpu_context.x20 = 0;
	}
	
	p->flags = clone_flags;
	p->priority = current->priority;
	p->state = TASK_RUNNING;
	p->counter = p->priority=1;
	p->preempt_count = 1; //disable preemtion until schedule_tail

	p->cpu_context.pc = (unsigned long)ret_from_fork;
	p->cpu_context.sp = (unsigned long)childregs;
	int pid = nr_tasks++;
	task[pid] = p;	
	printf("before return in copy_process,ret_from_fork=%x,childregs=%x ,p=%x\r\n",ret_from_fork,childregs,p);
	preempt_enable();

	return pid;
}


static inline bool is_aligned(unsigned long addr, unsigned long align)
{
    return !(addr & (align - 1));
}

unsigned long map_and_copy_user_code(void)
{
    /* —— 1) 计算源区的高半区虚地址及大小 —— */
    unsigned long src_va_begin = (unsigned long)&user_begin;
    unsigned long src_va_end   = (unsigned long)&user_data_begin;
    size_t         code_size   = src_va_end - src_va_begin;

    printf("DEBUG: user_begin @ %x, &user_begin @ %x\n",user_begin, &user_begin); 
    printf("DEBUG: hi user_begin @ %x, hi &user_beginn @ %x",
          ((unsigned long) user_begin)>>32, ((unsigned long)(&user_begin))>>32);

    printf("DEBUG: src_va_begin @ %x, src_va_end @ %x, size = %d\n",
           src_va_begin, src_va_end, code_size);
           
    printf("DEBUG: hi src_va_begin @ %x, hi src_va_end @ %x",
           src_va_begin>>32, src_va_end>>32);

    /* —— 2) 分配一页用户物理页，并映射到用户空间 VA=0x0040_0000 —— */
    unsigned long new_pa = allocate_user_page(
                              current,
                              USER_CODE_BASE,    /* = 0x00400000 in EL0 */
                              USER_FLAGS_CODE);
    if (!new_pa) {
        printf("ERROR: alloc user code page failed\n");
        return 0;
    }
    printf("Mapped user code VA=0x%x → new PA=0x%x\n",
           USER_CODE_BASE, new_pa);

    /* —— 3) 在内核高半区找出源/目地的可访问地址 —— */
    void *src_va  = (void *)src_va_begin;    /* 高半区虚地址 */
    void *dst_va  = (void *)__va(new_pa);    /* direct-map 转高半区 */

    /* —— 4) 拷贝整个 .user.text 段 —— */
    memcpy(dst_va, src_va, code_size);

    /* —— 5) D-Cache 写回 + I-Cache 失效 ——*/
    asm volatile(
        "dsb ish\n\t"
        "ic iallu\n\t"
        "dsb ish\n\t"
        "isb\n\t"
    );
 
    /* —— 验证一下第一个指令 —— */
    {
        uint32_t first_instr = *(uint32_t *)dst_va;
        printf("After copy, first instr = 0x%x (expect a9bd7bfd)\n",
               first_instr);
    }
    /* 6) 再次调试：验证 offset=0 处，和 user_process 处的指令都正确 */
    {
        uint32_t ins0 = *(uint32_t *)dst_va;
        unsigned long entry_off = (unsigned long)&user_process - src_va_begin;
        uint32_t ins1 = *(uint32_t *)((char *)dst_va + entry_off);
        printf( "USER COPY: [0x0] = 0x%x (expect a9bd7bfd)\n", ins0);
        printf( "USER COPY: [entry_off=0x%x] = 0x%x (expect a9bf7bfd)\n",
               entry_off, ins1);
    }

    printf("User code mapped: src_va=0x%x , dest_va=%x\n\r", src_va, dst_va);
    return new_pa;
}

int move_to_user_mode(unsigned long start, unsigned long size, unsigned long pc)
{
    if (!start || !size || size > 0x100000) {
        printf("Invalid user program size or addr\n\r");
        return -1;
    }
    printf("move_to_user_mode current->mm->pgd %x,pa=%x\n\r",current->mm->pgd,__va(current->mm->pgd));

    struct pt_regs *regs = task_pt_regs(current);
     unsigned long dst_va=  map_and_copy_user_code();
        // 举例：打印 PGD[ <0x400000 索引> ] 的值
    unsigned long *pgd_base = (unsigned long *)__va(current->mm->pgd);
    int pgd_index = (0x400000 >> 39) & 0x1FF;  // AArch64 通常每级用 9 位索引
    printf("Child PGD[%d] = 0x%x\n", pgd_index, pgd_base[pgd_index]);

    // 分配栈页（从栈底向下增长）
    unsigned long stack_va = USER_STACK_BASE  - USER_STACK_SIZE;
    unsigned long stack_page = allocate_user_page(current, stack_va,PTE_AF| PTE_VALID | PTE_USER | PTE_WRITE  ); // User-writable, no execute);
    if (!stack_page) {
      //  free_page(code_page - VA_START);
        return -1;
    }
    printf(" after  allocate stack_page %x,stack_va=%x \n\r",stack_page,stack_va);

    // 举例：打印 PGD[ <0x400000 索引> ] 的值
 
    regs->pstate = PSR_MODE_EL0t|PSR_DAIF_MASK;  
    regs->pc =pc;    
    //printf(" regs->pc  USER_CODE_BASE:%x,pc=%x\r\n",code_va,pc);            
    regs->sp =stack_va + PAGE_SIZE ; 


printf("user jump: pc=0x%x sp=0x%x pstate=0x%x\n",regs->pc, regs->sp, regs->pstate);
	debug_pgd_recursive(current->mm->pgd);
    
//set_pgd(current->mm->pgd);
  printf("After set_pgd, about to switch, ELR_EL1=%x, SPSR_EL1=%x, SP_EL0=%x\n",regs->pc, regs->pstate, regs->sp);
//return 0;
   unsigned long entry_pc  = regs->pc;     // 例如 0x00400054
    unsigned long spsr_val  = regs->pstate; // 例如 0x00000000000003C0
    unsigned long user_sp   = regs->sp;     // 例如 0x000000000007FFF000
    unsigned long tmp;

// 1) 为 TTBR0_EL1 指定的页表设定合适的翻译控制
unsigned long tcr = 0;
//tcr |= (32UL << 0);   // T0SZ = 32 → VA [31:0] 有效
tcr |= (16UL << 0);    // T0SZ=16 → 用户空间 48-bit (0x0000_0000_0000_0000 - 0x0000_FFFF_FFFF_FFFF)
tcr |= (16UL << 16);   // T1SZ=16 → 内核空间 48-bit (0xFFFF_0000_0000_0000 - 0xFFFF_FFFF_FFFF_FFFF)
tcr |= (1UL  << 8);   // IRGN0 = 01 → Inner WB WA
tcr |= (1UL  << 10);  // ORGN0 = 01 → Outer WB WA
tcr |= (3UL  << 12);  // SH0   = 11 → Inner Shareable
tcr |= (0UL  << 14);  // TG0   = 00 → 4KB granule
__asm__ volatile("msr TCR_EL1, %0\n\t" :: "r"(tcr) : "memory");
__asm__ volatile("isb\n\t");
printf("TCR_EL1 = 0x%x\n", tcr);
    // 1) 配置 MAIR_EL1 → 让 AttrIndx0 代表 Normal, WB&WA
    unsigned long mair = (0xffULL << (8*0));
    __asm__ volatile("msr MAIR_EL1, %0\n\t" :: "r"(mair) : "memory");
    __asm__ volatile("isb\n\t");
    printf("MAIR_EL1 set to 0x%x\n", mair);

    // 2) 写 TTBR0_EL1
    unsigned long pgd_phys = current->mm->pgd;
    __asm__ volatile("msr TTBR0_EL1, %0\n\t" :: "r"(pgd_phys) : "memory");
    __asm__ volatile("isb\n\t");
    // 验证
    unsigned long check_ttbr0;
    __asm__ volatile("mrs %0, TTBR0_EL1\n\t" : "=r"(check_ttbr0));
    printf("TTBR0_EL1 = 0x%x (expect 0x%x)\n", check_ttbr0, pgd_phys);

    // 3) 打开 MMU：设置 SCTLR_EL1.M = 1
    unsigned long sctlr;
    __asm__ volatile("mrs %0, SCTLR_EL1\n\t" : "=r"(sctlr));
    printf("Old SCTLR_EL1 = 0x%x\n", sctlr);
    sctlr |= 1;  // bit0 = 1 → 开启 MMU
    __asm__ volatile("msr SCTLR_EL1, %0\n\t" :: "r"(sctlr) : "memory");
    __asm__ volatile("isb\n\t");
    // 验证
    __asm__ volatile("mrs %0, SCTLR_EL1\n\t" : "=r"(sctlr));
    printf("New SCTLR_EL1 = 0x%x (bit0 should be 1)\n", sctlr);

    // ——— 写 ELR_EL1 ———
    __asm__ volatile("msr ELR_EL1, %0\n\t" :: "r"(entry_pc) : "memory");
    // 立即读取 ELR_EL1 并打印，确认写入生效
    __asm__ volatile("mrs %0, ELR_EL1\n\t" : "=r"(tmp));
    printf("VERIFY ELR_EL1 = 0x%x (expect 0x%x)\n", tmp, entry_pc);

    // ——— 写 SPSR_EL1 ———
    __asm__ volatile("msr SPSR_EL1, %0\n\t" :: "r"(spsr_val) : "memory");
    // 立即读取 SPSR_EL1 并打印
    __asm__ volatile("mrs %0, SPSR_EL1\n\t" : "=r"(tmp));
    printf("VERIFY SPSR_EL1 = 0x%x (expect 0x%x)\n", tmp, spsr_val);

    // ——— 写 SP_EL0 ———
    __asm__ volatile("msr SP_EL0, %0\n\t" :: "r"(user_sp) : "memory");
    // 立即读取 SP_EL0 并打印
    __asm__ volatile("mrs %0, SP_EL0\n\t" : "=r"(tmp));
    printf("VERIFY SP_EL0  = 0x%x (expect 0x%x)\n", tmp, user_sp);
    __asm__ volatile("isb\n\t");


    //验证

/*
uint64_t *pte_ptr = (uint64_t *)0xf89000;
    uint64_t pte = *pte_ptr;
printf("[PTE CHECK] VA=0x400060 → hi PRT :%x,PTE=0x%x (phys=0x%x, flags=0x%x)\n",pte>>32,pte, pte & 0xFFFFFFFFF000, pte & 0xFFF);
// 检查权限位
uint32_t ap = (pte >> 6) & 0x3;
if (ap != 0 && ap != 2) {
    printf("ERROR: PTE does not allow user access! (AP=0x%x)\n", ap);
    return -1;
}
if (pte & (1 << 54)) {  // XN=1 (Execute Never)
    printf("  ERROR: Page is marked non-executable (XN=1)!\n");
}

*/

//printf("Instruction at PA 0x100a060: 0x%x\n", *((uint64_t *)__va(0x100a060)));
uint32_t *phys_ptr = (uint32_t *)__va(0x100a000);
printf("Phys [0x100a000] = 0x%x\n", *phys_ptr);
    printf(">>> About to eret to EL0 <<<\n");

 //   __asm__ volatile("eret\n\t");
   
 // unsigned long elr = regs->pc;       // 应该是 0x400050
//unsigned long spsr = regs->pstate;  // 应该是 0x0 （EL0t）
//unsigned long sp0 = regs->sp;       // 应该是 0x7fff000

    /*

  __asm__ volatile(
    "msr    ELR_EL1, %0\n"   // 把 regs->pc（0x400050）写到 ELR_EL1
    "msr    SPSR_EL1, %1\n"  // 把 regs->pstate（PSR_MODE_EL0t）写到 SPSR_EL1
    "msr    SP_EL0, %2\n"    // 把 regs->sp（0x7fff000）写到 SP_EL0
    "eret\n"                 // 一条指令跳到 EL0 执行用户态
    :
    : "r"(regs->pc), "r"(regs->pstate), "r"(regs->sp)
    : "memory"
);
*/
	//print_user_mapping(__va(current->mm->pgd),USER_CODE_BASE);
   // walk_page_table(USER_CODE_BASE,current->mm->pgd);
     __asm__ volatile("eret\n\t");

    return 0;
}
 
void copy_kernel_mappings(pgd_t *dest_pgd, pgd_t *kernel_pgd) {
    if (!dest_pgd || !kernel_pgd) {
        printf("Invalid PGD pointers\n");
        return;
    }



    // 只拷贝 PGD[511]：内核映射在最高虚拟地址区
    dest_pgd[511] = kernel_pgd[511];  // 共享内核PUD，避免复制

    printf("Shared kernel mapping: dest PGD[511] = 0x%x,src PGD[511]=%x\n", pgd_val(dest_pgd[511]),pgd_val(kernel_pgd[511]));
}









struct pt_regs * task_pt_regs(struct task_struct *tsk){
	unsigned long p = (unsigned long)tsk->stack + THREAD_SIZE - sizeof(struct pt_regs);
	return (struct pt_regs *)p;
}

