.syntax unified
.cpu cortex-a7
.arm

.section .text.start, "ax"
.global _start
_start:
    bl main
1:
    bl user_yield
    b 1b
