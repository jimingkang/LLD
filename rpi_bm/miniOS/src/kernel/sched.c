#include "sched.h"
#include "irq.h"
#include "printf.h"

static struct task_struct init_task = INIT_TASK;
struct task_struct *current = &(init_task);
struct task_struct * task[NR_TASKS] = {&(init_task), };
int nr_tasks = 1;

void preempt_disable(void)
{
	current->preempt_count++;
}

void preempt_enable(void)
{
	current->preempt_count--;
}


void _schedule(void)
{
	printf("enter _schedule\n\r");
	preempt_disable();
	int next,c;
	struct task_struct * p;
	while (1) {
		printf("while _schedule\n\r");
		c = -1;
		next = 0;
		for (int i = 0; i < NR_TASKS; i++){
			p = task[i];
			if (p && p->state == TASK_RUNNING && p->counter > c) {
				c = p->counter;
				next = i;
			}
		}
		if (c) {
			break;
		}
		for (int i = 0; i < NR_TASKS; i++) {
			p = task[i];
			
			if (p) {
				
			printf("task[%d]: state=%d, counter=%d\n\r", i, p->state, p->counter);
	
				p->counter = (p->counter >> 1) + p->priority+1;
			}
		}
		printf("quit while _schedule,next=%x\n\r",next);
	}
	printf("return from _schedule. next=%x,task=%x\r\n",next,task[next]);
	switch_to(task[next]);
	preempt_enable();
}

void schedule(void)
{
	current->counter = 0;
	_schedule();
}

void switch_to(struct task_struct * next) 
{
	if (current == next) 
		return;
	struct task_struct * prev = current;
	current = next;
	cpu_switch_to(prev, next);
}

void schedule_tail(void) {
	preempt_enable();
}


void timer_tick()
{
	--current->counter;
	if (current->counter>0 || current->preempt_count >0) {
		return;
	}
	current->counter=0;
	irq_enable();
	_schedule();
	irq_disable();
}

/*void ret_from_fork() {
    	preempt_enable();
    // 通常是调用 x19 作为函数指针，x20 作为参数
    ((void (*)(unsigned long))current->cpu_context.x19)(current->cpu_context.x20);
    // 最后应该调用 exit 结束任务（非此文件范围）
}
*/
void __ret_from_kernel_thread(void) {
    int (*fn)(void *) = (void *)current->cpu_context.x19;
    void *arg = (void *)current->cpu_context.x20;
    
    int ret = fn(arg);
    do_exit(ret);
}
void do_exit(int error_code) {
    struct task_struct *tsk = current;
    
    // Mark task as zombie
    tsk->state = TASK_ZOMBIE;
    
    // Free resources
    if (tsk->stack && !(tsk->flags & PF_KTHREAD)) {
      //  free_pages(tsk->stack, 1);
    }
    
    // Schedule other tasks
    schedule();
    
    // Should never reach here
    //panic("Zombie task scheduled!\n");
}

void exit_process(){
	preempt_disable();
	for (int i = 0; i < NR_TASKS; i++){
		if (task[i] == current) {
			task[i]->state = TASK_ZOMBIE;
			break;
		}
	}
	if (current->stack) {
		free_page(current->stack);
	}
	preempt_enable();
	schedule();
}