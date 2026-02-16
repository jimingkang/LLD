#ifndef _SCHED_H
#define _SCHED_H

#include "mem.h"


#define CORE_CONTEXT_OFFSET 0
#define THREAD_CPU_CONTEXT			0 		// offset of cpu_context in task_struct 
#ifndef __ASSEMBLER__
#define THREAD_SIZE				4096
#define NR_TASKS				64
#define FIRST_TASK task[0]
#define LAST_TASK task[NR_TASKS-1]
#define TASK_RUNNING				0
#define TASK_ZOMBIE				1
#define PF_KTHREAD		            	0x00000002
#define MAX_PROCESS_PAGES			2048	
#define TASK_RUNNING      0
#define TASK_ZOMBIE       1
#define MAX_PAGE_COUNT    16

extern struct task_struct *current;
extern struct task_struct * task[NR_TASKS];
extern int nr_tasks;


/*

struct core_context
{
    u64 x19;
    u64 x20;
    u64 x21;
    u64 x22;
    u64 x23;
    u64 x24;
    u64 x25;
    u64 x26;
    u64 x27;
    u64 x28;
    u64 fp;
    u64 sp;
    u64 lr;
};

struct user_page
{
    u64 pa;
    u64 uva;
};

struct mm_struct
{
    u64 pgd;
    struct user_page user_pages[MAX_PAGE_COUNT];
    u64 kernel_pages[MAX_PAGE_COUNT];
		int user_pages_count;
	int kernel_pages_count;
};

struct task_struct
{
    struct core_context core_context;
    long state;
    long counter;
    long priority;
    long preempt_count;
    u64 flags;
    struct mm_struct mm;
	unsigned long stack; 
};
*/

/**/
struct cpu_context {
	unsigned long x19;
	unsigned long x20;
	unsigned long x21;
	unsigned long x22;
	unsigned long x23;
	unsigned long x24;
	unsigned long x25;
	unsigned long x26;
	unsigned long x27;
	unsigned long x28;
	unsigned long fp;
	unsigned long sp;
	unsigned long pc;
};


struct user_page {
	unsigned long pa;
	unsigned long uva;
};

struct mm_struct {
	unsigned long pgd;
	int user_pages_count;
	struct user_page user_pages[MAX_PROCESS_PAGES];
	int kernel_pages_count;
	unsigned long kernel_pages[MAX_PROCESS_PAGES];
};
struct task_struct {
	struct cpu_context cpu_context;
	unsigned long stack; 
	long state;	
	long counter;
	long priority;
	long preempt_count;
	unsigned long flags;
	struct mm_struct *mm;

};

extern void sched_init(void);
extern void schedule(void);
extern void timer_tick(void);
extern void preempt_disable(void);
extern void preempt_enable(void);
extern void switch_to(struct task_struct* next);
extern void cpu_switch_to(struct task_struct* prev, struct task_struct* next);
extern void schedule(void);
 void schedule_tail(void);
#define INIT_TASK \
/*cpu_context*/	{ {0,0,0,0,0,0,0,0,0,0,0,0,0}, \
/* state etc */	0,0,1, 0 \
}



#endif
#endif