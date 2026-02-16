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
		//*childregs=	*cur_regs; 	
	//	childregs->regs[0] = 0;
     //   unsigned long user_kstack = allocate_kernel_page();  // 返回 KVA
      //  if (!user_kstack) return -1;
     //   p->stack = user_kstack;  // 把 p->stack 设成新分配的内核栈虚拟地址
     //   childregs->sp = user_kstack + PAGE_SIZE;
		//childregs->sp = stack + PAGE_SIZE; 
		//p->stack = stack;
		printf("else in copy_process\n\r");
      //  p->cpu_context.x19 = 0;
      //  p->cpu_context.x20 = 0;


       
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
	
	preempt_enable();

	return pid;
}


static inline bool is_aligned(struct task_struct *p,unsigned long addr, unsigned long align)
{
    return !(addr & (align - 1));
}

unsigned long map_and_copy_user_code(struct task_struct *p)
{
    /* —— 1) 计算源区的高半区虚地址及大小 —— */
    unsigned long src_va_begin = (unsigned long)&user_begin;
    unsigned long src_va_end   = (unsigned long)&user_data_begin;
    size_t         code_size   = src_va_end - src_va_begin;

    printf("DEBUG: hi user_begin @ %x, low user_begin @ %x\r\n",((unsigned long )user_begin)>>32, user_begin); 
    //printf("DEBUG: hi user_begin @ %x, hi &user_beginn @ %x\r\n",
     //     ((unsigned long) user_begin)>>32, ((unsigned long)(&user_begin))>>32);

    printf("\r\nDEBUG: src_va_begin @ %x, src_va_end @ %x, size = %d\r\n",
           src_va_begin, src_va_end, code_size);
           
    //printf("DEBUG: hi src_va_begin @ %x, hi src_va_end @ %x",
     //      src_va_begin>>32, src_va_end>>32);

    /* —— 2) 分配一页用户物理页，并映射到用户空间 VA=0x0040_0000 —— */
    unsigned long flag=USER_FLAGS_CODE;
    flag&=~(1<<51);
    flag&=~(1<<54);
    unsigned long new_pa = allocate_user_page(
                              p,
                              USER_CODE_BASE,    /* = 0x00400000 in EL0 */
                              flag);
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
    _memcpy((u64*)dst_va, (u64*)src_va, code_size);

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
        unsigned long entry_off = (unsigned long)&user_start - src_va_begin;
        uint32_t ins1 = *(uint32_t *)((char *)dst_va + entry_off);
        printf( "USER COPY: [0x0] = 0x%x (expect a9bd7bfd)\n", ins0);
        printf( "USER COPY: [entry_off=0x%x] = 0x%x (expect a9bf7bfd)\n",
               entry_off, ins1);
    }

    printf("User code mapped: hi src_va=0x%x,low src_va=0x%x  ,hi dst_va=0x%x,low dst_va=0x%x\n\r", ((unsigned long )src_va)>>32,src_va,((unsigned long )dst_va)>>32,dst_va);
    return new_pa;
}

static inline void flush_tlb_entry(unsigned long va) {
    __asm__ volatile(
        "dsb ishst\n\t"
        "tlbi vae1is, %0\n\t"
        "dsb ish\n\t"
        "isb\n\t"
        :: "r"(va >> 12)
    );
}

void walk_page_table(uint64_t table_phys, int level, uint64_t base_va) {
    uint64_t* table = (uint64_t*)__va(table_phys);
    for (int i = 0; i < 512; ++i) {
        uint64_t entry = table[i];
        if (entry & 1) { // valid
            uint64_t pa = entry & ~(PAGE_SIZE - 1);
            printf("[%d] @ leve%d, va=0x%x, entry=0x%x, pa=0x%x, flags=0x%x\n",
                i, level, base_va | ((uint64_t)i << (12 + 9 * (3 - level))),
                entry, pa, entry & 0xFFF);
            // 如果不是叶子，还递归
            if (level < 3 && ((entry & 0x3) == 0x3)) // Table descriptor
                walk_page_table(pa, level + 1, base_va | ((uint64_t)i << (12 + 9 * (3 - level))));
        }
    }
}

void dump_pagetable_walk(uint64_t pgd_phys, uint64_t va) {
    printf("==== ARM64 Page Table Walk for VA=0x%x ====\n", va);
    uint64_t idx[4];
    idx[0] = (va >> PGD_SHIFT) & LEVEL_MASK;
    idx[1] = (va >> PUD_SHIFT) & LEVEL_MASK;
    idx[2] = (va >> PMD_SHIFT) & LEVEL_MASK;
    idx[3] = (va >> PTE_SHIFT) & LEVEL_MASK;

    uint64_t pa, entry;
    printf("PGD PA: 0x%x\n", pgd_phys);

    uint64_t* pgd = (uint64_t*)__va(pgd_phys);
    entry = pgd[idx[0]];
    printf("  [PGD][%u] = 0x%x\n", idx[0], entry);
    if (!(entry & 1)) { printf("    INVALID PGD ENTRY\n"); return; }
    pa = entry & PAGE_MASK;

    uint64_t* pud = (uint64_t*)__va(pa);
    entry = pud[idx[1]];
    printf("  [PUD][%u] = 0x%x\n", idx[1], entry);
    if (!(entry & 1)) { printf("    INVALID PUD ENTRY\n"); return; }
    pa = entry & PAGE_MASK;

    uint64_t* pmd = (uint64_t*)__va(pa);
    entry = pmd[idx[2]];
    printf("  [PMD][%u] = 0x%x\n", idx[2], entry);
    if (!(entry & 1)) { printf("    INVALID PMD ENTRY\n"); return; }
    pa = entry & PAGE_MASK;

    uint64_t* pte = (uint64_t*)__va(pa);
    entry = pte[idx[3]];
    printf("  [PTE][%u] = 0x%x\n", idx[3], entry);
    if (!(entry & 1)) { printf("    INVALID PTE ENTRY\n"); return; }
    pa = entry & PAGE_MASK;

    printf("  -> Final PA: 0x%x (Page flags: 0x%x)\n", pa, entry & ~PAGE_MASK);
    // 你可以在这里检查物理页内容，比如首字节
    printf("  [Phys 0x%x] = 0x%x\n", pa, *(volatile uint32_t*)__va(pa));
}




int move_to_user_mode(struct task_struct *p,unsigned long start, unsigned long size, unsigned long pc)
{
    if (!start || !size || size > 0x100000) {
        printf("Invalid user program size or addr\n\r");
        return -1;
    }
    printf("move_to_user_mode current->mm->pgd %x,va=%x\n\r",p->mm->pgd,__va(p->mm->pgd));

    struct pt_regs *regs = task_pt_regs(p);
     unsigned long dst_va=  map_and_copy_user_code(p);
        // 举例：打印 PGD[ <0x400000 索引> ] 的值
    unsigned long *pgd_base = (unsigned long *)__va(p->mm->pgd);
    int pgd_index = (USER_CODE_BASE >> 39) & 0x1FF;  // AArch64 通常每级用 9 位索引
    printf("Child PGD[%d] = 0x%x\n", pgd_index, pgd_base[pgd_index]);

    // 分配栈页（从栈底向下增长）
    unsigned long stack_va = USER_STACK_BASE  - USER_STACK_SIZE;
    unsigned long stack_page = allocate_user_page(p, stack_va,USER_FLAGS_DATA ); // User-writable, no execute);
    if (!stack_page) {
      //  free_page(code_page - VA_START);
        return -1;
    }
    printf(" after  allocate stack_page %x,stack_va=%x \n\r",stack_page,stack_va);

 
    regs->pstate = PSR_MODE_EL0t|PSR_DAIF_MASK;  
    regs->pc =pc;    
    printf(" regs->pc  hi=%x,low=%x \r\n",pc>>32,pc);            
    regs->sp =stack_va + PAGE_SIZE ; 

        dump_pagetable_walk(p->mm->pgd, USER_CODE_BASE);    // 检查用户代码
dump_pagetable_walk(p->mm->pgd, 0x7fff000);   // 检查用户栈

    printf("user jump: current->mm->pgd=%x, pc=0x%x sp=0x%x pstate=0x%x\n",p->mm->pgd,regs->pc, regs->sp, regs->pstate);
//enter_user_from_kthread(regs, current->mm->pgd);
//__builtin_unreachable();
//return;
   
    //set_pgd(current->mm->pgd,regs);

    __asm__ volatile (
        "msr ttbr0_el1, %0\n\t"
        "tlbi vmalle1\n\t"
        "dsb ish\n\t"
        "isb\n\t"
        :
        : "r"(__pa(current->mm->pgd))
        : "memory"
    );
   printf("after flush ttbr0_el1\n");
   unsigned long val;
__asm__ volatile("mrs %0, ttbr0_el1\n\t" : "=r"(val));
printf("TTBR0_EL1 right after set: 0x%x\n", val);





unsigned long tcr = 
      (16UL    <<  0)   /* T0SZ = 16 → 48-bit VA */ 
    | (1UL     <<  8)   /* IRGN0 = 01 (NC) */  
    | (1UL     << 10)   /* ORGN0 = 01 (NC) */  
    | (3UL     << 12)   /* SH0  = 11 (inner) */  
    | (0UL     << 14)   /* TG0  = 00 (4K) */  
    | (16UL    << 16)   /* T1SZ = 16 → 48-bit VA */  
    | (1UL     << 24)   /* IRGN1 = 01 (WBWA) */  
    | (1UL     << 26)   /* ORGN1 = 01 (WBWA) */  
    | (3UL     << 28)   /* SH1  = 11 (inner) */  
    | (2UL     << 30);  /* TG1  = 10 (4K) */  
    
__asm__ volatile("msr TCR_EL1, %0\n\t" :: "r"(tcr) : "memory");
__asm__ volatile("isb\n\t");
printf("TCR_EL1 = 0x%x\n", tcr);

 // 1) 配置 MAIR_EL1 → 让 AttrIndx0 代表 Normal, WB&WA
    unsigned long mair = ( (0xffUL << 8) | (0x44UL << 0)) ;//0xffULL << (8*0));
    __asm__ volatile("msr MAIR_EL1, %0\n\t" :: "r"(mair) : "memory");
    __asm__ volatile("isb\n\t");
    printf("MAIR_EL1 set to 0x%x\n", mair);

    asm volatile("tlbi vaae1is, %0" : : "r" (0x300000 >> 12));
asm volatile("dsb ish");
asm volatile("isb");


asm volatile("dc cvau, %0" : : "r" (__va(0x1007000)));  // Clean to PoU using valid user VA
asm volatile("dsb ish");  // Ensure completion
asm volatile("ic ivau, %0" : : "r" (__va(0x1007000)));  // Invalidate I-cache to PoU using same VA
asm volatile("dsb ish");  // Ensure completion
asm volatile("isb");  // Synchronize instruction fetch

uint32_t instr;
asm volatile("ldr %0, [%1]" : "=r" (instr) : "r" (__va(0x1007000)));
printf("Instruction at VA 0x300000: 0x%x\n", instr);

  //printf("After set_pgd, about to switch, ELR_EL1=%x, SPSR_EL1=%x, SP_EL0=%x\n",regs->pc, regs->pstate, regs->sp);
return 0;


}
 
void copy_kernel_mappings(pgd_t *dest_pgd, pgd_t *kernel_pgd) {
    if (!dest_pgd || !kernel_pgd) {
        printf("Invalid PGD pointers\n");
        return;
    }



    // 只拷贝 PGD[511]：内核映射在最高虚拟地址区
    dest_pgd[511] = kernel_pgd[511];  // 共享内核PUD，避免复制

    

    for (int i = 0; i < 2; ++i) {
    printf("copy_kernel_mappings kernel_pgd[%d] = 0x%x\n", i, pgd_val(kernel_pgd[i]));
}
 for (int i =510; i < 512; ++i) {
    printf(" copy_kernel_mappings kernel_pgd[%d] = 0x%x\n", i, pgd_val(kernel_pgd[i]));
}

    printf("Shared kernel mapping: dest PGD[511] = 0x%x,src PGD[511]=%x\n", pgd_val(dest_pgd[511]),pgd_val(kernel_pgd[511]));
}









struct pt_regs * task_pt_regs(struct task_struct *tsk){
	unsigned long p = (unsigned long)tsk->stack + THREAD_SIZE - sizeof(struct pt_regs);
	return (struct pt_regs *)p;
}

