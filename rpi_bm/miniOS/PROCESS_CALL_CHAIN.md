# miniOS 用户进程创建与切换调用链

本文对应当前 miniOS 的实现，说明通过内核启动函数创建用户进程、首次调度进入 EL0，以及后续异常往返的调用关系。

## 总调用链

```text
kernel_main()
└── copy_process(PF_KTHREAD, kernel_process, 0, 0)
    ├── allocate_kernel_page()                  分配 task_struct
    │   └── task_struct.cpu_context             位于 task_struct 偏移 0
    ├── allocate_kernel_page()                  分配独立内核栈
    ├── task_pt_regs(p)
    │   └── pt_regs                             固定放在内核栈高地址端
    ├── p->cpu_context.x19 = kernel_process     首次执行的内核函数
    ├── p->cpu_context.x20 = 0                  函数参数
    ├── p->cpu_context.pc = ret_from_fork       cpu_switch_to 的返回目标
    └── p->cpu_context.sp = childregs           首次运行时的内核 SP

kernel_main()
└── schedule()
    └── _schedule()
        └── switch_to(next)
            ├── switch_user_pgd(next->mm->pgd)  已有用户进程才切换 TTBR0_EL1
            └── cpu_switch_to(prev, next)
                ├── 保存 prev 的 x19～x30 和 SP
                ├── 恢复 next 的 x19～x30 和 SP
                └── ret
                    └── ret_from_fork
                        ├── preempt_enable()
                        ├── x19 != 0
                        └── blr x19
                            └── kernel_process()
                                └── launch_user_image(...)
                                    ├── allocate_kernel_page()          分配 mm_struct
                                    ├── allocate_pagetable_page()       分配用户 PGD
                                    └── move_to_user_mode(...)
                                        ├── map_and_copy_user_code()    映射并复制用户代码
                                        ├── allocate_user_page()        映射用户栈
                                        ├── task_pt_regs(current)
                                        ├── regs->pc = 用户入口地址
                                        ├── regs->sp = 用户栈顶
                                        ├── regs->pstate = EL0t 状态
                                        └── TTBR0_EL1 = current->mm->pgd

ret_from_fork
└── kernel_process() 返回
    └── ret_to_user                         位于 blr x19 后面
        ├── 从 pt_regs 读取 sp
        │   └── SP_EL0 = pt_regs->sp
        ├── 从 pt_regs 读取 pc
        │   └── ELR_EL1 = pt_regs->pc
        ├── 从 pt_regs 读取 pstate
        │   └── SPSR_EL1 = pt_regs->pstate
        └── kernel_exit 0
            ├── 恢复 x0～x30
            ├── 释放 pt_regs 栈帧
            └── eret
                └── EL0 用户入口
```

## 第一个用户进程

```text
kernel_main
└── copy_process(PF_KTHREAD, kernel_process, ...)
    └── 首次调度
        └── ret_from_fork
            └── kernel_process
                └── launch_user_image("user-image-1", ...)
                    └── move_to_user_mode
                        ├── 用户代码 VA 0x400000
                        ├── 用户栈 VA 0x07fff000～0x08000000
                        ├── ELR_EL1 = 0x400000
                        ├── SP_EL0 = 0x08000000
                        └── TTBR0_EL1 = 该进程的用户 PGD
```

## 第二个用户进程

```text
kernel_main
└── copy_process(PF_KTHREAD, kernel_process2, ...)
    └── 首次调度
        └── ret_from_fork
            └── kernel_process2
                └── launch_user_image("user-image-2", ...)
                    └── move_to_user_mode
                        ├── 用户代码 VA 0x401000
                        ├── 用户栈 VA 0x07fff000～0x08000000
                        ├── ELR_EL1 = 0x401000
                        ├── SP_EL0 = 0x08000000
                        └── TTBR0_EL1 = 该进程的用户 PGD
```

两个进程可以使用相同的用户栈虚拟地址，因为各自的 `TTBR0_EL1` 指向不同的用户页表，最终映射到不同物理页。

## 系统调用调用链

```text
EL0 用户代码
└── call_sys_xxx()
    └── svc #0
        └── EL0 synchronous exception
            └── el0_sync
                ├── kernel_entry 0
                │   ├── CPU 已切换到该任务的 SP_EL1
                │   └── 在内核栈顶部保存新的 pt_regs
                └── el0_svc
                    ├── 根据 x8 查找 sys_call_table
                    ├── blr sys_xxx
                    └── ret_from_syscall
                        ├── 把返回值写入 pt_regs->x0
                        └── kernel_exit 0
                            ├── 恢复用户寄存器
                            └── eret 返回 EL0
```

## 定时器中断和进程切换

```text
EL0 用户代码
└── 定时器 IRQ
    └── el0_irq
        ├── kernel_entry 0                       保存当前用户 pt_regs
        └── handle_irq()
            └── timer_tick()
                └── _schedule()
                    └── switch_to(next)
                        ├── switch_user_pgd(next->mm->pgd)
                        │   └── TTBR0_EL1 = next 用户 PGD
                        └── cpu_switch_to(prev, next)
                            ├── 保存 prev.cpu_context
                            ├── 恢复 next.cpu_context
                            └── 返回到 next 原先暂停的位置

next 的异常返回路径
└── handle_irq() 返回
    └── kernel_exit 0
        ├── 从 next 内核栈上的 pt_regs 恢复现场
        └── eret 返回 next 的 EL0
```

## 两类上下文的职责

```text
task_struct
└── cpu_context
    ├── x19～x30
    ├── 内核 SP
    └── 用途：EL1 调度切换

内核栈顶部
└── pt_regs / TrapFrame
    ├── x0～x30
    ├── SP_EL0
    ├── ELR_EL1
    ├── SPSR_EL1
    └── 用途：EL0 异常进入和 eret 返回
```

`cpu_context` 是 `task_struct` 的第一个成员，因此两者起始地址相同。这是当前内核与 `cpu_switch_to` 汇编之间的软件布局约定，并非 ARM64 硬件规定。

## TTBR0 与 TTBR1

```text
低地址用户空间
└── TTBR0_EL1
    └── current->mm->pgd
        ├── 用户代码
        └── 用户栈

高半区内核空间
└── TTBR1_EL1
    └── 全局 kernel_pgd
        ├── 内核代码和数据
        ├── task_struct 与内核栈的直接映射
        └── MMIO
```

调度用户进程时只需切换 `TTBR0_EL1`；`TTBR1_EL1` 保持指向公共内核页表。

## PSTATE 注意事项

当前代码使用：

```c
regs->pstate = PSR_MODE_EL0t | PSR_DAIF_MASK;
```

这会得到 `0x3c0`，屏蔽 Debug、SError、IRQ 和 FIQ。若希望 EL0 用户进程能够被定时器正常抢占，应改为：

```c
regs->pstate = PSR_MODE_EL0t;
```

即初始 `SPSR_EL1` 为 `0x0`。
