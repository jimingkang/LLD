#include "entry.h"

// context_switch(cpu_context_t *old_context, cpu_context_t *new_context)
// Save current context to old_context and restore from new_context
.globl context_switch
context_switch:
    // x0 = old_context pointer, x1 = new_context pointer
    
    // Save current context to old_context (x0)
    stp x0, x1, [x0, #0]        // Save x0, x1
    stp x2, x3, [x0, #16]       // Save x2, x3
    stp x4, x5, [x0, #32]       // Save x4, x5
    stp x6, x7, [x0, #48]       // Save x6, x7
    stp x8, x9, [x0, #64]       // Save x8, x9
    stp x10, x11, [x0, #80]     // Save x10, x11
    stp x12, x13, [x0, #96]     // Save x12, x13
    stp x14, x15, [x0, #112]    // Save x14, x15
    stp x16, x17, [x0, #128]    // Save x16, x17
    stp x18, x19, [x0, #144]    // Save x18, x19
    stp x20, x21, [x0, #160]    // Save x20, x21
    stp x22, x23, [x0, #176]    // Save x22, x23
    stp x24, x25, [x0, #192]    // Save x24, x25
    stp x26, x27, [x0, #208]    // Save x26, x27
    stp x28, x29, [x0, #224]    // Save x28, x29
    str x30, [x0, #240]         // Save x30 (LR)
    
    // Save stack pointer
    mov x2, sp
    str x2, [x0, #248]          // Save SP
    
    // Save program counter (return address)
    str x30, [x0, #256]         // Save PC (LR)
    
    // Save processor state - we'll use default EL1h state
    mov x2, #0x5                // SPSR_EL1h (EL1h with all interrupts enabled)
    str x2, [x0, #264]          // Save PSTATE
    
    // Restore context from new_context (x1)
    ldp x0, x2, [x1, #0]        // Restore x0, but use x2 for old x1
    ldp x3, x4, [x1, #16]       // Restore x2->x3, x3->x4
    ldp x5, x6, [x1, #32]       // Restore x4->x5, x5->x6
    ldp x7, x8, [x1, #48]       // Restore x6->x7, x7->x8
    ldp x9, x10, [x1, #64]      // Restore x8->x9, x9->x10
    ldp x11, x12, [x1, #80]     // Restore x10->x11, x11->x12
    ldp x13, x14, [x1, #96]     // Restore x12->x13, x13->x14
    ldp x15, x16, [x1, #112]    // Restore x14->x15, x15->x16
    ldp x17, x18, [x1, #128]    // Restore x16->x17, x17->x18
    ldp x19, x20, [x1, #144]    // Restore x18->x19, x19->x20
    ldp x21, x22, [x1, #160]    // Restore x20->x21, x21->x22
    ldp x23, x24, [x1, #176]    // Restore x22->x23, x23->x24
    ldp x25, x26, [x1, #192]    // Restore x24->x25, x25->x26
    ldp x27, x28, [x1, #208]    // Restore x26->x27, x27->x28
    ldp x29, x30, [x1, #224]    // Restore x28->x29, x29->x30
    
    // Restore stack pointer
    ldr x31, [x1, #248]         // Load SP into temporary register
    mov sp, x31                 // Restore SP
    
    // Restore program counter (jump to it)
    ldr x31, [x1, #256]         // Load PC
    
    // Finally restore x1 and x2 from their saved positions
    mov x1, x2                  // Restore x1 from x2
    mov x2, x3                  // Restore x2 from x3
    
    // Jump to the restored program counter
    br x31

// process_start(process_func_t func, void *stack_top)
// Start a new process by setting up its initial context
.globl process_start
process_start:
    // x0 = function pointer, x1 = stack top
    
    // Set up the stack
    mov sp, x1
    
    // Clear all registers for clean process start
    mov x1, #0
    mov x2, #0
    mov x3, #0
    mov x4, #0
    mov x5, #0
    mov x6, #0
    mov x7, #0
    mov x8, #0
    mov x9, #0
    mov x10, #0
    mov x11, #0
    mov x12, #0
    mov x13, #0
    mov x14, #0
    mov x15, #0
    mov x16, #0
    mov x17, #0
    mov x18, #0
    mov x19, #0
    mov x20, #0
    mov x21, #0
    mov x22, #0
    mov x23, #0
    mov x24, #0
    mov x25, #0
    mov x26, #0
    mov x27, #0
    mov x28, #0
    mov x29, #0
    
    // Jump to the process function
    blr x0
    
    // If the process function returns, terminate the process
    bl process_exit_cleanup
    
    // Should never reach here
    b .

// process_exit_cleanup - called when a process exits
.globl process_exit_cleanup
process_exit_cleanup:
    // This function should mark the current process as terminated
    // and call the scheduler to switch to another process
    bl process_self_terminate
    // Should never return
    b .