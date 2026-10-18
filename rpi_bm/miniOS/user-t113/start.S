.syntax unified
.cpu cortex-a7
.arm

.section .text.start, "ax"
.global _start
_start:
    bl main
    bl exit
1:
    bl yield
    b 1b
