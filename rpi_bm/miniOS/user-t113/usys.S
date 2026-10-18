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

.global fork
.global user_fork
fork:
user_fork:
    push {r7, lr}
    mov r7, #4
    svc #0
    pop {r7, pc}

.global sleep
.global user_sleep
sleep:
user_sleep:
    push {r7, lr}
    mov r7, #5
    svc #0
    pop {r7, pc}

.global wait
.global user_wait
wait:
user_wait:
    push {r7, lr}
    mov r7, #6
    svc #0
    pop {r7, pc}

.global exit
.global user_exit
exit:
user_exit:
    push {r7, lr}
    mov r7, #7
    svc #0
1:
    b 1b
