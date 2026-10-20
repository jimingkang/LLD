.syntax unified
.cpu cortex-a7
.arm

.global __sys_write
__sys_write:
    push {r7, lr}
    mov r7, #1
    svc #0
    pop {r7, pc}

.global __sys_getpid
__sys_getpid:
    push {r7, lr}
    mov r7, #2
    svc #0
    pop {r7, pc}

.global __sys_yield
__sys_yield:
    push {r7, lr}
    mov r7, #3
    svc #0
    pop {r7, pc}

.global __sys_fork
__sys_fork:
    push {r7, lr}
    mov r7, #4
    svc #0
    pop {r7, pc}

.global __sys_vfork
__sys_vfork:
    push {r7, lr}
    mov r7, #14
    svc #0
    pop {r7, pc}

.global __sys_sleep
__sys_sleep:
    push {r7, lr}
    mov r7, #5
    svc #0
    pop {r7, pc}

.global __sys_wait
__sys_wait:
    push {r7, lr}
    mov r7, #6
    svc #0
    pop {r7, pc}

.global __sys_exit
__sys_exit:
    push {r7, lr}
    mov r7, #7
    svc #0
1:
    b 1b

.global __sys_open
__sys_open:
    push {r7, lr}
    mov r7, #8
    svc #0
    pop {r7, pc}

.global __sys_read
__sys_read:
    push {r7, lr}
    mov r7, #9
    svc #0
    pop {r7, pc}

.global __sys_close
__sys_close:
    push {r7, lr}
    mov r7, #10
    svc #0
    pop {r7, pc}

.global __sys_uptime
__sys_uptime:
    push {r7, lr}
    mov r7, #11
    svc #0
    pop {r7, pc}

.global __sys_exec
__sys_exec:
    push {r7, lr}
    mov r7, #12
    svc #0
    pop {r7, pc}

.global __sys_sbrk
__sys_sbrk:
    push {r7, lr}
    mov r7, #13
    svc #0
    pop {r7, pc}

.global __sys_readdir
__sys_readdir:
    push {r7, lr}
    mov r7, #15
    svc #0
    pop {r7, pc}

.global __sys_getcwd
__sys_getcwd:
    push {r7, lr}
    mov r7, #16
    svc #0
    pop {r7, pc}

.global __sys_tftp
__sys_tftp:
    push {r7, lr}
    mov r7, #17
    svc #0
    pop {r7, pc}

.global __sys_netctl
__sys_netctl:
    push {r7, lr}
    mov r7, #18
    svc #0
    pop {r7, pc}

.global __sys_dup
__sys_dup:
    push {r7, lr}
    mov r7, #19
    svc #0
    pop {r7, pc}
