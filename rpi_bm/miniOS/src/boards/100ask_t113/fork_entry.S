.syntax unified
.cpu cortex-a7
.arm

.equ PF_KTHREAD, 2
.equ TF_USER_SP, 52
.equ TF_PC,      60
.equ TF_CPSR,    64

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
