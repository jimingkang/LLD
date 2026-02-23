#ifndef _PROCESS_H
#define _PROCESS_H

#include "handler.h"
#include "file.h"
#include "lib.h"

struct Process {
	struct List *next;
    int pid;
	int state;
		int wait;
	uint64_t context;
	uint64_t page_map;
	uint64_t stack;
	struct TrapFrame *tf;
};

struct ProcessControl {
	struct Process *current_process;
	struct HeadList ready_list;

	struct HeadList wait_list;
	struct HeadList kill_list;
};

#define STACK_SIZE (2*1024*1024)
#define NUM_PROC 10
#define PROC_UNUSED 0
#define PROC_INIT 1
#define PROC_RUNNING 2
#define PROC_READY 3
#define PROC_SLEEP 4
#define PROC_KILLED 5

void init_process(void);
struct ProcessControl* get_pc(void);
void yield(void);
void swap(uint64_t *prev, uint64_t next);
void trap_return(void);
void sleep(int wait);
void wake_up(int wait);
void exit(void);
void wait(int pid);
extern void ret_from_fork(void);
extern struct Process *current;

extern void enter_user(struct TrapFrame *tf) __attribute__((noreturn));


#endif

/*内核全局内存（例如 .bss / .data）

process_table[]:
┌────────────────────────┐
│ struct Process (pid=0) │
├────────────────────────┤
│ struct Process (pid=1) │
├────────────────────────┤
│ struct Process (pid=2) │ ← 你现在的
│   - pid                │
│   - state              │
│   - wait               │
│   - context = 0x2F3FFD50 ◄──────┐
│   - page_map            │       │
│   - stack               │       │
│   - tf                  │       │
└────────────────────────┘       │
                                 │
                                 ▼
								 
*/

/*pid=2 的 kernel stack（2MB）

0xFFFF00002F400000  ← stack top
┌──────────────────────────┐
│ TrapFrame                │
├──────────────────────────┤
│ sys / handler / sleep    │
├──────────────────────────┤
│ schedule                 │
├──────────────────────────┤
│ Context  (size 0x60) ◄───┘
├──────────────────────────┤
│ 运行栈（sp 在这里动）     │
└──────────────────────────┘
0xFFFF00002F200000  ← stack base*/


/*返回用户态后，调用 sleepu() 进入内核态，执行 sync_handler->handler->sys_call->sys_sleep() -> sleep() -> schedule() -> swap() -> idle_thread() -> schedule() -> swap() -> trap_return() -> eret 进入用户态
过程:
#0  schedule      fp=0xFFFF00002F3FFD90  lr=0xFFFF00000008BBF4
#1  sleep         fp=0xFFFF00002F3FFDD0  lr=0xFFFF00000008BCD0
#2  sys_sleep     fp=0xFFFF00002F3FFE00  lr=0xFFFF00000008BEF4
#3  sys_call      fp=0xFFFF00002F3FFE30  lr=0xFFFF00000008BFD C
#4  handler (C)   fp=0xFFFF00002F3FFE70  lr=0xFFFF000000081D44
#5  sync_handler  fp=0xFFFF00002F3FFEB0  lr=0xFFFF000000081864
#6  user          fp=0x00000000005FFFE0  lr=0x0000000000400004




高地址
0xFFFF00002F400000
│
│  ┌──────────────────────────────────────────────┐
│  │ TrapFrame (size = 0x120)                      │
│  │ tf = 0xFFFF00002F3FFEE0                       │
│  │  - elr = 0x400004 (user pc)                   │
│  │  - spsr / esr / sp0 / regs...                 │
│  └──────────────────────────────────────────────┘
│  ┌──────────────────────────────────────────────┐
│  │ sync_handler() （汇编异常入口）              │
│  │ fp = 0xFFFF00002F3FFEB0                      │
│  │ lr = 0xFFFF000000081864                      │
│  └──────────────────────────────────────────────┘
│  ┌──────────────────────────────────────────────┐
│  │ handler()   （C 异常分发）                   │
│  │ fp = 0xFFFF00002F3FFE70                      │
│  │ lr = 0xFFFF000000081D44                      │
│  └──────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────┐
│  │ sys_call()                                   │
│  │ fp = 0xFFFF00002F3FFE30                      │
│  │ lr = 0xFFFF00000008BFDC                      │
│  └──────────────────────────────────────────────┘
│  ┌──────────────────────────────────────────────┐
│  │ sys_sleep()                                  │
│  │ fp = 0xFFFF00002F3FFE00                      │
│  │ lr = 0xFFFF00000008BEF4                      │
│  └──────────────────────────────────────────────┘

│
│  ┌──────────────────────────────────────────────┐
│  │ sleep()                                      │
│  │ fp = 0xFFFF00002F3FFDD0                      │
│  │ lr = 0xFFFF00000008BCD0                      │
│  └──────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────┐
│  │ schedule()                                   │
│  │ fp = 0xFFFF00002F3FFD90                      │
│  │ lr = 0xFFFF00000008BBF4                      │
│  └──────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────┐
│  │ Context (size = 0x60)                        │
│  │ context = 0xFFFF00002F3FFD50                 │
│  │  - x19 ~ x28                                 │
│  │  - saved fp (x29)                            │
│  │  - saved lr (x30)                            │
│  └──────────────────────────────────────────────┘
│...
低地址
0xFFFF00002F200000
*/

/* pid=0的idle_thread 的内核栈（2MB）
高地址
0xFFFF000030000000  ← stack top
│
│ ┌──────────────────────────────────────────┐
│ │ TrapFrame  (0x120 = 288B)                 │
│ │ addr: 0xFFFF00002FFFFEE0                  │
│ │  elr / spsr / esr / regs …                │
│ └──────────────────────────────────────────┘
│
│ ┌──────────────────────────────────────────┐
│ │ Context  (0x60 = 96B)                     │
│ │ addr: 0xFFFF00002FFFFE80                  │
│ │  x19–x28                                  │
│ │  saved fp = 0x0                           │
│ │  saved lr = 0xFFFF00000008B178            │
│ └──────────────────────────────────────────┘
│
│ ──────────────────────────────────────────
│   ❌ 注意：这里没有为函数调用预留空间
│   sp 不能在这块 stack 上正常生长
│ ──────────────────────────────────────────
│
│
│   （下面这 2MB 实际没有被当作当前栈使用）
│
│
低地址
0xFFFF00002FE00000  ← stack base

boot堆栈
 #0: fp=FFFF00000007FE00H  lr=FFFF00000008BBF4H(yield)
 #1: fp=FFFF00000007FE40H  lr=FFFF00000008BC74H(sleep)
 #2: fp=FFFF00000007FE70H  lr=FFFF000000081D68H(handler)
 #3: fp=FFFF00000007FEA0H  lr=FFFF0000000818D0H(irq_handler)

*/

