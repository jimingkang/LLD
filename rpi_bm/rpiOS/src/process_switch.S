.global switch_to_user
.global save_user_context

// switch_to_user(cpu_context_t* context)
// x0 = context pointer
switch_to_user:
    // Load user context
    ldp x1, x2, [x0, #0]       // x0, x1
    ldp x3, x4, [x0, #16]      // x2, x3
    ldp x5, x6, [x0, #32]      // x4, x5
    ldp x7, x8, [x0, #48]      // x6, x7
    ldp x9, x10, [x0, #64]     // x8, x9
    ldp x11, x12, [x0, #80]    // x10, x11
    ldp x13, x14, [x0, #96]    // x12, x13
    ldp x15, x16, [x0,#112]   // x14, x15
    ldp x17, x18, [x0,#128]   // x16, x17
    ldp x19, x20, [x0,#144]   // x18, x19
    ldp x21, x22, [x0,#160]   // x20, x21
    ldp x23, x24, [x0,#176]   // x22, x23
    ldp x25, x26, [x0,#192]   // x24, x25
    ldp x27, x28, [x0,#208]   // x26, x27
    ldp x29, x30, [x0,#224]   // x28, fp
    
    // Load ELR and SPSR
    ldr x29, [x0,#256]        // elr_el1
    msr elr_el1, x29
    ldr x29, [x0,#264]        // spsr_el1
    msr spsr_el1, x29
    
    // Load user stack pointer
    ldr x29, [x0,#272]        // sp_el0
    msr sp_el0, x29
    
    // Load kernel stack pointer
    ldr x29, [x0,#240]        // sp
    mov sp, x29
    
    // Restore x0 and x29 (fp)
    ldr x29, [x0,#232]        // fp
    ldr x0, [x0, #0]           // x0
    
    // Return to user mode
    eret

// save_user_context(cpu_context_t* context)
// Called from exception handler to save user context
save_user_context:
    // Save all general purpose registers
    stp x0, x1, [x0, #0]
    stp x2, x3, [x0, #16]
    stp x4, x5, [x0, #32]
    stp x6, x7, [x0, #48]
    stp x8, x9, [x0, #64]
    stp x10, x11, [x0, #80]
    stp x12, x13, [x0, #96]
    stp x14, x15, [x0,#112]
    stp x16, x17, [x0,#128]
    stp x18, x19, [x0,#144]
    stp x20, x21, [x0,#160]
    stp x22, x23, [x0,#176]
    stp x24, x25, [x0,#192]
    stp x26, x27, [x0,#208]
    stp x28, x29, [x0,#224]
    str x30, [x0,#240]        // lr
    
    // Save kernel stack pointer
    mov x1, sp
    str x1, [x0,#248]         // sp
    
    // Save ELR and SPSR
    mrs x1, elr_el1
    str x1, [x0, #256]         // elr_el1
    mrs x1, spsr_el1
    str x1, [x0,#264]         // spsr_el1
    
    // Save user stack pointer
    mrs x1, sp_el0
    str x1, [x0,#272]         // sp_el0
    
    ret
