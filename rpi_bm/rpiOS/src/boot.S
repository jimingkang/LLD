#include "sysregs.h"
.section ".text.boot"
.global _start

_start:
    mrs x0, mpidr_el1
    and x0, x0, #3
    cmp x0, #0
    beq kernel_entry

end:
    b end

kernel_entry:
    ldr x0, =((3 << 28) | (3 << 22) | (1 << 20) | (1 << 11)|(0<<25))
    msr sctlr_el1, x0

    ldr x0, =((1 << 31))
    msr hcr_el2, x0

    ldr x0, =((3 << 4) | (1 << 10) | (1 << 0))
    msr scr_el3, x0

    ldr x0, =((7 << 6) | (5 << 0))
    msr spsr_el3, x0

    adr x0, el1_entry

    msr elr_el3, x0
    eret



el1_entry:
setup_system:
   mov sp, #0x80000
    // Setup exception vector table
    ldr x0, =exception_vector_table
    msr vbar_el1, x0
    
    // Initialize MMU
    bl mmu_init
    
    // Initialize hardware
    bl hardware_init
    
    // Jump to kernel main
    bl kernel_main
    
    // Should never reach here
    //b halt

.align 11
exception_vector_table:
    // Current EL with SP0
    .align 7
    b sync_exception_handler    // Synchronous
    .align 7  
    b irq_handler         // IRQ
    .align 7
    b exception_handler    // FIQ
    .align 7
    b exception_handler    // SError
    
    // Current EL with SPx
    .align 7
    b sync_exception_handler    // Synchronous
    .align 7
    b irq_handler         // IRQ
    .align 7
    b exception_handler    // FIQ
    .align 7
    b exception_handler    // SError
    
    // Lower EL using AArch64 (User mode)
    .align 7
    b sync_exception_handler    // Synchronous (System calls)
    .align 7
    b irq_handler         // IRQ
    .align 7
    b exception_handler    // FIQ
    .align 7
    b exception_handler    // SError
    
    // Lower EL using AArch32
    .align 7
    b exception_handler    // Synchronous
    .align 7
    b irq_handler         // IRQ
    .align 7
    b exception_handler    // FIQ
    .align 7
    b exception_handler    // SError

sync_exception_handler:
    // Save all registers for system call handling
    stp x0, x1, [sp, #-16]!
    stp x2, x3, [sp, #-16]!
    stp x4, x5, [sp, #-16]!
    stp x6, x7, [sp, #-16]!
    stp x8, x9, [sp, #-16]!
    stp x10, x11, [sp, #-16]!
    stp x12, x13, [sp, #-16]!
    stp x14, x15, [sp, #-16]!
    stp x16, x17, [sp, #-16]!
    stp x18, x19, [sp, #-16]!
    stp x20, x21, [sp, #-16]!
    stp x22, x23, [sp, #-16]!
    stp x24, x25, [sp, #-16]!
    stp x26, x27, [sp, #-16]!
    stp x28, x29, [sp, #-16]!
    str x30, [sp, #-8]!
    
    // Get ESR and ELR for system call analysis
    mrs x4, esr_el1        // Exception Syndrome Register
    mrs x5, elr_el1        // Exception Link Register (user PC)
    
    // Load system call arguments (x0, x1, x2 already saved, x8 = syscall number)
    ldr x6, [sp, #64]      // x0 (arg1)
    ldr x7, [sp, #72]      // x1 (arg2) 
    ldr x8, [sp, #80]      // x2 (arg3)
    ldr x9, [sp, #128]     // x8 (syscall number)
    
    // Call C synchronous exception handler
    mov x0, x4             // ESR
    mov x1, x5             // ELR
    mov x2, x6             // x0 (arg1)
    mov x3, x7             // x1 (arg2)
    // x4 = x2 (arg3) already in x8
    mov x4, x8
    // x5 = x8 (syscall number) already in x9
    mov x5, x9
    bl handle_sync_exception
    
    // Restore context
    ldr x30, [sp], #8
    ldp x28, x29, [sp], #16
    ldp x26, x27, [sp], #16
    ldp x24, x25, [sp], #16
    ldp x22, x23, [sp], #16
    ldp x20, x21, [sp], #16
    ldp x18, x19, [sp], #16
    ldp x16, x17, [sp], #16
    ldp x14, x15, [sp], #16
    ldp x12, x13, [sp], #16
    ldp x10, x11, [sp], #16
    ldp x8, x9, [sp], #16
    ldp x6, x7, [sp], #16
    ldp x4, x5, [sp], #16
    ldp x2, x3, [sp], #16
    ldp x0, x1, [sp], #16
    eret

exception_handler:
    // Save context
    stp x0, x1, [sp, #-16]!
    stp x2, x3, [sp, #-16]!
    stp x4, x5, [sp, #-16]!
    stp x6, x7, [sp, #-16]!
    stp x8, x9, [sp, #-16]!
    stp x10, x11, [sp, #-16]!
    stp x12, x13, [sp, #-16]!
    stp x14, x15, [sp, #-16]!
    stp x16, x17, [sp, #-16]!
    stp x18, x19, [sp, #-16]!
    stp x20, x21, [sp, #-16]!
    stp x22, x23, [sp, #-16]!
    stp x24, x25, [sp, #-16]!
    stp x26, x27, [sp, #-16]!
    stp x28, x29, [sp, #-16]!
    str x30, [sp, #-8]!
    
    // Call C exception handler
    bl handle_exception
    
    // Restore context
    ldr x30, [sp], #8
    ldp x28, x29, [sp], #16
    ldp x26, x27, [sp], #16
    ldp x24, x25, [sp], #16
    ldp x22, x23, [sp], #16
    ldp x20, x21, [sp], #16
    ldp x18, x19, [sp], #16
    ldp x16, x17, [sp], #16
    ldp x14, x15, [sp], #16
    ldp x12, x13, [sp], #16
    ldp x10, x11, [sp], #16
    ldp x8, x9, [sp], #16
    ldp x6, x7, [sp], #16
    ldp x4, x5, [sp], #16
    ldp x2, x3, [sp], #16
    ldp x0, x1, [sp], #16
    eret

irq_handler:
    // Save context (same as exception_handler)
    stp x0, x1, [sp, #-16]!
    stp x2, x3, [sp, #-16]!
    stp x4, x5, [sp, #-16]!
    stp x6, x7, [sp, #-16]!
    stp x8, x9, [sp, #-16]!
    stp x10, x11, [sp, #-16]!
    stp x12, x13, [sp, #-16]!
    stp x14, x15, [sp, #-16]!
    stp x16, x17, [sp, #-16]!
    stp x18, x19, [sp, #-16]!
    stp x20, x21, [sp, #-16]!
    stp x22, x23, [sp, #-16]!
    stp x24, x25, [sp, #-16]!
    stp x26, x27, [sp, #-16]!
    stp x28, x29, [sp, #-16]!
    str x30, [sp, #-8]!
    
    // Call C IRQ handler
    bl handle_irq
    
    // Restore context
    ldr x30, [sp], #8
    ldp x28, x29, [sp], #16
    ldp x26, x27, [sp], #16
    ldp x24, x25, [sp], #16
    ldp x22, x23, [sp], #16
    ldp x20, x21, [sp], #16
    ldp x18, x19, [sp], #16
    ldp x16, x17, [sp], #16
    ldp x14, x15, [sp], #16
    ldp x12, x13, [sp], #16
    ldp x10, x11, [sp], #16
    ldp x8, x9, [sp], #16
    ldp x6, x7, [sp], #16
    ldp x4, x5, [sp], #16
    ldp x2, x3, [sp], #16
    ldp x0, x1, [sp], #16
    eret

