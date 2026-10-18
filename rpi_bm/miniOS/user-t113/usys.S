.syntax unified
.cpu cortex-a7
.arm

.global user_write
user_write:
    push {r7, lr}
    mov r7, #1
    svc #0
    pop {r7, pc}

.global user_getpid
user_getpid:
    push {r7, lr}
    mov r7, #2
    svc #0
    pop {r7, pc}

.global user_yield
user_yield:
    push {r7, lr}
    mov r7, #3
    svc #0
    pop {r7, pc}
