# 进程对象、内核上下文与用户态 TrapFrame

本文整理当前 `rpi_bm` 工程中进程创建、首次调度、内核上下文切换以及返回用户态的实现，并与 `s-matyukevich/raspberry-pi-os`、xv6 中的概念进行对应。

## 1. 三个核心数据结构

当前工程没有名为 `struct task_struct` 的类型，但并不表示没有进程控制块。当前工程使用 `struct Process` 承担这一角色。

| 当前工程 | s-matyukevich/Linux | xv6 | 作用 |
|---|---|---|---|
| `struct Process` | `struct task_struct` | `struct proc` | 描述整个进程，即 PCB |
| `struct cpu_context` | `struct cpu_context` | `struct context` | 保存内核调度上下文 |
| `struct TrapFrame` | `struct pt_regs` | `struct trapframe` | 保存和恢复用户态寄存器现场 |

### 1.1 `struct Process`

当前定义为：

```c
struct Process {
    struct List *next;
    int pid;
    int state;
    int wait;
    uint64_t context;
    uint64_t page_map;
    uint64_t stack;
    struct TrapFrame *tf;
};
```

各成员的主要用途：

- `pid`：进程编号。
- `state`：进程状态，如 `PROC_RUNNING`、`PROC_READY`。
- `wait`：进程等待的事件或编号。
- `page_map`：进程页表根地址。
- `stack`：该进程独立内核栈的起始地址。
- `context`：指向内核栈中的调度上下文。
- `tf`：指向内核栈顶部的用户态 `TrapFrame`。
- `next`：用于把进程加入 ready、wait 等链表。

所有进程对象存放在内核全局数组中：

```c
static struct Process process_table[NUM_PROC];
```

因此，当前工程的 `Process` 并不位于内核栈底部。它与 xv6 将 `struct proc` 存放在全局 `proc[]` 数组中的设计更接近。

### 1.2 `struct cpu_context`

```c
struct cpu_context {
    int64_t x19;
    int64_t x20;
    int64_t x21;
    int64_t x22;
    int64_t x23;
    int64_t x24;
    int64_t x25;
    int64_t x26;
    int64_t x27;
    int64_t x28;
    int64_t fp;   // x29
    int64_t lr;   // x30
};
```

它保存 AArch64 调用约定中的 callee-saved 寄存器。调度器通过 `swap()` 保存旧进程的这些寄存器，并恢复新进程的这些寄存器。

`cpu_context` 只描述内核态执行现场，不描述整个进程。

### 1.3 `struct TrapFrame`

`TrapFrame` 保存 `x0`～`x30`、`sp0`、`elr`、`spsr` 等寄存器。它描述的是：

> 下一次执行 `eret` 返回 EL0 时，CPU 应该恢复为什么状态。

关键字段：

- `elr`：返回 EL0 后执行的用户 PC，对应 `ELR_EL1`。
- `sp0`：用户栈指针，对应 `SP_EL0`。
- `spsr`：返回后的处理器状态和异常级别，对应 `SPSR_EL1`。

## 2. 当前工程的对象和内核栈布局

`Process` 位于全局 `process_table[]`，通过指针引用独立分配的页表和内核栈：

```text
内核全局 .bss

process_table[]
┌──────────────────────────┐
│ struct Process           │
│                          │
│ page_map ────────────────┼──→ 进程页表
│ stack ───────────────────┼──→ 独立的 2 MiB 内核栈
│ context ─────────────────┼──→ 栈中的内核上下文
│ tf ──────────────────────┼──→ 栈顶部 TrapFrame
└──────────────────────────┘
```

新任务的初始内核栈布局为：

```text
高地址：stack + PAGE_SIZE（PAGE_SIZE = 2 MiB）
┌──────────────────────────────┐
│ struct TrapFrame，288 字节   │ ← process->tf
├──────────────────────────────┤
│ 初始 cpu_context，96 字节    │ ← process->context
│ x19～x28                     │
│ x29 / fp                     │
│ x30 / lr                     │
├──────────────────────────────┤
│                              │
│ 内核栈可用空间               │
│ 栈向低地址增长 ↓             │
│                              │
└──────────────────────────────┘
低地址：stack
```

初始位置计算如下：

```c
process->tf = (struct TrapFrame *)(
    process->stack + PAGE_SIZE - sizeof(struct TrapFrame));

process->context = process->stack + PAGE_SIZE
    - sizeof(struct TrapFrame)
    - sizeof(struct cpu_context);
```

当前代码使用 `12 * 8` 表示 `sizeof(struct cpu_context)`。

## 3. `init_user_process()` 为什么可以直接启动用户进程

`init_user_process()` 使用 `alloc_new_process()`，在任务第一次被调度之前就准备好页表、内核上下文和用户态 TrapFrame。

### 3.1 构造初始内核上下文

```c
process->context = process->stack + PAGE_SIZE
    - sizeof(struct TrapFrame) - 12 * 8;

*(uint64_t *)(process->context + 11 * 8) =
    (uint64_t)trap_return;
```

`11 * 8` 是 `cpu_context.lr` 的偏移。因此第一次恢复该上下文后：

```text
x30 = trap_return
```

`swap()` 最后的 `ret` 会跳到 `x30`，即跳到 `trap_return`。

### 3.2 构造用户态 TrapFrame

```c
process->tf->elr  = 0x400000;
process->tf->sp0  = 0x400000 + PAGE_SIZE;
process->tf->spsr = 0;
```

因为当前 `PAGE_SIZE` 是 2 MiB：

```text
用户入口 = 0x400000
用户栈顶 = 0x600000
```

当前代码中 `spsr = 0` 表示返回到 AArch64 EL0t。为了提高可读性，后续最好改为具有明确含义的常量。

### 3.3 建立用户地址空间

```c
process->page_map = (uint64_t)kalloc();
memset((void *)process->page_map, 0, PAGE_SIZE);

ASSERT(setup_uvm(process->page_map, "INIT.BIN"));
```

`setup_uvm()` 将一个 2 MiB 物理页映射到用户虚拟地址 `0x400000`，并将 `INIT.BIN` 加载到该物理页。

因此以下两项相互匹配：

```text
TrapFrame.elr = 0x400000
页表中 0x400000 → 装有 INIT.BIN 的物理页
```

### 3.4 加入 ready 队列

```c
process->state = PROC_READY;
append_list_tail(&process_control->ready_list,
                 (struct List *)process);
```

当前初始化顺序是：

```c
init_idle_process();
init_user_process();
create_kernel_process(kthread1);
```

所以 ready 队列中 PID 1 的用户进程排在 PID 2 的内核线程之前。

### 3.5 第一次调度的完整路径

```text
schedule()
  → 从 ready_list 取出用户进程
  → switch_vm(process->page_map)
  → swap(&idle->context, user->context)
  → 恢复 x19～x30，其中 x30 = trap_return
  → sp += sizeof(cpu_context)，此时 sp == process->tf
  → ret，跳到 trap_return
  → 从 TrapFrame 恢复 ELR_EL1、SPSR_EL1、SP_EL0 和通用寄存器
  → eret
  → EL0: 0x400000，开始执行 INIT.BIN
```

它能够成功依赖四个严格匹配的条件：

1. `context.lr` 被设置为 `trap_return`。
2. 初始 `cpu_context` 后面紧邻 `TrapFrame`。
3. `TrapFrame.elr` 等于用户程序的映射地址 `0x400000`。
4. `swap()` 前已经切换到该进程的用户页表。

## 4. `create_kernel_process()` 的内核栈

`create_kernel_process()` 使用 `alloc_new_process2(fn)`。它和直接用户进程使用相同的初始空间布局：

```text
高地址：stack + PAGE_SIZE
┌──────────────────────────────┐
│ TrapFrame，初始全部清零      │ ← process->tf
├──────────────────────────────┤
│ 初始 cpu_context             │ ← process->context
│ x19～x29 = 0                 │
│ x30 = fn，例如 kthread1      │
├──────────────────────────────┤
│ 内核线程运行栈               │
│ 栈向低地址增长 ↓             │
└──────────────────────────────┘
低地址：stack
```

它与 `init_user_process()` 的区别不是物理布局，而是初始内容和启动目标：

| 内容 | `init_user_process()` | `create_kernel_process()` |
|---|---|---|
| 初始 `x30` | `trap_return` | 内核函数 `fn` |
| TrapFrame | 已准备用户 PC/SP/PSTATE | 清零，暂不使用 |
| 页表 | 新建用户页表 | `kernel_pgd` |
| 第一次调度 | 直接 `eret` 到 EL0 | 先执行内核函数 |

内核线程第一次调度路径：

```text
swap()
  → 恢复 x30 = kthread1
  → ret
  → kthread1() 在 EL1 运行
```

进入 `kthread1()` 时，`sp` 位于 `TrapFrame` 的起始地址。AArch64 栈向低地址增长，因此内核 C 函数使用的是 `TrapFrame` 下方空间，不会覆盖上方预留的 `TrapFrame`。

## 5. `move_to_user_mode()` 路径

`kthread1()` 调用：

```c
move_to_user_mode(get_pc()->current_process);
```

该函数重新建立用户页表并填写预留的 TrapFrame：

```c
p->tf->elr  = 0x400000;
p->tf->sp0  = 0x400000 + PAGE_SIZE;
p->tf->spsr = 0;

setup_uvm(p->page_map, "USER.BIN");
set_ttbr0(p->page_map);
enter_user(p->tf);
```

`enter_user()` 执行：

```asm
enter_user:
    mov sp, x0       // x0 = p->tf
    b trap_return
```

完整路径为：

```text
swap
  → kthread1（EL1）
  → move_to_user_mode
  → 填写 TrapFrame
  → enter_user
  → trap_return
  → eret
  → USER.BIN（EL0）
```

## 6. 两种用户进程启动方法的区别

### 6.1 直接构造用户进程

```text
alloc_new_process
  → context.lr = trap_return
  → 提前填写 TrapFrame
  → 提前建立用户页表
  → 加入 ready_list
  → 第一次调度直接 eret 到 EL0
```

这条路径更接近 xv6 的 `allocproc()` 加 `forkret/usertrapret` 设计。

### 6.2 先创建内核线程再转用户态

```text
alloc_new_process2
  → context.lr = kthread1
  → 使用 kernel_pgd
  → 第一次调度先在 EL1 执行 kthread1
  → move_to_user_mode 填写 TrapFrame 和用户页表
  → enter_user
  → eret 到 EL0
```

这条路径与 `s-matyukevich/raspberry-pi-os` 中：

```text
copy_process(PF_KTHREAD, kernel_process, arg)
  → ret_from_fork
  → kernel_process
  → move_to_user_mode
  → kernel_exit
  → eret
```

在思想上相似。

## 7. `ret_from_fork`、`forkret` 和 `trap_return`

概念上的对应关系：

| 当前/参考实现 | xv6 中的近似对应 |
|---|---|
| `ret_from_fork` | `forkret` |
| `TrapFrame` / `pt_regs` | `trapframe` |
| `cpu_context` | `context` |
| `trap_return` / `kernel_exit` | `usertrapret` + `userret` 的底层恢复部分 |
| `swap` / `cpu_switch_to` | `swtch` |

它们是概念对应，不是逐行完全等价。

## 8. `x19` 保存内核线程函数是不是 ARM 规定

不是。把入口函数放在 `x19`、参数放在 `x20`，是内核自己的任务启动协议。

ARM 指令集只规定：

```asm
blr x19
```

会执行：

```text
x30 = blr 后一条指令的地址
PC  = x19 中保存的地址
```

AAPCS64 规定 `x19`～`x28` 是 callee-saved 寄存器，因此内核选择 `x19`、`x20` 保存入口和参数很方便：调用 `schedule_tail()` 等普通函数后，它们仍应保持不变。

但具体约定：

```text
x19 = 内核线程入口函数
x20 = 入口函数参数
```

仍然是操作系统作者自己定义的，而不是 ARM 硬件强制规定的。

## 9. 首次上下文与后续上下文的区别

新任务第一次运行前：

```text
process->context = tf - sizeof(cpu_context)
```

这是人工构造的初始上下文。

任务运行后被调度出去时，`swap()` 执行：

```asm
sub sp, sp, #(12 * 8)
stp x19, x20, ...
...
str sp, [x0]
```

等价于：

```c
prev->context = 当前保存寄存器后的真实 sp;
```

因此：

```text
首次运行：context 是人工放在 TrapFrame 下方的启动现场
后续运行：context 是任务被切走时由 swap() 动态保存的现场
```

后续 `context` 不保证仍位于固定的 `tf - 96` 地址。

## 10. Git 提交演进

相关提交记录：

```text
ec85e64  2026-02-17  lesson 1:mv qemu_rpi3_process to rpi_bm
a4c425b  2026-02-24  lesson3:tf_context_stack
61fd752  2026-10-15  lesson6:启动代码
```

演进过程：

1. `ec85e64` 已包含 `alloc_new_process()` 和 `init_user_process()`，但 `init_process()` 中的调用仍被注释。
2. `a4c425b` 首次启用 `init_user_process()`，将文件名从 `init.bin` 改为 `INIT.BIN`，并明确整理 `context` 与 `TrapFrame` 的相邻布局。这是直接用户进程启动路径开始实际工作的关键提交。
3. `61fd752` 主要完成目录迁移、构建文件和调试输出调整，不是 `init_user_process()` 的首次引入。

## 11. 当前实现的限制

当前 `init_user_process()` 是第一个用户进程的专用启动代码，还不是通用进程创建函数：

```c
ASSERT(process == &process_table[1]);
```

主要限制包括：

- 只能在启动阶段成功创建固定的 PID 1。
- 用户入口固定为 `0x400000`。
- 用户程序文件固定为 `INIT.BIN`。
- 用户代码与用户栈共享一个 2 MiB 映射。
- 没有父子进程关系和 `fork()` 语义。
- 分配失败后缺少完整资源回收。
- 初始启动依赖 `cpu_context` 和 `TrapFrame` 严格相邻。
- 使用 `12 * 8`、`11 * 8` 等硬编码偏移，结构变化时容易出错。

后续可以将硬编码改为：

```c
process->context = (uint64_t)process->tf
    - sizeof(struct cpu_context);

((struct cpu_context *)process->context)->lr =
    (uint64_t)trap_return;
```

这样能够直接表达结构含义，并避免结构大小调整后偏移失配。
