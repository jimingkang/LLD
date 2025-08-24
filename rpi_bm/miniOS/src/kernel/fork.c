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

    printf("DEBUG: user_begin @ %x, &user_begin @ %x\r\n",user_begin, &user_begin); 
    //printf("DEBUG: hi user_begin @ %x, hi &user_beginn @ %x\r\n",
     //     ((unsigned long) user_begin)>>32, ((unsigned long)(&user_begin))>>32);

    printf("\r\nDEBUG: src_va_begin @ %x, src_va_end @ %x, size = %d\r\n",
           src_va_begin, src_va_end, code_size);
           
    //printf("DEBUG: hi src_va_begin @ %x, hi src_va_end @ %x",
     //      src_va_begin>>32, src_va_end>>32);

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
    _memcpy(dst_va, src_va, code_size);

    /* —— 5) Enhanced cache maintenance for executable pages —— */
    // Clean data cache for the destination physical address
    unsigned long dst_pa = new_pa;
    for (unsigned long addr = dst_pa; addr < dst_pa + code_size; addr += 64) {
        asm volatile("dc cvac, %0\n\t" :: "r"(addr) : "memory");
    }
    
    // Data synchronization barrier
    asm volatile("dsb sy\n\t");
    
    // Invalidate instruction cache for the virtual address range
    for (unsigned long addr = (unsigned long)dst_va; addr < (unsigned long)dst_va + code_size; addr += 64) {
        asm volatile("ic ivau, %0\n\t" :: "r"(addr) : "memory");
    }
    
    // Full memory barriers and instruction synchronization
    asm volatile(
        "dsb ish\n\t"
        "isb\n\t"
        ::: "memory"
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

    printf("User code mapped: src_va=0x%x , dest_va=%x\n\r", src_va, dst_va);
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




int move_to_user_mode(unsigned long start, unsigned long size, unsigned long pc)
{
    if (!start || !size || size > 0x100000) {
        printf("Invalid user program size or addr\n\r");
        return -1;
    }
    printf("move_to_user_mode current->mm->pgd %x,va=%x\n\r",current->mm->pgd,__va(current->mm->pgd));

    struct pt_regs *regs = task_pt_regs(current);
     unsigned long dst_va=  map_and_copy_user_code();
        // 举例：打印 PGD[ <0x400000 索引> ] 的值
    unsigned long *pgd_base = (unsigned long *)__va(current->mm->pgd);
    int pgd_index = (0x400000 >> 39) & 0x1FF;  // AArch64 通常每级用 9 位索引
    printf("Child PGD[%d] = 0x%x\n", pgd_index, pgd_base[pgd_index]);

    // 分配栈页（从栈底向下增长）
    unsigned long stack_va = USER_STACK_BASE  - USER_STACK_SIZE;
    unsigned long stack_page = allocate_user_page(current, stack_va,USER_FLAGS_DATA ); // User-writable, no execute);
    if (!stack_page) {
      //  free_page(code_page - VA_START);
        return -1;
    }
    printf(" after  allocate stack_page %x,stack_va=%x \n\r",stack_page,stack_va);



 

 
    regs->pstate = PSR_MODE_EL0t|PSR_DAIF_MASK;  
    regs->pc =pc;    
    printf(" regs->pc  pc=%x\r\n",pc);            
    regs->sp =stack_va + PAGE_SIZE ; 


    printf("user jump: current->mm->pgd=%x, pc=0x%x sp=0x%x pstate=0x%x\n",current->mm->pgd,regs->pc, regs->sp, regs->pstate);
	//debug_pgd_recursive(current->mm->pgd);
   
    //set_pgd(current->mm->pgd,regs);

    __asm__ volatile (
        "msr ttbr0_el1, %0\n\t"
     //   "tlbi vmalle1is\n\t"
     //   "dsb ish\n\t"
        "isb\n\t"
        :
        : "r"(current->mm->pgd)
        : "memory"
    );
   printf("after flush ttbr0_el1\n");
   unsigned long val;
__asm__ volatile("mrs %0, ttbr0_el1\n\t" : "=r"(val));
printf("TTBR0_EL1 right after set: 0x%x\n", val);
    __asm__ volatile(
        "dsb sy\n\t"
        "tlbi vaae1is, %0\n\t"
        "tlbi vaae1is, %1\n\t"
        "dsb sy\n\t"
        "isb\n\t"
        :: "r"(0x400000 >> 12), "r"(0x8000000 >> 12)
        : "memory"
    );


    dump_pagetable_walk(current->mm->pgd, 0x400000);    // 检查用户代码
dump_pagetable_walk(current->mm->pgd, 0x7fff000);   // 检查用户栈

    // The process is now set up for user mode. The actual transition will happen
    // when this process is scheduled and ret_to_user is called by the scheduler.
    printf("User mode setup complete: ELR_EL1=%x, SPSR_EL1=%x, SP_EL0=%x\n", regs->pc, regs->pstate, regs->sp);
    return 0;
/*
   unsigned long entry_pc  = regs->pc;     // 例如 0x00400054
    unsigned long spsr_val  = regs->pstate; // 例如 0x00000000000003C0
    unsigned long user_sp   = regs->sp;     // 例如 0x000000000007FFF000
    unsigned long tmp;


    unsigned long *pgd_base2 = (unsigned long *)__va(current->mm->pgd);
unsigned long pgd_val = pgd_base2[(0x400000 >> 39) & 0x1FF];
unsigned long *pud_base2= (unsigned long *)__va(pgd_val & 0x7ffffff000);
unsigned long pud_val = pud_base2[(0x400000 >> 30) & 0x1FF];
unsigned long *pmd_base2 = (unsigned long *)__va(pud_val & 0x7ffffff000);
unsigned long pmd_val = pmd_base2[(0x400000 >> 21) & 0x1FF];
unsigned long *pte_base2 = (unsigned long *)__va(pmd_val & 0x7ffffff000);
unsigned long pte_val = pte_base2[(0x400000 >> 12) & 0x1FF];
printf("Before eret: PGD=0x%x, PUD=0x%x, PMD=0x%x, PTE=0x%x\n",pgd_val, pud_val, pmd_val, pte_val);
pgd_base2[(0x400000 >> 39) & 0x1FF] |= (1UL << 10); // Set AF
pud_base2[(0x400000 >> 30) & 0x1FF] |= (1UL << 10);
pmd_base2[(0x400000 >> 21) & 0x1FF] |= (1UL << 10);
pte_base2[(0x400000 >> 12) & 0x1FF] |= (1UL << 10);
printf("Updated: PGD=0x%x, PUD=0x%x, PMD=0x%x, PTE=0x%x\n",
       pgd_base2[(0x400000 >> 39) & 0x1FF],
       pud_base2[(0x400000 >> 30) & 0x1FF],
       pmd_base2[(0x400000 >> 21) & 0x1FF],
       pte_base2[(0x400000 >> 12) & 0x1FF]);

//Clean and invalidate caches for coherency
__asm__ volatile(
    "dc civac, %0\n\t" // Clean and invalidate user code
    "dc civac, %1\n\t" // Clean and invalidate stack
    "dc civac, %2\n\t" // Clean and invalidate PGD
    "dc civac, %3\n\t" // Clean and invalidate PUD
    "dc civac, %4\n\t" // Clean and invalidate PMD
    "dc civac, %5\n\t" // Clean and invalidate PTE
    "dsb sy\n\t"
    :: "r"(0x1008000), "r"(0x100a000), "r"(0x1004000),
       "r"(0x1005000), "r"(0x1006000), "r"(0x1007000)
    : "memory"
);
printf("Cache cleaned for user code, stack, and page tables\n");


    unsigned long user_va = 0x400000;      // 用户空间虚拟地址
unsigned long pgd_phys1 =0x95000;// 0x1004000;    // PGD 物理地址
unsigned long pud_phys = 0x1005000;    // PUD 物理地址
unsigned long pmd_phys = 0x1006000;    // PMD 物理地址
unsigned long pte_phys = 0x1007000;    // PTE 物理地址
unsigned long page_phys = 0x1008000;   // 最终映射的物理页
int pgd_idx = (user_va >> 39) & 0x1FF;
int pud_idx = (user_va >> 30) & 0x1FF;
int pmd_idx = (user_va >> 21) & 0x1FF;
int pte_idx = (user_va >> 12) & 0x1FF;
unsigned long *pgd1= (unsigned long *)__va(pgd_phys1);
unsigned long *pud = (unsigned long *)__va(pud_phys);
unsigned long *pmd = (unsigned long *)__va(pmd_phys);
unsigned long *pte = (unsigned long *)__va(pte_phys);
// PGD -> PUD
pgd1[pgd_idx] = pud_phys | 0x3;   // Valid + Table
// PUD -> PMD
pud[pud_idx] = pmd_phys | 0x3;   // Valid + Table
// PMD -> PTE
pmd[pmd_idx] = pte_phys | 0x3;   // Valid + Table
// PTE -> 最终物理页
pte[pte_idx] = page_phys | 0x7c1;  // 如 0x741/0x7c1 等（见前文）


unsigned long stack_va2 = 0x7fff000;         // 用户栈虚拟地址
//unsigned long pud_phys2 = 0x1005000;        // PUD 物理地址
unsigned long pmd_phys2 = 0x1009000;        // PMD 物理地址
unsigned long pte_phys2 = 0x100a000;        // PTE 物理地址
unsigned long stack_page_phys = 0x100a000;  // 栈物理页（和 PTE 指向同一物理页，举例）
int pgd_idx2 = (stack_va2 >> 39) & 0x1FF;
int pud_idx2 = (stack_va2 >> 30) & 0x1FF;
int pmd_idx2 = (stack_va2 >> 21) & 0x1FF;
int pte_idx2 = (stack_va2 >> 12) & 0x1FF;
//unsigned long *pud2 = (unsigned long *)__va(pud_phys2);
unsigned long *pmd2 = (unsigned long *)__va(pmd_phys2);
unsigned long *pte2 = (unsigned long *)__va(pte_phys2);
// PGD -> PUD
//pgd1[pgd_idx2] = pud_phys2 | 0x3;      // Valid + Table
// PUD -> PMD
//pud2[pud_idx2] = pmd_phys2 | 0x3;      // Valid + Table
// PMD -> PTE
pmd2[pmd_idx2] = pte_phys2 | 0x3;      // Valid + Table
// PTE -> 最终物理页
pte2[pte_idx2] = stack_page_phys | 0x741;   // 0x741, 用户数据页标准flag

printf("kernel PGD[%d] = 0x%x\n", pgd_idx, pgd1[pgd_idx]);
printf("kernel PUD[%d] = 0x%x\n", pud_idx, pud[pud_idx]);
printf("kernel PMD[%d] = 0x%x\n", pmd_idx, pmd[pmd_idx]);
printf("kernel PTE[%d] = 0x%x\n", pte_idx, pte[pte_idx]);
printf("kernel PTE[%d] = 0x%x\n", pte_idx2, pte2[pte_idx2]);
*/

// 1) 为 TTBR0_EL1 指定的页表设定合适的翻译控制
//unsigned long tcr = 0;
//tcr |= (32UL << 0);   // T0SZ = 32 → VA [31:0] 有效
//tcr |= (16UL << 0);    // T0SZ=16 → 用户空间 48-bit (0x0000_0000_0000_0000 - 0x0000_FFFF_FFFF_FFFF)
//tcr |= (16UL << 16);   // T1SZ=16 → 内核空间 48-bit (0xFFFF_0000_0000_0000 - 0xFFFF_FFFF_FFFF_FFFF)
//tcr |= (1UL  << 8);   // IRGN0 = 01 → Inner WB WA
//tcr |= (1UL  << 10);  // ORGN0 = 01 → Outer WB WA
//tcr |= (3UL  << 12);  // SH0   = 11 → Inner Shareable
//tcr |= (0UL  << 14);  // TG0   = 00 → 4KB granule

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
   // unsigned long mair = ( (0x00UL << 0) | (0xffUL << 8)) ;//0xffULL << (8*0));
    //__asm__ volatile("msr MAIR_EL1, %0\n\t" :: "r"(mair) : "memory");
   // __asm__ volatile("isb\n\t");
    //printf("MAIR_EL1 set to 0x%x\n", mair);


    // 2) 写 TTBR0_EL1
    pgd_t * user_pgd =(pgd_t*)current->mm->pgd;
dump_pagetable_walk(current->mm->pgd, 0x400000);    // 检查用户代码
dump_pagetable_walk(current->mm->pgd, 0x7fff000);   // 检查用户栈

    unsigned long pgd_phys = (unsigned long)current->mm->pgd;
    
   
printf("sp = 0x%x\n", (unsigned long)__builtin_frame_address(0));
//__asm__ volatile("dsb ishst\n\t");   // 强制所有cache写回
//__asm__ volatile("dsb ish\n\t");
//__asm__ volatile("isb\n\t");
//__asm__ volatile("tlbi vmalle1\n\t");
//__asm__ volatile("dsb ish\n\t");


  


    // ——— 写 ELR_EL1 ———
   // __asm__ volatile("msr ELR_EL1, %0\n\t" :: "r"(entry_pc) : "memory");
    // 立即读取 ELR_EL1 并打印，确认写入生效
   // __asm__ volatile("mrs %0, ELR_EL1\n\t" : "=r"(tmp));
  //  printf("VERIFY ELR_EL1 = 0x%x (expect 0x%x)\n", tmp, entry_pc);

    // ——— 写 SPSR_EL1 ———
   // __asm__ volatile("msr SPSR_EL1, %0\n\t" :: "r"(spsr_val) : "memory");
    // 立即读取 SPSR_EL1 并打印
    //__asm__ volatile("mrs %0, SPSR_EL1\n\t" : "=r"(tmp));
    //printf("VERIFY SPSR_EL1 = 0x%x (expect 0x%x)\n", tmp, spsr_val);

    // ——— 写 SP_EL0 ———
    //__asm__ volatile("msr SP_EL0, %0\n\t" :: "r"(user_sp) : "memory");
    // 立即读取 SP_EL0 并打印
    //__asm__ volatile("mrs %0, SP_EL0\n\t" : "=r"(tmp));
    //printf("VERIFY SP_EL0  = 0x%x (expect 0x%x)\n", tmp, user_sp);
    //__asm__ volatile("isb\n\t");


    //验证


__asm__ volatile(
    "dsb sy\n\t"
    "tlbi vaae1is, %0\n\t"
    "tlbi vaae1is, %1\n\t"
    "dsb sy\n\t"
    "isb\n\t"
    :: "r"(0x400000 >> 12), "r"(0x8000000 >> 12)
    : "memory"
);


  __asm__ volatile(
    "msr    ELR_EL1, %0\n\t"   // 把 regs->pc（0x400050）写到 ELR_EL1
    "msr    SPSR_EL1, %1\n\t"  // 把 regs->pstate（PSR_MODE_EL0t）写到 SPSR_EL1
    "msr    SP_EL0, %2\n\t"    // 把 regs->sp（0x7fff000）写到 SP_EL0
   // "eret\n"                 // 一条指令跳到 EL0 执行用户态
    :
    : "r"(regs->pc), "r"(regs->pstate), "r"(regs->sp)
    : "memory"
);


   //__asm__ volatile("eret\n\t");
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



