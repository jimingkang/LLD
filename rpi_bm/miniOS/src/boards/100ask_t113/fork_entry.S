.syntax unified
.cpu cortex-a7
.arm

.equ PF_KTHREAD, 2
.equ TF_USER_SP, 52
.equ TF_PC,      60
.equ TF_CPSR,    64
.equ TF_SIZE,    68

.section .text, "ax"
.global ret_from_fork
.type ret_from_fork, %function
ret_from_fork:
    /* Private first-run convention restored by cpu_switch_to:
     * r4=task, r5=kernel fn, r6=kernel arg. */
    mov     r0, r4
    bl      t113_finish_fork
    tst     r0, #PF_KTHREAD
    beq     1f

    cpsie   i
    mov     r0, r6
    blx     r5
    bl      t113_task_exit
    b       .

1:
    mov     r0, r4
    bl      t113_task_trapframe
    b       arm32_return_to_user
.size ret_from_fork, . - ret_from_fork

.global arm32_return_to_user
.type arm32_return_to_user, %function
arm32_return_to_user:
    /* r0 points at struct arm32_trapframe.  From privileged SVC mode the
     * '^' form writes the banked User/System SP and LR. */
    mov     r3, r0
    add     r1, r3, #TF_USER_SP
    ldmia   r1, {sp, lr}^
    ldr     lr, [r3, #TF_PC]
    ldr     r1, [r3, #TF_CPSR]
    msr     spsr_cxsf, r1
    ldmia   r3, {r0-r12}
    movs    pc, lr
.size arm32_return_to_user, . - arm32_return_to_user

.global kernel_svc_entry
.type kernel_svc_entry, %function
kernel_svc_entry:
    /* SVC arrived from User mode. Build struct arm32_trapframe on the
     * process's SVC/kernel stack before calling any C code. */
    cpsid   i
    sub     sp, sp, #TF_SIZE
    stmia   sp, {r0-r12}

    add     r0, sp, #TF_USER_SP
    stmia   r0, {sp, lr}^       @ banked User SP and LR
    str     lr, [sp, #TF_PC]    @ LR_svc is the instruction after SVC
    mrs     r0, spsr
    str     r0, [sp, #TF_CPSR]

    mov     r0, sp
    bl      t113_syscall_dispatch

    /* Release the temporary frame from SP_svc, while passing its address to
     * the common User-mode restore routine. */
    mov     r0, sp
    add     sp, sp, #TF_SIZE
    b       arm32_return_to_user
.size kernel_svc_entry, . - kernel_svc_entry
