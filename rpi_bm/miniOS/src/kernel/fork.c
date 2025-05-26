#include "mm.h"
#include "mem.h"
#include "sched.h"
#include "fork.h"
#include "entry.h"
#include "printf.h"
#define PF_KTHREAD		            	0x00000002
extern pg_dir;
int copy_process_inkernel(unsigned long fn, unsigned long arg)
{
	preempt_disable();
	struct task_struct *p;

	p = (struct task_struct *) get_free_pages(1);
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

	/**/
	unsigned long kernel_stack = allocate_kernel_page(); // 分配内核栈
    if (!kernel_stack) {
        printf("Failed to allocate kernel stack\n\r");
      //  free_kernel_page(page); // 释放已分配的task_struct
        return -1;
    }
	p->stack = kernel_stack; // 所有任务都设置内核栈指针
    printf("Allocated kernel stack at 0x%x\n\r", kernel_stack);

	// 2. 初始化内存管理
    if (clone_flags & PF_KTHREAD) {
        // 内核线程不需要用户页表
        p->mm = 0;
    } else {
        printf("go to else in  copy_process \r\n");
        // 用户进程需要完整的页表
        p->mm = (struct mm_struct *)allocate_kernel_page();
        if (!p->mm)return -1;
        memzero(p->mm,  sizeof(struct mm_struct));
        
        p->mm->pgd = alloc_new_pgd();
        if (!p->mm->pgd)return -1;
        
        // 复制内核映射并初始化用户空间
		 u64 kernel_pgd = kernel_pgd_addr();
		p->mm->pgd = allocate_kernel_page();
 
        //copy_kernel_mappings(p->mm->pgd, kernel_pgd);

       // if (init_user_mappings(p->mm->pgd, 0x0, 0x8000000) != 0)
		//printf("error  init_user_mappings \r\n");
         //   goto user_mapping_fail;
    }


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
		childregs->sp = stack + PAGE_SIZE; 
		p->stack = stack;
		printf("else in copy_process\n\r");
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

/*
int move_to_user_mode(unsigned long start, unsigned long size, unsigned long pc)
{
	struct pt_regs *regs = task_pt_regs(current);
	regs->pstate = PSR_MODE_EL0t;
	regs->pc = pc;
	regs->sp = 2 *  PAGE_SIZE;  
	unsigned long code_page = allocate_user_page(current, 0);
	if (code_page == 0)	{
		return -1;
	}
	memcpy(code_page, start, size);
	set_pgd(current->mm.pgd);
	return 0;
}
*/
static inline bool is_aligned(unsigned long addr, unsigned long align)
{
    return !(addr & (align - 1));
}



int move_to_user_mode(unsigned long start, unsigned long size, unsigned long pc)
{
	
printf(" in move_to_user_mode\n\r");
    
    if (size > PAGE_SIZE || !start || !pc) {
        return -1;
    }
  
    struct pt_regs *regs = task_pt_regs(current);
    
    unsigned long code_page = allocate_user_page(current, pc & PAGE_MASK, PTE_VALID | PTE_USER  );
    if (!code_page) {
        return -1;
    }
    
  
    unsigned long stack_page = allocate_user_page(current, 0, PTE_VALID | PTE_USER | PTE_WRITE|PTE_UXN  ); // User-writable, no execute);
    if (!stack_page) {
        free_page(code_page - VA_START);
        return -1;
    }
    printf(" after  allocate stack_page %x \n\r",stack_page);
 
    memcpy((void*)code_page, (void*)start, size);
     

    regs->pstate = PSR_MODE_EL0t;  
    regs->pc = pc;                
    regs->sp = stack_page + USER_STACK_SIZE; 



	debug_pgd(current->mm->pgd);
    set_pgd(current->mm->pgd);
    return 0;
}
void walk_page_table(unsigned long va, pgd_t *pgd_base) {
    int pgd_idx = PGD_INDEX(va);
    pgd_t pgd_entry = pgd_base[pgd_idx];

    printf("VA: 0x%lx\n", va);
    printf("PGD[%d] @ %p → 0x%lx\n", pgd_idx, &pgd_base[pgd_idx], pgd_val(pgd_entry));
    if (!(pgd_val(pgd_entry) & PTE_VALID)) {
        printf("→ Invalid PGD entry\n");
        return;
    }

    pud_t *pud_base = (pud_t *)__va(pgd_val(pgd_entry) & PAGE_MASK);
    int pud_idx = PUD_INDEX(va);
    pud_t pud_entry = pud_base[pud_idx];

    printf("PUD[%d] @ %p → 0x%lx\n", pud_idx, &pud_base[pud_idx], pud_val(pud_entry));
    if (!(pud_val(pud_entry) & PTE_VALID)) {
        printf("→ Invalid PUD entry\n");
        return;
    }

    pmd_t *pmd_base = (pmd_t *)__va(pud_val(pud_entry) & PAGE_MASK);
    int pmd_idx = PMD_INDEX(va);
    pmd_t pmd_entry = pmd_base[pmd_idx];

    printf("PMD[%d] @ %p → 0x%lx\n", pmd_idx, &pmd_base[pmd_idx], pmd_val(pmd_entry));
    if (!(pmd_val(pmd_entry) & PTE_VALID)) {
        printf("→ Invalid PMD entry\n");
        return;
    }

    pte_t *pte_base = (pte_t *)__va(pmd_val(pmd_entry) & PAGE_MASK);
    int pte_idx = PTE_INDEX(va);
    pte_t pte_entry = pte_base[pte_idx];

    printf("PTE[%d] @ %p → 0x%lx\n", pte_idx, &pte_base[pte_idx], pte_val(pte_entry));
    if (!(pte_val(pte_entry) & PTE_VALID)) {
        printf("→ Invalid PTE entry\n");
        return;
    }

    unsigned long pa = (pte_val(pte_entry) & PAGE_MASK) | (va & 0xFFF);
    printf("→ Mapped to physical address: 0x%lx\n", pa);
}
void print_pte_table(pte_t *pte_base, unsigned long va_base) {
    for (int i = 0; i < 512; i++) {
        unsigned long entry = pte_val(pte_base[i]);
        if (entry & PTE_VALID) {

            unsigned long pa = (entry & PAGE_MASK);
            unsigned long va = va_base + (i << 12);  // 4KB per entry
            printf("PTE[%d] → VA: 0x%x → PA: 0x%x | FLAGS: 0x%x\n",
                   i, va, pa, entry & ~PAGE_MASK);
        } else {
            // Uncomment if you want to print all, including invalid
            // printf("PTE[%03d] → INVALID\n", i);
        }
    }
}


void copy_kernel_mappings(pgd_t *dest_pgd, pgd_t *src_pgd) {
       printf("!src_pgd  %x\r\n",src_pgd);
    if (!dest_pgd || !src_pgd) {
        printf("Invalid PGD pointers\n");
        return;
    }
for (int i = 0; i < 512; i++) {
    printf("src_pgd[%d] = 0x%x\n", i, pgd_val(src_pgd[i]));
}

    // 内核虚拟地址范围（根据实际架构调整）
    unsigned long kernel_start =   0xffffff8000000000;
    unsigned long kernel_end =  VMALLOC_START;  // 避免覆盖用户空间
     //  unsigned long kernel_end = (unsigned long)(-1);

    // 复制内核映射
    for (unsigned long addr = kernel_start; addr < kernel_end; addr += PGDIR_SIZE) {
        int pgd_idx = pgd_index(addr);
        pgd_t pgd = src_pgd[pgd_idx];
        printf("pgd[%d] = 0x%x, present = %d\n", pgd_idx, pgd_val(pgd), pgd_present(pgd));
        if (!pgd_present(pgd)) {
             printf("!pgd_present  %x\r\n",pgd);
            continue;  // 忽略未使用的 PGD 项
        }

        // 复制 PUD
        pud_t *src_pud = pud_offset(&pgd, addr);
        pud_t *dest_pud = (pud_t *)allocate_kernel_page();
        if (!dest_pud) {
            printf("Failed to allocate PUD\n");
            break;
        }
         // printf("succeed to allocate PUD,dest_pud=%x,src_pud=%x\n",dest_pud,src_pud);
        memcpy(dest_pud, src_pud, PAGE_SIZE);

        // 设置新的 PGD 项
        dest_pgd[pgd_idx] = __pgd(__pa(dest_pud) | PGD_TYPE_TABLE);

        // 遍历 PUD 复制 PMD/PTE 并设置权限
        for (int pud_idx = 0; pud_idx < 512; pud_idx++) {
            pud_t pud = dest_pud[pud_idx];
            if (!pud_present(pud)) {
                continue;
            }

            // 复制 PMD
            pmd_t *src_pmd = pmd_offset(&pud, 0);
            pmd_t *dest_pmd = (pmd_t *)allocate_kernel_page();
            //printf("succeed to allocate PMD,dest_pmd=%x,src_pmd=%x\n",dest_pmd,src_pmd);
            memcpy(dest_pmd, src_pmd, PAGE_SIZE);
            dest_pud[pud_idx] = __pud(__pa(dest_pmd) | PUD_TYPE_TABLE);

            // 遍历 PMD 复制 PTE 并设置权限
            for (int pmd_idx = 0; pmd_idx < 512; pmd_idx++) {
                pmd_t pmd = dest_pmd[pmd_idx];
                if (!pmd_present(pmd)) {
                    continue;
                }
                 if (!is_pmd_table(pmd)) {
        //printf("Skip pmd_idx=%d: not a table entry (value=0x%lx)\n", pmd_idx, pmd_val(pmd));
        continue;
    }
               

                // 复制 PTE
                pte_t *src_pte = pte_offset_kernel(&pmd, 0);
                pte_t *dest_pte = (pte_t *)allocate_kernel_page();
                  printf("succeed to allocate pte,pmd_idx=%d,dest_pte=%x,src_pte=%x\n",pmd_idx,dest_pte,src_pte);
                memcpy(dest_pte, src_pte, PAGE_SIZE);
                dest_pmd[pmd_idx] = __pmd(__pa(dest_pte) | PMD_TYPE_TABLE);
                if (!src_pte) {
                    printf("src_pte is NULL at pmd_idx=%d, skip\n", pmd_idx);
                    
                    continue;
                }
                 for (int i = 0; i < PTRS_PER_PTE; i++) {
                    if (pte_valid(src_pte[i])) {
                         dest_pte[i] = src_pte[i];  // 直接复制表项，不拷贝物理页
                           unsigned long va = ((pmd_idx << 21) | (i << 12));  // PMD idx + PTE idx → VA（低位段）
            unsigned long pa = pte_val(src_pte[i]) & PAGE_MASK;
            unsigned long flags = pte_val(src_pte[i]) & ~PAGE_MASK;
           // if (pmd_idx>503)
            {        printf("PTE copy: VA=0x%x → PA=0x%x | FLAGS=0x%x\n", va, pa, flags);}
    
                       /*   printf("in side pte_valid,dest_pte=%x,src_pte=%x\n",dest_pte,src_pte);
                        // 取出原物理页地址
                        phys_addr_t old_pa = pte_val(src_pte[i]) & PAGE_MASK;

                        // 分配新物理页
                        void *new_page = allocate_user_page();  // 或 allocate_kernel_page()
                        phys_addr_t new_pa = __pa(new_page);
                      printf("before memcpy new_page=%x,old_pa=%x\n",new_page,old_pa);
                        // 拷贝原数据页内容
                        memcpy(new_page, __va(old_pa), PAGE_SIZE);

                        // 写入新 PTE 表项
                        dest_pte[i] =__pte(new_pa | (pte_val(src_pte[i]) & ~PAGE_MASK));// new_pa | (pte_val(src_pte[i]) & ~PAGE_MASK);  // 保留原 flags
                    */ 
                   }
                }




          
            }
        }
    }

    printf("Copied kernel mappings from 0x%lx to 0x%lx\n", (unsigned long)src_pgd, (unsigned long)dest_pgd);
}

void old2_copy_kernel_mappings(pgd_t *dest_pgd,pgd_t *src_pgd) {
	 
    // 分配新的顶级页表
   // pgd_t *new_pgd =dest_pgd;// (pgd_t *)allocate_kernel_page();
    if (!dest_pgd) {
        printf("Failed to allocate new PGD\n\r");
        return 0;
    }
    memzero(dest_pgd, PAGE_SIZE);

    // 内核空间在ARM64中通常使用TTBR1，地址范围从PAGE_OFFSET开始
    unsigned long kernel_start = 0xffffff8000000000;
    //unsigned long kernel_start = 0x80000;
    unsigned long kernel_end = (unsigned long)(-1);

    // 复制内核空间映射
  for (unsigned long addr = kernel_start; addr < kernel_end; addr += PGDIR_SIZE) {
    int pgd_idx = pgd_index(addr);
    pgd_t pgd = src_pgd[pgd_idx];
     set_pte_ap(pgd, AP_RW_NA);  
    dest_pgd[pgd_idx] = pgd;
    if (!pgd_present(pgd)) continue;

    // 分配下级页表并复制内容
    pud_t *src_pud = pud_offset(&pgd, addr);
    pud_t *dest_pud = (pud_t *)allocate_kernel_page();
    memcpy(dest_pud, src_pud, PAGE_SIZE);
    
    // 设置新的 PGD 项指向复制的 PUD
    dest_pgd[pgd_idx] = __pgd(__pa(dest_pud) | PGD_TYPE_TABLE);
}

 printf("enter copy_kernel_mappings\n\r");
    // 复制固定映射区域（如设备映射）
    // 这里需要根据你的具体架构添加

    printf("Copied kernel mappings from 0x%x to 0x%x\n\r", (unsigned long)src_pgd, (unsigned long)dest_pgd);
    return ;
}

void debug_pgd(pgd_t *pgd) {
    for (int i = 0; i < 5; i++) { // 打印前5项
        printf("pgd[%d] = 0x%x\n", i, pgd[i]);
    }
}



struct pt_regs * task_pt_regs(struct task_struct *tsk){
	unsigned long p = (unsigned long)tsk->stack + THREAD_SIZE - sizeof(struct pt_regs);
	return (struct pt_regs *)p;
}

