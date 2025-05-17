#include "mm.h"
#include "mem.h"
#include "sched.h"
#include "fork.h"
#include "entry.h"
#include "printf.h"

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
	preempt_disable();
	struct task_struct *p;

	p = (struct task_struct *) get_free_pages(1);
	if (!p) {
		printf("Error while get_free_pages in copy_process\n\r");
		return -1;
	}

	struct pt_regs *childregs = task_pt_regs(p);
	memzero((unsigned long)childregs, sizeof(struct pt_regs));
	memzero((unsigned long)&p->cpu_context, sizeof(struct cpu_context));

	if (clone_flags & PF_KTHREAD) {
		p->cpu_context.x19 = fn;
		p->cpu_context.x20 = arg;

	} else {
		struct pt_regs * cur_regs = task_pt_regs(current);
		*childregs=	*cur_regs; 	
		childregs->regs[0] = 0;
		childregs->sp = stack + PAGE_SIZE; 
		p->stack = stack;
		// p->cpu_context.x19 = 0;  // ✅ 关键点：让 ret_from_fork 进入 ret_to_user
   // p->cpu_context.x20 = 0;
	}
	p->flags = clone_flags;
	p->priority = current->priority;
	p->state = TASK_RUNNING;
	p->counter = p->priority;
	p->preempt_count = 1; //disable preemtion until schedule_tail

	p->cpu_context.pc = (unsigned long)ret_from_fork;
	p->cpu_context.sp = (unsigned long)childregs;
	int pid = nr_tasks++;
	task[pid] = p;	
	preempt_enable();


	return pid;
}

int move_to_user_mode(unsigned long pc)
{
	struct pt_regs *regs = task_pt_regs(current);
	memzero((unsigned long)regs, sizeof(*regs));
	regs->pc = pc;
	regs->pstate = PSR_MODE_EL0t;

	unsigned long phys_stack = get_free_pages(1); // 分配物理页
	if (!phys_stack) {
		printf("Error while get_free_pages in move_to_user_mode\n\r");
		return -1;
	}
	
	printf("user_process = 0x%x\n", pc);

	 printf("phys_stack %x\r\n ",phys_stack);
	//map_user_page(USER_STACK_TOP, phys_stack, PTE_USER_RW_FLAGS);

	// 设置用户态 SP 寄存器（虚拟地址）
	regs->sp =USER_STACK_TOP+PAGE_SIZE;// USER_STACK_TOP;
	current->stack = phys_stack;
	current->flags &= ~PF_KTHREAD;
    printf("EL1 → EL0 prepare: pc=0x%lx sp=0x%lx pstate=0x%lx\n", regs->pc, regs->sp, regs->pstate);
	return 0;
}

int old_move_to_user_mode(unsigned long pc)
{
	struct pt_regs *regs = task_pt_regs(current);
	memzero((unsigned long)regs, sizeof(*regs));
	regs->pc = pc;
	regs->pstate = PSR_MODE_EL0t;
	unsigned long stack = get_free_pages(1); //alocate new user stack
	if (!stack) {
		printf("Error while get_free_pages in move_to_user_mode\n\r");
		return -1;
	}
	regs->sp = stack + PAGE_SIZE; 
	current->stack = stack;
	return 0;
}

struct pt_regs * task_pt_regs(struct task_struct *tsk){
	unsigned long p = (unsigned long)tsk + THREAD_SIZE - sizeof(struct pt_regs);
	return (struct pt_regs *)p;
}