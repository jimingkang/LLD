.syntax unified
.cpu cortex-a7
.arm

.section .text.start, "ax"
.global _start
.type _start, %function

_start:
    b reset

    .align 5
vectors:
    b reset
    b exception_hang             @ undefined instruction
    b exception_hang             @ SVC
    b exception_hang             @ prefetch abort
    b exception_hang             @ data abort
    b exception_hang             @ reserved
    b exception_hang             @ IRQs remain masked throughout SPL
    b exception_hang             @ FIQ

reset:
    /* Cortex-A7 comes from the Allwinner BootROM in ARM state.  Establish
     * SVC32, little-endian execution and mask IRQ/FIQ during early bring-up. */
    mrs r0, cpsr
    bic r0, r0, #0x1f
    orr r0, r0, #0x13
    orr r0, r0, #0xc0
    bic r0, r0, #(1 << 9)
    msr cpsr_c, r0

    /* BootROM state is not part of the kernel ABI.  Start with translation
     * and caches off; mmu.c installs our own table before enabling M/I. */
    mrc p15, 0, r0, c1, c0, 0
    bic r0, r0, #(1 << 0)
    bic r0, r0, #(1 << 2)
    bic r0, r0, #(1 << 12)
    mcr p15, 0, r0, c1, c0, 0
    isb

    ldr r0, =24000000
    mcr p15, 0, r0, c14, c0, 0  @ CNTFRQ

    /* SPL owns temporary SRAM stacks. */
    mrs r0, cpsr
    bic r1, r0, #0x1f
    orr r1, r1, #0x12
    msr cpsr_c, r1
    ldr sp, =__spl_stack_irq_end
    msr cpsr_c, r0
    ldr sp, =__spl_stack_svc_end
    ldr r0, =vectors
    mcr p15, 0, r0, c12, c0, 0  @ VBAR
    isb

    ldr r0, =__spl_bss_start
    ldr r1, =__spl_bss_end
    mov r2, #0
1:
    cmp r0, r1
    strlo r2, [r0], #4
    blo 1b

    bl spl_main

exception_hang:
    wfi
    b exception_hang

.size _start, . - _start
