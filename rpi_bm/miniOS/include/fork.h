#ifndef _FORK_H
#define _FORK_H
#include "mem.h"
struct pt_regs {
	unsigned long regs[31];
	unsigned long sp;
	unsigned long pc;
	unsigned long pstate;
};
#define PSR_MODE_EL0t	0x00000000
#define PSR_MODE_EL1t	0x00000004
#define PSR_MODE_EL1h	0x00000005
#define PSR_MODE_EL2t	0x00000008
#define PSR_MODE_EL2h	0x00000009
#define PSR_MODE_EL3t	0x0000000c
#define PSR_MODE_EL3h	0x0000000d

int copy_process(unsigned long clone_flags, unsigned long fn, unsigned long arg, unsigned long stack);
int move_to_user_mode(unsigned long start, unsigned long size, unsigned long pc);
struct pt_regs * task_pt_regs(struct task_struct *tsk);

int copy_process_inkernel(unsigned long fn, unsigned long arg);
void copy_kernel_mappings(pgd_t *dest_pgd,pgd_t *src_pgd);


#endif