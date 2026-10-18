.syntax unified
.cpu cortex-a7
.arm

/* struct t113_cpu_context offsets: r4-r11=0..28, sp=32, lr=36. */
.section .text, "ax"
.global t113_cpu_switch_to
.type t113_cpu_switch_to, %function
t113_cpu_switch_to:
    stmia r0, {r4-r11, sp, lr}
    ldmia r1, {r4-r11, sp, lr}
    bx lr
.size t113_cpu_switch_to, . - t113_cpu_switch_to
