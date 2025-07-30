#ifndef _FORK_H
#define _FORK_H
#include "mem.h"


#include "types.h"
#include "sched.h"

#define UTHREAD 0
#define KTHREAD 1

//int copy_process(u64 clone_flags, u64 fn, u64 arg);
int prepare_move_to_user(u64 start_addr, u64 size, u64 fn);
struct ke_regs * task_ke_regs(struct task_struct *tsk);

/* kernel entry/exit regs */
struct ke_regs
{
    u64 regs[31];
    u64 sp;
    u64 elr;
    u64 pstate;
};



struct pt_regs {
	unsigned long regs[31];
	unsigned long sp;    //sp_el0
	unsigned long pc; //elr_el1
	unsigned long pstate;  //spsr_el1
} ;
#define PSR_MODE_EL0t	0x00000000
#define PSR_MODE_EL1t	0x00000004
#define PSR_MODE_EL1h	0x00000005
#define PSR_MODE_EL2t	0x00000008
#define PSR_MODE_EL2h	0x00000009
#define PSR_MODE_EL3t	0x0000000c
#define PSR_MODE_EL3h	0x0000000d

#define PSR_DAIF_MASK    (0xFUL << 6)      // DAIF = 1111b → 屏蔽 Debug/A/IRQ/FIQ

int copy_process(unsigned long clone_flags, unsigned long fn, unsigned long arg, unsigned long stack);
int move_to_user_mode(unsigned long start, unsigned long size, unsigned long pc);
struct pt_regs * task_pt_regs(struct task_struct *tsk);

int copy_process_inkernel(unsigned long fn, unsigned long arg);
void copy_kernel_mappings(pgd_t *dest_pgd,pgd_t *src_pgd);
int move_to_user_mode_fixed(unsigned long start, unsigned long size, unsigned long pc);
//unsigned long map_and_copy_user_code(   unsigned long src_va_begin, size_t  code_size );
unsigned long map_and_copy_user_code(void);
void walk_page_table(uint64_t table_phys, int level, uint64_t base_va);
void dump_pagetable_walk(uint64_t pgd_phys, uint64_t va);	
#endif