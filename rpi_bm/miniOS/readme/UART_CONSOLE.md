# miniOS UART3 控制台：TX 轮询、RX 中断与 /dev/console

本文对应当前 miniOS（100ASK T113-S3）的实现，说明 UART3 从初始化到
收发数据的完整工作流程：发送侧为什么用轮询、接收侧如何用中断 +
256 字节环形缓冲把按键交给 shell、`/dev/console` 这个设备文件是
怎么注册和关联到 fd 0/1/2 的。涉及的代码集中在
`src/boards/100ask_t113/uart.c`、`timer.c`（IRQ 分派）、
`src/kernel/fs/devfs.c`、`src/kernel/syscall.c`。

当前已打通的链路：

- `t113_uart_init()` 是 `kernel_main()` 做的第一件事，串口立即可用，
  内核所有 `t113_uart_puts` 调试用打印都走它（early console）；
- TX 纯轮询：等 `USR.TFNF` 有空槽就写 THR，带 10 ms 停转看门狗；
- RX 双模式：中断使能前用轮询，使能后走 IRQ 37 → 环形缓冲 →
  等待队列唤醒阻塞读；
- 驱动模型 probe 把同一对读写函数注册成 devfs 的 `console`(1,0)
  和 `ttyS0`(3,0)，`open("/dev/console")` 可用；
- 用户 stdio 不走 VFS：`sys_read` 对 fd 0、`sys_write` 对 fd 1/2
  直接特判到 UART。

尚未实现：TX 软件环形缓冲 + 发送中断（现在写是忙等）、RX 流控
（无 RTS/CTS，环形缓冲满只能丢字节）、行规约（echo/退格/canonical
模式在 sh 的 readline 里自己做）、串口参数 ioctl（波特率固定
115200）、多个串口。

## 1. 硬件与初始化

UART3 是 DesignWare APB UART（16550 兼容 + 扩展寄存器）：

| 引脚/时钟 | 配置 |
| --- | --- |
| PB6 = TX，PB7 = RX | `GPIO PB CFG0` 复用 7（`gpio_set_uart3`，uart.c:77） |
| 时钟 | CCU `UART_BGR` bit3 = UART3 gate，bit19 = 复位释放（uart.c:87-92，先关 gate 再开，中间 100 次空转等待） |
| 波特率 | 24 MHz / (16 × 13) = 115200（`LCR.DLAB=1` 写 `DLL=13`，uart.c:97-98） |
| 帧格式 | 8N1（`LCR=0x03`，uart.c:100） |
| FIFO | `FCR=0x07`：使能 + 收发 FIFO 复位，触发级默认（uart.c:101） |

比普通 16550 多出来的两个状态位贯穿全文：

- `USR`（UART+0x7C）：bit0 BUSY、bit1 TFNF（TX FIFO 未满）、bit3
  RFNE（RX FIFO 非空）——8250 驱动里通常轮 `LSR.THRE`，DW 变体要
  看 `USR.TFNF`；
- `IIR` 的 `0x07` = Busy detect：在 `USR.BUSY` 期间写 LCR 会挂起
  这个中断，**只有读一次 USR 才清**，不清的话电平中断会一直挂着
  （uart.c:242-243 专门处理）。

## 2. 启动时序：early console 与驱动 probe 的分工

```
kernel_main (platform_kernel.c:32)
├── t113_uart_init()          ← 第一件事：裸寄存器初始化，串口立刻能打
├── t113_mmu_init()
└── kernel_boot (src/kernel/init/main.c:27)
    ├── 挂载 /boot / /dev
    ├── t113_driver_core_init()   → t113_uart_probe (uart.c:349)
    │                                 只校验 mem/IRQ 与硬编码值一致,
    │                                 注册 devfs "console"/"ttyS0"
    ├── t113_gic_init()
    ├── t113_sched_init()
    ├── kernel_platform_console_irq_init()  → t113_uart_irq_init (uart.c:194)
    ├── start_init_process()      ← 加载 /init
    └── timer0_init + cpsie i     ← 从此 IRQ 37 (UART RX) 开始到达
```

注意 `t113_uart_probe` 里那句注释：硬件在 `kernel_main()` 开头就已
经初始化好了，probe **不做任何硬件操作**，只把"这块板子的 UART3
资源确实对应 early console"这件事校验一遍，然后向 devfs 登记节点
（uart.c:343-364）。这是把"启动早期就要用的裸驱动"嫁接到驱动模型
上的典型做法：硬件归 boot 代码，注册归 probe。

## 3. TX 路径：轮询 + 停转看门狗

```
write(1, buf, n)  或内核 t113_uart_puts
  → sys_write (syscall.c:405)  fd==1||fd==2 特判
    → t113_uart_putc (uart.c:141)  逐字节:
        '\n' → 先递归发 '\r'                  (终端要 CRLF)
        uart_tx_wait_slot()                    等 USR.TFNF
        uart3->rbr_thr_dll = c                 写 THR
        uart_tx_report_stall()                 有停转则补打诊断
```

**为什么 TX 用轮询不用中断 + 缓冲**：这个串口的第一职责是内核调试
打印（panic、exception dump、驱动 probe 信息），语义上要求"打完
这句才继续"，而且要能在 IRQ 关掉的上下文里用。环形缓冲 + 发送
中断适合吞吐量场景，对 printk 反而是负担——xv6 的 `uartputc` 同样
是关中断轮询 LSR.THRE，Linux 则只在 `console_unlock` 的atomic
copy 阶段用轮询。miniOS 现在连 TX 软件缓冲都没有，`console_write`
（uart.c:307）就是逐字节 putc 循环。

轮询的代价由 `uart_tx_wait_slot`（uart.c:108）兜底：

- 正常路径：`USR.TFNF` 为 1 就返回，一个字节约 87 µs（115200 8N1）；
- 停转路径：连续 10 ms 没有空槽（`UART_TX_STALL_US`），认为发送器
  卡死——快照 `USR`/`LSR`、计数、**只复位 TX FIFO**（`FCR=0x05`，
  保住 RX FIFO 里没读走的输入），把诊断推迟到 putc 末尾再打
  （`uart_tx_report_stall`，避免在持锁/IRQ 上下文里递归打印）。

## 4. RX 路径：中断如何拿到数据

### 4.1 使能

`t113_uart_irq_init()`（uart.c:194）在调度器就绪后、第一个用户
进程创建前调用（main.c:45）：

1. `rx_irq_enabled = 1`（持锁写，读侧据此在"轮询直读"和"睡等待
   队列"之间二选一）；
2. `IER = ERBFI`：只开"接收数据可用"中断；
3. `dsb sy` + `t113_gic_enable_irq(T113_IRQ_UART3)`——IRQ 37 =
   GIC SPI 5（platform.h:21）。

### 4.2 中断分派链

```
硬件 IRQ 37 电平触发
  → vector → kernel_irq_entry (kernel_entry.S:122)
      srsdb sp!, #0x13            IRQ→SVC, 保存 LR+SPSR
      cps #0x13                   切 SVC 栈
      stmdb sp!, {r0-r12, lr}
      bl t113_irq_handler         (timer.c:96)
        ├── GIC IAR 取号 + EOI
        ├── irq == T113_IRQ_UART3 → t113_uart_irq_handler() (uart.c:235)
        └── UART3: t113_sched_yield()   ← 让被唤醒的读任务立即跑
      ldmia / rfeia               恢复原上下文(可能已是新任务)
```

### 4.3 中断里做什么

`t113_uart_irq_handler`（uart.c:235）很短，三个动作：

1. **清 Busy detect**：`IIR == 0x07` 时读一次 `USR`（唯一清除方式，
   不清则电平中断永久挂起）；
2. **drain FIFO** → `uart_rx_drain`（uart.c:204）：
   - 不信任 IIR 的瞬态 `NO_INT`——DW 版在第一次读 RBR 后可能立即
     报"无中断"，但 `LSR.DR` 还挂着同一串按键的后续字节。所以按
     **FIFO 状态**（`LSR.DR`）循环抽干，而不是按中断原因数字节；
   - 每字节：持 `rx_wait.lock` → 写 `rx_buffer[rx_head]` →
     `rx_head = (head+1) & 255`，`next == rx_tail` 说明 256 字节
     环形缓冲**满了，丢弃**（无流控，丢字节好过覆盖）；
   - 收尾重写 `IER = ERBFI`（timeout/line-status 中断服务后防丢使能
     的保险）；
3. **唤醒读方**：收到字节就 `wake_up_all(&rx_wait)`，把睡在队列上
   的任务置为 RUNNING；返回 `t113_irq_handler` 后立刻
   `t113_sched_yield()`，不等下一秒 Timer0——这是交互延迟的关键：
   shell 按一键，UART IRQ 在同一条中断路径里完成"存字符 → 唤醒 →
   调度走"，read 系统调用毫秒级返回。

### 4.4 阻塞读：锁内入队防丢唤醒

```
read(0, buf, n) → sys_read (syscall.c:63)  fd==0 特判
  → t113_uart_read (uart.c:161):
      持 rx_wait.lock 查环形缓冲:
        有字符 → 拷贝并立刻返回(终端语义: 有 1 字节就返回)
        空 + IRQ 模式 → wait_queue_sleep_locked(&rx_wait, flags)
                         持锁状态下把自己入队再睡 —— 与 IRQ 生产者
                         共用一把锁, "查空→入队" 与 "存字节→唤醒"
                         不可能交错丢唤醒
        空 + 轮询模式 → 解锁, 直接读硬件 LSR.DR, 否则 yield 自旋
```

`wait_queue_sleep_locked`（src/kernel/sync.c:43）= 持锁入队 →
解锁并恢复 IRQ → `t113_sched_yield()`。拿锁用
`spin_lock_irqsave`，因为生产者那半在 IRQ 上下文里跑。

### 4.5 RX 看门狗：漏中断恢复

UART 中断毕竟刚调通，留了一道保险：Timer0 每秒 tick 里调用
`t113_uart_rx_watchdog`（uart.c:247，挂在 timer.c:104）——若
`LSR.DR` 显示有数据而 IRQ 没把它们搬走（漏中断/使能丢失），就
主动 `uart_rx_drain()` 一次，并打印一次 "recovered missed RX
interrupt"。能自愈，又能暴露问题。

## 5. `/dev/console` 如何关联

### 5.1 注册：probe → devfs 节点

uart probe（uart.c:359-360）：

```c
t113_devfs_register_chrdev("console", 1u, 0u, &console_fops);
t113_devfs_register_chrdev("ttyS0",   3u, 0u, &console_fops);
```

`console_fops = { .read = console_read, .write = console_write }`，
两个函数都只是 `t113_uart_read` / 逐字节 `t113_uart_putc` 的薄封装
（uart.c:302-318）——devfs 的 read/write 本就不带 offset（字符设备
无位置概念），正好匹配串口语义。

devfs 侧（devfs.c）：节点表 16 项，名字 ≤30 字符；
`devfs_basename` 剥掉 `/dev` 前缀后线性查名；`lookup` 命中后把
`id = major<<16 | minor`、`private_data = &nodes[i]` 填进 VFS 节点；
`devfs_read/write` 转发到 `node->ops->read/write`。VFS 层负责
"哪个挂载点接这个路径"（最长前缀匹配，/dev → devfs），这部分详见
`ROOTFS_DEVFS.md`。

### 5.2 使用：fd 0/1/2 特判，不走 VFS

这是与 xv6/Linux 差异最大的一处。当前 `sys_read`/`sys_write`
对 stdio 是硬编码特判（syscall.c:65、syscall.c:411）：

| fd | 系统调用 | 去向 |
| --- | --- | --- |
| 0 (stdin) | `sys_read` | 直接 `t113_uart_read` |
| 1/2 (stdout/stderr) | `sys_write` | 直接逐字节 `t113_uart_putc` |
| ≥3 | open/read/write/close | 经 VFS → devfs → `console_fops`（`open("/dev/console", O_RDONLY)` 可读串口） |

用户进程创建时不打开任何文件，`files[]` 全空；sh 的 `read(0,...)`
/`write(1,...)` 全靠 fd 特判落到 UART。`/dev/console` 节点现在主要
给将来的用户程序用（以及证明 devfs 通路完整），init 并未像 xv6 那
样 `open("/dev/console")` 后 dup 成 0/1/2。

### 5.3 全景数据流

```
键盘
 │ USB 转串口
 ▼
UART3 RX FIFO (硬件, 16 深)
 │ IRQ 37 电平触发, IER.ERBFI
 ▼
t113_uart_irq_handler → uart_rx_drain
 │ 持锁写 256B 环形缓冲 rx_buffer[head]   (满则丢)
 │ wake_up_all(&rx_wait)  → sched_yield
 ▼
sh: read(0, &c, 1)
 │ svc #0, r7=9 (T113_SYS_READ)
 ▼
sys_read (fd==0 特判) → t113_uart_read
 │ 环形缓冲空 → wait_queue_sleep_locked 阻塞
 │ 有字节 → 拷给用户 buf, 返回 1
 ▼
sh readline 回显: putchar(c)
 │ write(1, &c, 1) → svc #0, r7=1 (T113_SYS_WRITE)
 ▼
sys_write (fd==1 特判) → t113_uart_putc
 │ '\n'→'\r\n'; 等 USR.TFNF; 写 THR
 ▼
UART3 TX FIFO → PB6 → USB 转串口 → 终端
```

内核打印（`t113_uart_puts`）与用户 `write(1,...)` 共用同一个 putc，
**没有互斥**：多任务并发打印会逐字节交错，这是有意保留的调试行为
（调度器 trace 就是靠它看交错的）。xv6 用 `Console.lock` 保证整行
不穿插；Linux 靠 `console_sem` + per-console lock。

## 6. 双模式读的设计意图

`rx_irq_enabled` 把读路径切成两副面孔，是为了 bring-up 顺序：

- 阶段一（`t113_uart_irq_init` 之前，含 SPL 交接后的早期内核）：
  GIC 未初始化，IRQ 到不了，`t113_uart_read`/`t113_uart_getc`
  退化为轮询 + `yield` 自旋。kernel_shell（kernel_shell.c:63，
  当前未接入启动流程，留作调试）用的就是这套；
- 阶段二（调度器 + GIC 就绪后）：开 IER、开 GIC，读路径切到
  "环形缓冲 + 睡眠唤醒"，CPU 空转代价归零。

`getc_nonblock`（uart.c:150）也保留双模式：IRQ 模式下只查环形
缓冲（硬件 FIFO 由中断独占搬运，避免与 IRQ 竞争读 RBR），轮询模式
下才直读硬件。

## 7. 调试设施

调通这条链路留下的开关，全部默认 0（除 Kconfig 项）：

| 开关 | 位置 | 作用 |
| --- | --- | --- |
| `CONFIG_DEBUG_TIMER_TICK` | menuconfig / autoconf.h | 每秒打印 tick 计数 |
| `SCHED_STATUS_TRACE` | timer.c:20 | 每秒一行：任务状态 + IER/LSR/USR + GIC 中 IRQ37 状态 + 等待队列 |
| `HEARTBEAT_TRACE` | timer.c:28 | 每 5 秒 '.', 有新 UART IRQ 时打 `<qN>` |
| `STDIN_TRACE` | syscall.c:23 | 首次 stdin 等待/返回时打 LSR/USR/收到数 |
| `EXEC_TRACE` | syscall.c:16 | exec 返回用户前经真实 MMU 校验 entry/sp/argc |
| 运行时计数 | uart.c:282 | `t113_uart_rx_irq_count()`；`t113_uart_debug_print()` 打 `q<irq数> r<head>/<tail> w<等待者pid>` |
| TX 停转 | uart.c:42 | `tx_stall_count/usr/lsr`，发生时打印 `uart3: TX stall #N USR=.. LSR=..` |
| RX 看门狗 | uart.c:247 | 漏中断自愈 + 一次性提示 |

排障口诀：`st` 行里的 `g`（GIC 视角 IRQ37 状态）为 1 而 `r<head/tail>`
不动 → 中断到了但 drain 没跑；`q` 计数不动而 LSR 有 DR → IRQ 没进
来，查 IER/GIC enable；`q` 涨、`r` 动、shell 仍卡 → 问题在唤醒/
调度，不在串口。

## 8. 与 xv6 / Linux 对照

| 话题 | miniOS | xv6 | Linux |
| --- | --- | --- | --- |
| TX | 轮询 `USR.TFNF`，无缓冲 | `uartputc` 关中断轮 `LSR.THRE`，无缓冲 | serial core：环形 xmit_buf + 发送中断/PIO 兜底 |
| RX | IRQ → 256B 环形缓冲 → 等待队列 | IRQ → `uartrecv` 直存 console 输入队列（同样睡眠唤醒） | IRQ → `tty_port` flip buffer → line discipline → read |
| 阻塞读 | `wait_queue_sleep_locked` 持锁入队 | `sleep(&cons.r, ...)` 同样要求持锁 | wait_event + tty 互斥 |
| 行规约 | 无，sh 的 readline 自己 echo/退格 | 无（echo 在 console 输入回显里做了一半） | tty ldisc：echo、canonical、信号 |
| /dev/console | devfs 节点已注册，但 stdio 走 fd 特判 | init 显式 open + dup 到 0/1/2 | 内核 console（printk）与用户 tty 分离又共存 |
| 丢数据 | RX 满丢字节，无流控 | 输入队列满丢字节 | 有 RTS/CTS 流控、可设 termios |

演进方向（如果要做）：照 xv6 的样子把 init 改成
`open("/dev/console")` + dup 到 0/1/2，撤掉 syscall 的 fd 特判；
TX 加软件环形缓冲 + `IER.ETBEI` 发送中断，把长打印从忙等里解放
出来；这两点做完，UART 子系统就和 xv6 的 console/ 基本同构了。
