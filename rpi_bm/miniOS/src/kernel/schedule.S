#define THREAD_CPU_CONTEXT			0 		// offset of cpu_context in task_struct 

.globl cpu_switch_to
cpu_switch_to:
	mov	x10, #THREAD_CPU_CONTEXT
	add	x8, x0, x10
	mov	x9, sp
	stp	x19, x20, [x8], #16		// store callee-saved registers
	stp	x21, x22, [x8], #16
	stp	x23, x24, [x8], #16
	stp	x25, x26, [x8], #16
	stp	x27, x28, [x8], #16
	stp	x29, x9, [x8], #16
	str	x30, [x8]
	add	x8, x1, x10
	ldp	x19, x20, [x8], #16		// restore callee-saved registers
	ldp	x21, x22, [x8], #16
	ldp	x23, x24, [x8], #16
	ldp	x25, x26, [x8], #16
	ldp	x27, x28, [x8], #16
	ldp	x29, x9, [x8], #16
	ldr	x30, [x8]
	mov	sp, x9
	ret

thread_switch:
    // Save current state
    stp x19, x20, [x0, #0]
    stp x21, x22, [x0, #16]
    stp x23, x24, [x0, #32]
    stp x25, x26, [x0, #48]
    stp x27, x28, [x0, #64]
    stp x29, x30, [x0, #80]  // FP=x29, LR=x30
    mov x2, sp
    str x2, [x0, #96]
    
    // Restore next state
    ldp x19, x20, [x1, #0]
    ldp x21, x22, [x1, #16]
    ldp x23, x24, [x1, #32]
    ldp x25, x26, [x1, #48]
    ldp x27, x28, [x1, #64]
    ldp x29, x30, [x1, #80]
    ldr x2, [x1, #96]
    mov sp, x2
    
    ret



/*
jimmy old test 
.global first_thread_switch
first_thread_switch:
    ldr x1, [x0, #96]    // Load SP
    mov sp, x1
    ldp x29, x30, [x0, #80]
    ldr x1, [x0, #104]   // Load CPSR
    msr spsr_el1, x1
    ldr x1, [x0, #88]    // Load PC (from LR slot)
    msr elr_el1, x1
    eret


    .global first_thread_switch
first_thread_switch:
    // x0 = thread context pointer
    ldp x29, x30, [x0, #80]  // Restore FP (x29) and LR (x30)
    ldr x1, [x0, #96]         // Load SP
    mov sp, x1
    ldr x1, [x0, #88]         // Load PC (from LR slot)
    br x1                      // Jump to thread (stay in EL1)

	    */