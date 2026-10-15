.equ FS_BASE, 0xffff000030000000
.equ FS_SIZE, 101*16*63*512

.section .text
.global start

start:
    mrs x0, mpidr_el1
    and x0, x0, #3
    cmp x0, #0
    beq kernel_entry

end:
    b end

kernel_entry:
    mrs x0, currentel
    lsr x0, x0, #2
    cmp x0, #3
    beq el3_entry
    cmp x0, #2
    beq el2_entry
    cmp x0, #1
    beq el1_entry
    b end

el3_entry:
    // Non-secure AArch64 at the next exception level.
    mov x0, #(1 << 10)
    orr x0, x0, #(3 << 4)
    orr x0, x0, #1
    msr scr_el3, x0

    // Return from EL3 to EL2h with interrupts masked.
    mov x0, #0b1111001001
    msr spsr_el3, x0
    adr x0, el2_entry
    msr elr_el3, x0
    eret

el2_entry:
    msr sctlr_el1, xzr
    mov x0, #(1 << 31)
    msr hcr_el2, x0

    mov x0, #0b1111000101
    msr spsr_el2, x0

    adr x0, el1_entry
    msr elr_el2, x0

    eret

el1_entry:
    mov sp, #0x80000

    bl setup_vm
    bl enable_mmu

    ldr x0, =FS_BASE
    ldr x1, =kernel_binary_end
    ldr x2, =FS_SIZE
    bl memcpy

    ldr x0, =bss_start
    ldr x1, =bss_end
    sub x2, x1, x0
    mov x1, #0
    bl memset

    ldr x0, =vector_table
    msr vbar_el1, x0
    
    mov x0, #0xffff000000000000
    add sp, sp, x0

    ldr x0, =KMain
    blr x0

halt:
    wfi
    b halt
    
.global ret_from_fork
ret_from_fork:
    mov x0, x19
    blr x0
