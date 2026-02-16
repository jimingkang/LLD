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



extern char user_begin[];       // 由 linker.ld 导出
extern char user_data_begin[];  // 放在 .user.rodata 后面
//extern char user_start[];       // 用户入口符号


/* 你已有：页表切换、TLBI、cache 维护等原语 */
static inline void cache_sync_exec_region(unsigned long dst_pa, void* dst_va, size_t size_bytes) {
    /* D-cache clean by PA to PoC */
    for (unsigned long pa = dst_pa; pa < dst_pa + size_bytes; pa += 64)
        asm volatile("dc cvac, %0" :: "r"(pa) : "memory");
    asm volatile("dsb sy" ::: "memory");
    /* I-cache invalidate by VA to PoU */
    for (unsigned long va = (unsigned long)dst_va; va < (unsigned long)dst_va + size_bytes; va += 64)
        asm volatile("ic ivau, %0" :: "r"(va) : "memory");
    asm volatile("dsb ish; isb" ::: "memory");
}

static inline u64 pa_from_desc(u64 d) { return d & ~0xFFFULL; }

void walk_and_dump(struct mm_struct *mm, u64 va) {
    u64 *l0 = mm->pgd;                           // KVA！
    u64 i0 = (va >> 39) & 0x1ff, d0 = l0[i0];
    printf("L0[%u]=0x%x\n", i0, d0);

    u64 *l1 = (u64 *)__va(pa_from_desc(d0));
    u64 i1 = (va >> 30) & 0x1ff, d1 = l1[i1];
    printf("L1[%u]=0x%x\n", i1, d1);

    u64 *l2 = (u64 *)__va(pa_from_desc(d1));
    u64 i2 = (va >> 21) & 0x1ff, d2 = l2[i2];
    printf("L2[%u]=0x%0x  (UXNTable=%u PXNTable=%u)\n",
           i2, d2, (d2>>60)&1, (d2>>59)&1);

    // 如果 d2 是 Table 描述符 (bits[1:0]==11)，继续到 L3
    if ((d2 & 3) == 3) {
        u64 *l3 = (u64 *)__va(pa_from_desc(d2));
        u64 i3 = (va >> 12) & 0x1ff, d3 = l3[i3];
        printf("L3[%u]=0x%x  (UXN=%u PXN=%u AP=%u AttrIdx=%u)\n",
               i3, d3, (d3>>54)&1, (d3>>53)&1, (d3>>6)&3, (d3>>2)&7);
    } else {
        printf("L2 entry is **BLOCK or INVALID**, not a table!\n");
    }
}

/* 把 [user_begin, user_data_begin) 拷贝到 USER_CODE_BASE 起的一串用户页 */
int map_and_copy_user_segment(struct task_struct *p, unsigned long *entry_va_out)
{
    printf("map_and_copy_user_segment");
    unsigned long src_va_begin = (unsigned long)user_begin;
    unsigned long src_va_end   = (unsigned long)user_data_begin; // 覆盖 .user.text + .user.rodata
    unsigned long seg_sz = src_va_end - src_va_begin;
        printf("p=%x,src_va_begin=%x,src_va_end=%x,seg_sz=%x,*(uint32_t*)src_va_begin=%x\n\r",p,src_va_begin,src_va_end,seg_sz,*(uint32_t*)src_va_begin);
    if (seg_sz == 0) return -1;

    unsigned long dst_base_va = USER_CODE_BASE;
    size_t        off         = 0;

    while (off < seg_sz) {
        size_t   chunk = PAGE_SIZE;
        unsigned long va = dst_base_va + off;
                printf("allocate_user_page\n\r");
        unsigned long pa = allocate_user_page(p, va,USER_FLAGS_CODE ); //USER_CODE_FLAGS
        //walk_and_dump(p->mm,va);
        if (!pa) return -2;

        void *dst = __va(pa);
        void *src = (void *)(src_va_begin + off);

        size_t tocpy = (off + chunk <= seg_sz) ? chunk : (seg_sz - off);
        _memcpy(dst, src, tocpy);

        cache_sync_exec_region(pa, dst, tocpy);
        off += chunk;
    }

    /* 计算入口 VA：基址 + 入口相对偏移 */
    unsigned long entry_off = (unsigned long)user_start - (unsigned long)user_begin;
    *entry_va_out = USER_CODE_BASE + entry_off;
    return 0;
}
/* 分配 N 页栈（向下增长），返回用户栈顶 VA */
unsigned long map_user_stack(struct task *p, int pages)
{
    unsigned long top = USER_STACK_TOP;
    for (int i = 1; i <= pages; ++i) {
        unsigned long va = top - i * PAGE_SIZE;   // 向下映射
        unsigned long pa = allocate_user_page(p, va, USER_DATA_FLAGS);
        if (!pa) return 0;
        /* 栈页是数据页，不执行，不需要做 I$ 失效 */
        /* 如需清零栈页：memset(__va(pa), 0, PAGE_SIZE); 并做 D-cache clean */
    }
    return top; // sp_el0 设为 top（空栈）
}

/* 进入用户态的最小桥（你可以把它放到 .S 汇编里） */
static inline void enter_user(unsigned long pc, unsigned long sp, unsigned long ttbr0)
{
    unsigned long spsr = 0x0; /* EL0t，DAIF 全开，按需可屏蔽 I/F：spsr |= (1<<7)|(1<<6) */

    asm volatile(
        "msr ttbr0_el1, %0      \n"
        "dsb ish                 \n"
        "isb                     \n"
        "msr sp_el0,  %1         \n"
        "msr elr_el1, %2         \n"
        "msr spsr_el1, %3        \n"
        "eret                    \n"
        :
        : "r"(ttbr0), "r"(sp), "r"(pc), "r"(spsr)
        : "memory");
}
int fork_user_and_run(void)
{
    struct task_struct *p =0;   // 你的进程/线程结构
  	unsigned long page = allocate_kernel_page();
	printf("allocate_kernel_page in copy_process%x\n\r",page);
	p = (struct task_struct *)page ;
    
    if (!p->mm) {
        p->mm = (struct mm_struct *)allocate_kernel_page();
        if (!p->mm) {
           printf("Failed to allocate mm_struct\n\r");
            return;
       }
        memzero(p->mm, sizeof(struct mm_struct));
      
        // 复制内核映射
        u64 kernel_pgd = kernel_pgd_addr();
        p->mm->pgd = allocate_pagetable_page(); //get_pgd();//
        if (!p->mm->pgd) {
            printf("Failed to copy kernel mappings\n\r");
            return;
        }
        memzero(__va(p->mm->pgd), PAGE_SIZE);

             
       // dump_pgd(kernel_pgd);
        irq_disable(); 
       copy_kernel_mappings(__va(p->mm->pgd),kernel_pgd);
        irq_enable();  
    }

    /* 2) 映射代码段（text+rodata）到 USER_CODE_BASE */
    unsigned long entry_va = 0x400000;
    int rc = map_and_copy_user_segment(p, &entry_va);
    if (rc) return -3;

    /* 3) 建栈 */
    unsigned long user_sp = map_user_stack(p, USER_STACK_PAGES);
    if (!user_sp) return -4;

    /* 4)（可选）.user.data/.user.bss 如有需要同理 map+memset */

    /* 5) 切到用户页表并跳入 EL0 */
    unsigned long ttbr0 = (unsigned long)p->mm->pgd; // 物理地址
    enter_user(entry_va, user_sp, ttbr0);

    __builtin_unreachable();
}


