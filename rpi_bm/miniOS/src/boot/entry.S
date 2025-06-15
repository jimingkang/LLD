#include "entry.h"
#include "sysregs.h"
#include "sys.h"


#define SYNC_ERROR			16 
#define SYSCALL_ERROR			17 
.extern schedule_tail

.macro RET_TO_USER childregs_addr:req
    // childregs_addr 中保存的就是 struct pt_regs *childregs
    // 将 childregs->pstate 写到 SPSR_EL1
    ldr     x0, [\childregs_addr, #offsetof_pt_regs_pstate]
    msr     SPSR_EL1, x0

    // 将 childregs->pc 写到 ELR_EL1
    ldr     x0, [\childregs_addr, #offsetof_pt_regs_pc]
    msr     ELR_EL1, x0

    // 将 childregs->sp 写到 SP_EL0
    ldr     x0, [\childregs_addr, #offsetof_pt_regs_sp]
    msr     SP_EL0, x0

    // 如果需要 restore x0-x30，请自行从 childregs[regs] 里取
    // （此处省略，假设用户程序真的不需要从父进程继承通用寄存器状态）

    eret
.endm

.macro kernel_entry, el
    sub sp, sp, #S_FRAME_SIZE
    stp x0, x1, [sp, #16 * 0]
    stp x2, x3, [sp, #16 * 1]
    stp	x4, x5, [sp, #16 * 2]
	stp	x6, x7, [sp, #16 * 3]
	stp	x8, x9, [sp, #16 * 4]
	stp	x10, x11, [sp, #16 * 5]
	stp	x12, x13, [sp, #16 * 6]
	stp	x14, x15, [sp, #16 * 7]
	stp	x16, x17, [sp, #16 * 8]
	stp	x18, x19, [sp, #16 * 9]
	stp	x20, x21, [sp, #16 * 10]
	stp	x22, x23, [sp, #16 * 11]
	stp	x24, x25, [sp, #16 * 12]
	stp	x26, x27, [sp, #16 * 13]
	stp	x28, x29, [sp, #16 * 14]

		.if	\el == 0
	mrs	x21, sp_el0
	.else
	add	x21, sp, #S_FRAME_SIZE
	.endif /* \el == 0 */

	mrs	x22, elr_el1
	mrs	x23, spsr_el1

	stp	x30, x21, [sp, #16 * 15] 
	stp	x22, x23, [sp, #16 * 16]
	/*
	str	x30, [sp, #16 * 15] 
	mrs x26, elr_el1                 //Jimmy add
    mrs x27, spsr_el1
    stp x26, x27, [sp, #16 * 16]
	*/

.endm

.macro kernel_exit ,el
	ldp	x22, x23, [sp, #16 * 16]
	ldp	x30, x21, [sp, #16 * 15] 

	.if	\el == 0
	msr	sp_el0, x21
	.endif /* \el == 0 */
	msr	elr_el1, x22			
	msr	spsr_el1, x23

    ldp x0, x1, [sp, #16 * 0]
    ldp x2, x3, [sp, #16 * 1]
    ldp	x4, x5, [sp, #16 * 2]
	ldp	x6, x7, [sp, #16 * 3]
	ldp	x8, x9, [sp, #16 * 4]
	ldp	x10, x11, [sp, #16 * 5]
	ldp	x12, x13, [sp, #16 * 6]
	ldp	x14, x15, [sp, #16 * 7]
	ldp	x16, x17, [sp, #16 * 8]
	ldp	x18, x19, [sp, #16 * 9]
	ldp	x20, x21, [sp, #16 * 10]
	ldp	x22, x23, [sp, #16 * 11]
	ldp	x24, x25, [sp, #16 * 12]
	ldp	x26, x27, [sp, #16 * 13]
	ldp	x28, x29, [sp, #16 * 14]
	/*
	ldr	x30, [sp, #16 * 15]    
	     
	ldp x26, x27, [sp, #16 * 16]  //jimmy add
    msr elr_el1, x26
    msr spsr_el1, x27
*/
	add	sp, sp, #S_FRAME_SIZE
	
    eret
.endm

.macro handle_invalid_entry el,  type
	kernel_entry \el
	mov	x0, #\type
	mrs	x1, esr_el1
	mrs	x2, elr_el1
	bl	show_invalid_entry_message
	b	err_hang
.endm

.macro	ventry	label
.align	7
    b	\label
.endm

//Exception vectors table
.align	11
.globl vectors 
vectors:
	ventry	sync_invalid_el1t			// Synchronous EL1t
	ventry	irq_invalid_el1t			// IRQ EL1t
	ventry	fiq_invalid_el1t			// FIQ EL1t
	ventry	error_invalid_el1t			// Error EL1t

	ventry	sync_invalid_el1h			// Synchronous EL1h
	ventry	handle_el1_irq				// IRQ EL1h
	ventry	fiq_invalid_el1h			// FIQ EL1h
	ventry	error_invalid_el1h			// Error EL1h


	ventry	el0_sync				 //ventry	sync_invalid_el0_64			// Synchronous 64-bit EL0
	ventry	el0_irq					//ventry	irq_invalid_el0_64			// IRQ 64-bit EL0
	
	ventry	fiq_invalid_el0_64			// FIQ 64-bit EL0
	ventry	error_invalid_el0_64		// Error 64-bit EL0

	ventry	sync_invalid_el0_32			// Synchronous 32-bit EL0
	ventry	irq_invalid_el0_32			// IRQ 32-bit EL0
	ventry	fiq_invalid_el0_32			// FIQ 32-bit EL0
	ventry	error_invalid_el0_32		// Error 32-bit EL0


sync_invalid_el1t:
	handle_invalid_entry 1,  SYNC_INVALID_EL1t

irq_invalid_el1t:
	handle_invalid_entry 1, IRQ_INVALID_EL1t

fiq_invalid_el1t:
	handle_invalid_entry  1,FIQ_INVALID_EL1t

error_invalid_el1t:
	handle_invalid_entry  1,ERROR_INVALID_EL1t

sync_invalid_el1h:
	handle_invalid_entry  1,SYNC_INVALID_EL1h

fiq_invalid_el1h:
	handle_invalid_entry  1,FIQ_INVALID_EL1h

error_invalid_el1h:
	handle_invalid_entry  1,ERROR_INVALID_EL1h

sync_invalid_el0_64:
	handle_invalid_entry 0, SYNC_INVALID_EL0_64

irq_invalid_el0_64:
	handle_invalid_entry 0, IRQ_INVALID_EL0_64

fiq_invalid_el0_64:
	handle_invalid_entry 0, FIQ_INVALID_EL0_64

error_invalid_el0_64:
	handle_invalid_entry 0,  ERROR_INVALID_EL0_64

sync_invalid_el0_32:
	handle_invalid_entry 0,  SYNC_INVALID_EL0_32

irq_invalid_el0_32:
	handle_invalid_entry 0,  IRQ_INVALID_EL0_32

fiq_invalid_el0_32:
	handle_invalid_entry 0,  FIQ_INVALID_EL0_32

error_invalid_el0_32:
	handle_invalid_entry 0,  ERROR_INVALID_EL0_32

handle_el1_irq:
	kernel_entry 0
	bl	handle_irq
	kernel_exit 0

el0_irq:
	kernel_entry 0
	bl	handle_irq
	kernel_exit 0
el0_sync:
	kernel_entry 0
	mrs	x25, esr_el1				// read the syndrome register
	lsr	x24, x25, #ESR_ELx_EC_SHIFT		// exception class
	cmp	x24, #ESR_ELx_EC_SVC64			// SVC in 64-bit state
	b.eq	el0_svc
	cmp x24, #0x24             // 检查是否为 Data Abort（0b100100）
    b.eq el0_da    // 跳转到缺页处理
	handle_invalid_entry 0, 16





sc_nr	.req	x25					// number of system calls
scno	.req	x26					// syscall number
stbl	.req	x27					// syscall table pointer




el0_svc:
	adr	stbl, sys_call_table			// load syscall table pointer
	uxtw	scno, w8				// syscall number in w8
	mov	sc_nr, #__NR_syscalls
	bl	irq_enable
	cmp     scno, sc_nr                     	// check upper syscall limit
	b.hs	ni_sys

	ldr	x16, [stbl, scno, lsl #3]		// address in the syscall table
	blr	x16					   // call sys_* routine
	b	ret_from_syscall
ni_sys:
	handle_invalid_entry 0, 17



ret_from_syscall:
	bl	irq_disable				
	str	x0, [sp, #S_X0]				// returned x0
	kernel_exit 0

	/*
el0_da:
	bl	irq_enable
	mrs	x0, far_el1
	mrs	x1, esr_el1			
	bl	do_mem_abort
	cmp x0, 0
	b.eq 1f
	handle_invalid_entry 0, DATA_ABORT_ERROR
1:
	bl irq_disable			
	kernel_exit 0

*/
el0_da:
    mrs    x0, far_el1               // 读取 FAR_EL1（缺页地址）
    mov    x1, x25                   // 传递 ESR_EL1（异常原因）
    bl     handle_user_page_fault    // 调用 C 函数处理缺页
    cmp    x0, #0                    // 检查返回值（0=成功）
    b.ne   ret_to_user_error         // 失败则跳转到错误处理
    b      ret_to_user               // 成功则返回用户态

.globl ret_from_fork
ret_from_fork:
	bl	schedule_tail
	cbz	x19, ret_to_user			// not a kernel thread
	ldr x0, =strr_kernel
	bl uart_send_string
	mov	x0, x20
	blr	x19


ret_to_user:
    mov   x0, sp //x29                   // x1 = childregs (pt_regs 的基地址)
	bl dump_pt_regs
    // 从 childregs 中恢复 PC/SP/PSTATE，然后 eret 跳 EL0/EL1
    mov   x1,sp         //# x29                   // x1 = childregs (pt_regs 的基地址)
 	ldr   x0, [x1, #32*8]
    msr   ELR_EL1, x0               // 下一条 eret 会把 PC 设成这里    
    ldr   x0, [x1, #33*8]
    msr   SPSR_EL1, x0              // 下一条 eret 会把 PSTATE 设成这里 
    ldr   x0, [x1, #31*8]
    msr   SP_EL0, x0                // 给 EL0 的栈

	// --------- 2) 刷新所有 Stage-1 TLB (EL1+EL0) ----------
	msr    TTBR0_EL1, x0
    dsb ish
    tlbi vmalle1
    dsb ish
    isb
    eret               
	             // 从 EL1 → EL0，跳到用户入口
	// bl irq_disable
   //kernel_exit 0
//ret_to_user:
 //   kernel_exit                     // 从内核栈恢复用户态寄存器
                                 // 返回用户态
	/* 
	ldr x1, =current
	ldr x1, [x1]         // 获取 current task_struct*
	ldr x1, [x1, #0]     // 假设 pt_regs 在偏移 0
	ldr x2, [x1, #16]    // regs->sp
	ldr x3, [x1, #0]     // regs->pc
	ldr x4, [x1, #24]    // regs->pstate
	msr SP_EL0, x2
	msr ELR_EL1, x3
	msr SPSR_EL1, x4
	eret
	*/



ret_to_user_error:
	ldr x0, =strr_error
	bl uart_send_string
    mov    x0, #-1                  // 设置错误码
    kernel_exit 0

.global ret_from_kernel_thread
ret_from_kernel_thread:
 bl      __ret_from_kernel_thread
//mov     x0, x20              // Move arg (x20) to x0 (first parameter)
//blr     x19                  // Call kernel thread function (address in x19)
//bl      do_exit               // If function returns, exit the thread

.globl err_hang
err_hang: b err_hang

// 获取当前 EL0 的栈指针
.global get_sp_el0
get_sp_el0:
    mrs x0, sp_el0   // 将 SP_EL0 的值读到 x0 寄存器
    ret              // 返回
.global get_elr_el1
get_elr_el1:
    mrs x0, elr_el1
    ret
	
.data
	strr:   .string  "in return from  user mode %x"
.data
	strr_kernel:   .string  "in return from kernel mode"
	.data
	strr_error:   .string  "in return error"