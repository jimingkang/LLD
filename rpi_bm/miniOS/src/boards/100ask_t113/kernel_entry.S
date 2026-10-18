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
    b kernel_exception_hang
    b kernel_svc_entry
    b kernel_exception_hang
    b kernel_exception_hang
    b kernel_exception_hang
    b kernel_irq_entry
    b kernel_exception_hang

kernel_reset:
    mov r4, r0                  @ DDR size passed by SPL
    cpsid if

    cps #0x12
    ldr sp, =__kernel_stack_irq_end
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
