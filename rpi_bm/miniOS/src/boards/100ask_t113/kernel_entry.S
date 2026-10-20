.syntax unified
.cpu cortex-a7
.arm

.section .text.kernel_entry, "ax"
.global kernel_entry
.type kernel_entry, %function
kernel_entry:
    b kernel_reset

    .align 5
.global kernel_vectors
kernel_vectors:
    b kernel_reset
    b kernel_undefined_entry
    b kernel_svc_entry
    b kernel_prefetch_abort_entry
    b kernel_data_abort_entry
    b kernel_exception_hang
    b kernel_irq_entry
    b kernel_fiq_entry

kernel_reset:
    mov r4, r0                  @ DDR size passed by SPL
    cpsid if

    cps #0x12
    ldr sp, =__kernel_stack_irq_end
    cps #0x17
    ldr sp, =__kernel_stack_abt_end
    cps #0x1b
    ldr sp, =__kernel_stack_und_end
    cps #0x11
    ldr sp, =__kernel_stack_fiq_end
    cps #0x13
    ldr sp, =__kernel_stack_svc_end

    ldr r0, =kernel_vectors
    mcr p15, 0, r0, c12, c0, 0
    isb

    ldr r0, =__kernel_bss_start
    ldr r1, =__kernel_bss_end
    mov r2, #0
1:
    cmp r0, r1
    strlo r2, [r0], #4
    blo 1b

    mov r0, r4
    bl kernel_main

kernel_exception_hang:
    wfi
    b kernel_exception_hang

/*
 * Undefined instruction / prefetch abort / data abort / FIQ.  Each entry
 * runs on its own mode stack, saves r0-r12 and the faulting PC, then
 * kernel_exception_common completes struct t113_exception_frame (see
 * exception.h) with SPSR and the interrupted mode's banked SP/LR and calls
 * t113_exception_report(), which prints everything and never returns.
 *
 *   LR_und = faulting insn + 4 (ARM state; Thumb fixed up in C)
 *   LR_abt = faulting insn + 4 (prefetch abort), + 8 (data abort)
 *   LR_fiq = interrupted insn + 4
 */
kernel_undefined_entry:
    sub     lr, lr, #4
    stmdb   sp!, {r0-r12, lr}
    mov     r0, #1                  @ T113_EXC_UNDEF
    b       kernel_exception_common

kernel_prefetch_abort_entry:
    sub     lr, lr, #4
    stmdb   sp!, {r0-r12, lr}
    mov     r0, #3                  @ T113_EXC_PREFETCH_ABORT
    b       kernel_exception_common

kernel_data_abort_entry:
    sub     lr, lr, #8
    stmdb   sp!, {r0-r12, lr}
    mov     r0, #4                  @ T113_EXC_DATA_ABORT
    b       kernel_exception_common

kernel_fiq_entry:
    sub     lr, lr, #4
    stmdb   sp!, {r0-r12, lr}
    mov     r0, #7                  @ T113_EXC_FIQ
    b       kernel_exception_common

kernel_exception_common:
    sub     sp, sp, #12             @ spsr, interrupted sp, interrupted lr
    mrs     r2, spsr
    str     r2, [sp]
    and     r3, r2, #0x1f
    cmp     r3, #0x10               @ User and System share one SP/LR bank
    cmpne   r3, #0x1f
    bne     1f
    add     r4, sp, #4
    stmia   r4, {sp, lr}^
    nop
    b       2f
1:
    /* Privileged mode: visit it with IRQ/FIQ masked to read its SP/LR. */
    mrs     r5, cpsr
    bic     r6, r5, #0x1f
    orr     r6, r6, r3
    orr     r6, r6, #0xc0
    msr     cpsr_c, r6
    mov     r7, sp
    mov     r8, lr
    msr     cpsr_c, r5
    str     r7, [sp, #4]
    str     r8, [sp, #8]
2:
    mov     r1, sp
    bl      t113_exception_report
    b       kernel_exception_hang

    .align 5
kernel_irq_entry:
    sub lr, lr, #4
    srsdb sp!, #0x13
    cps #0x13
    stmdb sp!, {r0-r12, lr}
    bl t113_irq_handler
    ldmia sp!, {r0-r12, lr}
    rfeia sp!

.size kernel_entry, . - kernel_entry
