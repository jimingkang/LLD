#include "process.h"
#include "memory.h"
#include "debug.h"
#include "stddef.h"


struct Process *current = NULL;

extern uint64_t kernel_pgd;   // 进程默认用的内核页表根（注意：这是 VA 还是 PA 看你怎么用）

static struct Process process_table[NUM_PROC];
static int pid_num = 1;
static struct ProcessControl pc;
void pstart(struct TrapFrame *tf);

struct ProcessControl* get_pc(void)
{
    return &pc;
}

static struct Process* find_unused_process(void)
{
    struct Process *process = NULL;

    for (int i = 0; i < NUM_PROC; i++) {
        if (process_table[i].state == PROC_UNUSED) {
            process = &process_table[i];
            break;
        }
    }

    return process;
}
 void idle_thread(void)
{
  
    for (;;) {
        printk("idle_thread\r\n");
       schedule();     // 有 ready 进程就切走
    }
}

 void init_idle_process(void)
{
    struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process = find_unused_process();
    ASSERT(process == &process_table[0]);

    process->state = PROC_RUNNING;
    process->pid = 0;
    //process->page_map = P2V(read_pgd());
    
    // 1. 给 idle 分配 kernel stack
    process->stack = (uint64_t)kalloc();
    ASSERT(process->stack != 0);
    memset((void*)process->stack, 0, PAGE_SIZE);

    // 2. 构造 kernel context (x19..x30)
    process->context =process->stack + PAGE_SIZE - sizeof(struct TrapFrame) - 12*8;
    //process->context =process->stack + PAGE_SIZE - 12*8;

    // 3. 第一次调度进来时从 idle_thread 开始执行
    *(uint64_t*)(process->context + 11*8) = (uint64_t)idle_thread;

    // 4. trapframe（可选，但推荐）
    process->tf = (struct TrapFrame*)(process->stack + PAGE_SIZE - sizeof(struct TrapFrame));
   memset(process->tf, 0, sizeof(*process->tf));

    // 5. idle 使用 kernel 页表（不要 read_pgd）
    process->page_map = kernel_pgd;
   
  

    process_control = get_pc();
    process_control->current_process = process;
    //printk("idle: stack=%x tf=%x ctx=%x lr(slot)=%x pgd=%x\n",process->stack,(uint64_t)process->tf,process->context,*(uint64_t*)(process->context + 88),process->page_map);
   // list = &process_control->ready_list;
   // process->state = PROC_READY;
   // append_list_tail(list, (struct List*)process);
}

static struct Process* alloc_new_process(void)
{
    struct Process *process;

    process = find_unused_process();
    ASSERT(process == &process_table[1]);

    process->stack = (uint64_t)kalloc();
    ASSERT(process->stack != 0);
    memset((void*)process->stack, 0, PAGE_SIZE);

    process->state = PROC_INIT;
    process->pid = pid_num++;

    process->context = process->stack + PAGE_SIZE - sizeof(struct TrapFrame) - 12*8;
    *(uint64_t*)(process->context + 11*8) = (uint64_t)trap_return;
    process->tf = (struct TrapFrame*)(process->stack + PAGE_SIZE - sizeof(struct TrapFrame));
    process->tf->elr = 0x400000;
    process->tf->sp0 = 0x400000 + PAGE_SIZE;
    process->tf->spsr = 0;

    process->page_map = (uint64_t)kalloc();
    ASSERT(process->page_map != 0);
    memset((void*)process->page_map, 0, PAGE_SIZE);

    return process;
}

static void init_user_process(void)
{
    struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process = alloc_new_process();
    ASSERT(process != NULL);

    ASSERT(setup_uvm((uint64_t)process->page_map, "init.bin"));

    process_control = get_pc();
    list = &process_control->ready_list;

    process->state = PROC_READY;
    append_list_tail(list, (struct List*)process);
}

static struct Process* alloc_new_process2(void (*fn)(void))
{
    struct Process *process;

    process = find_unused_process();
    ASSERT(process != NULL);

    // kernel stack
    process->stack = (uint64_t)kalloc();
    ASSERT(process->stack != 0);
    memset((void*)process->stack, 0, PAGE_SIZE);

    process->state = PROC_INIT;
    process->pid = pid_num++;

    /*
     * kernel context:
     * x19..x30 (12 regs)
     */
    process->context =
        process->stack + PAGE_SIZE - sizeof(struct TrapFrame) - 12*8;

    // return to trap_return when scheduled first time
    *(uint64_t*)(process->context + 11*8) = (uint64_t)fn;

    // kernel trapframe
    process->tf =(struct TrapFrame*)(process->stack + PAGE_SIZE - sizeof(struct TrapFrame));

    memset(process->tf, 0, sizeof(*process->tf));

    /*
     * IMPORTANT:
     * Do NOT setup user ELR/SP here.
     * This is still kernel thread.
     */


    // kernel page table for now
    process->page_map = kernel_pgd;

    return process;
}
static void create_kernel_process(void (*fn)(void))
{
    struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process = alloc_new_process2(fn);
    ASSERT(process != NULL);

   // ASSERT(setup_uvm((uint64_t)process->page_map, "init.bin"));

    process_control = get_pc();
    list = &process_control->ready_list;

    process->state = PROC_READY;
    append_list_tail(list, (struct List*)process);
    printk("user1: stack=%x tf=%x ctx=%x pgd=%x\n", 
       process->stack, (uint64_t)process->tf, process->context, process->page_map);
}


static inline void set_ttbr0(uint64_t pgd_va)
{
    uint64_t pgd_pa = V2P(pgd_va);
    __asm__ volatile(
        "dsb ish\n"
        "msr ttbr0_el1, %0\n"
        "    tlbi vmalle1is\n"
            "dsb ish\n"
        "isb\n"
        :
        : "r"(pgd_pa)
        : "memory"
    );
}


void move_to_user_mode(struct Process *p)
{
      struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *list;
    p->page_map = (uint64_t)kalloc();
    memset((void*)p->page_map, 0, PAGE_SIZE);

    uint64_t stack_top = p->stack + PAGE_SIZE;
    p->tf = (struct TrapFrame *)(stack_top - sizeof(struct TrapFrame));
    memset(p->tf, 0, sizeof(*p->tf));
    p->tf->elr  = 0x400000;
    p->tf->sp0  = 0x400000 + PAGE_SIZE;
    p->tf->spsr = 0;


  

    ASSERT(setup_uvm(p->page_map, NULL));
set_ttbr0(p->page_map);
  
    // 5) 让该进程下一次被调度时走 trap_return -> eret
   // *(uint64_t*)(p->context + 11*8) = (uint64_t)trap_return;

    // 6) 触发调度，让 swap 生效，从 trap_return 进入 EL0
  //  printk("kthread1 before schedule: pid=%d, tf=%x elr=%x sp0=%x ctx=%x lr=%x\n",(unsigned int)p->pid, (uint64_t)p->tf, p->tf->elr, p->tf->sp0,p->context,*(uint64_t*)(p->context + 11*8));
   enter_user(p->tf);
    //p->state = PROC_READY;
    //process_control = get_pc();
    //list = &process_control->ready_list;
   // append_list_tail(list, (struct List*)p);

    //yield();

//struct Process *prev = current;
//current = p;
//switch_process(prev, p);  


}



void kthread1(void)
{
    printk("kthread1 start\n");

    move_to_user_mode(get_pc()->current_process);

     //printk("kthread1 back to kernel\n");
 

    // 永远不会再回来
    //while (1);
}
void init_process(void)
{
    init_idle_process();
    create_kernel_process(kthread1);
   //init_user_process();
}

 void switch_process(struct Process *prev, struct Process *current)
{
   // printk("new current :id=%d, stack=%x ctx=%x pgd=%x\n", current->pid, current->stack, current->context, current->page_map);

    switch_vm(current->page_map);
  //  printk("before swap: prev pid=%d ,prev->context=%x next pid=%d next->context=%x\n",prev->pid, prev->context,current->pid, current->context);
    swap(&prev->context, current->context);
  //  printk("after swap: prev pid=%d prev->context=%x\n", prev->pid, prev->context);
}

 void schedule(void)
{
    struct Process *prev_proc;
    struct Process *current_proc;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process_control = get_pc();
    list = &process_control->ready_list;
    prev_proc = process_control->current_process;

    if (is_list_empty(list)) {
        current_proc = &process_table[0];
    }
    else {
        current_proc = (struct Process*)remove_list_head(list);
    }

    current_proc->state = PROC_RUNNING;
    process_control->current_process = current_proc;




    switch_process(prev_proc, current_proc);
}
/*1
高地址
+------------------------------+  stack + PAGE_SIZE
|        TrapFrame             |  ← 固定位置
+------------------------------+
|        context               |  ← 紧挨着 TrapFrame
+------------------------------+
|                              |
|      内核栈运行区             |  ← sp 初始在这里(向低地址增长)
|                              |
+------------------------------+  stack
低地址*/
void yield(void)
{
    struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process_control = get_pc();
    list = &process_control->ready_list;

    if (is_list_empty(list)) {
        return;
    }

    process = process_control->current_process;
    process->state = PROC_READY;

    if (process->pid != 0) {
        append_list_tail(list, (struct List*)process);
    }

    schedule();
}
void sleep(int wait)
{
    struct Process *process;
    struct ProcessControl *process_control;

    process_control = get_pc();
    process = process_control->current_process;
    process->state = PROC_SLEEP;
    process->wait = wait;

    append_list_tail(&process_control->wait_list, (struct List*)process);
    schedule();
}

void wake_up(int wait)
{
    struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *ready_list;
    struct HeadList *wait_list;

    process_control = get_pc();
    ready_list = &process_control->ready_list;
    wait_list = &process_control->wait_list;

    process = (struct Process*)remove_list(wait_list, wait);

    while (process != NULL) {
        process->state = PROC_READY;
        append_list_tail(ready_list, (struct List*)process);
        process = (struct Process*)remove_list(wait_list, wait);
    }
}

void exit(void)
{
    struct Process *process;
    struct ProcessControl *process_control;

    process_control = get_pc();
    process = process_control->current_process;
    process->state = PROC_KILLED;
    process->wait = process->pid;

    append_list_tail(&process_control->kill_list, (struct List*)process);

    wake_up(-3);
    schedule();
}

void wait(int pid)
{
    struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process_control = get_pc();
    list = &process_control->kill_list;

    while (1) {
        if (!is_list_empty(list)) {
            process = (struct Process*)remove_list(list, pid);
            if (process != NULL) {
                ASSERT(process->state == PROC_KILLED);
                kfree(process->stack);
                free_vm(process->page_map);
                memset(process, 0, sizeof(struct Process));
                break;
            }
        }

        sleep(-3);
    }
}