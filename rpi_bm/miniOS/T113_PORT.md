# miniOS 移植到 100ASK T113-S3

该目标参考 SyterKit `v0.3.0.0` 的 `board/100ask-t113s3` 与 `sun8iw20` 驱动。

## 当前阶段

当前镜像采用 SPL + kernel 一体化双阶段结构：BootROM 只认识一个 Boot0
镜像，但其中同时包含 SRAM SPL 和链接到 DDR 的 OS payload。

```text
BootROM
  -> Boot0/SPL @ SRAM 0x00020000
  -> DDR3 training / size detection
  -> copy embedded kernel payload to 0x40200000
  -> invalidate TLB/I-cache/branch predictor
  -> kernel_entry @ DDR
  -> kernel VBAR/stack/BSS/MMU/GIC/scheduler
```

已经完成：

- Allwinner Boot0/eGON 文件头和校验；
- Cortex-A7 SVC32 入口、VBAR、栈和 BSS 初始化；
- SRAM 链接地址 `0x00020000`，最大窗口 128 KiB；
- UART3 时钟复位、PB6/PB7 pinmux 和 115200 8N1 输出；
- GICv2 distributor/CPU interface 初始化；
- T113 Timer0 使用 24 MHz 时钟产生 IRQ 91；
- IRQ 模式使用独立 1 KiB 栈，并保存/恢复 r0-r12、lr 和 SPSR；
- DDR kernel 中的 ARMv7 short-descriptor 16 KiB 一级页表和恒等映射；
- Timer0 驱动的循环 ready list 调度，以及两个拥有独立 SVC 内核栈的内核线程；
- SRAM 4 KiB 页分配器，支持连续页和按页数对齐分配；
- 动态分配的 4 KiB 内核线程栈；
- 独立用户 L1 页表、用户只读代码页和用户可写/XN 栈页；
- 独立 `make t113` 构建目标。

现有 miniOS 调度、异常、MMU 和 EL0 代码是 AArch64 汇编，不能链接进 ARMv7 镜像。下一阶段需要分别移植：

1. 为用户进程增加 ARM32 `pt_regs` 和 SVC 返回路径；
2. 在当前一级内核恒等映射上增加每进程用户页表；
3. 增加页分配器，并把静态内核线程栈换成动态分配；
4. 扩展当前 ready list 的阻塞、唤醒和退出状态管理。

## DDR、页分配器与用户地址空间

DDR3 初始化和 training 代码来自 SyterKit v0.3.0.0 的 sun8iw20 驱动，使用
100ASK T113-S3 `board.c` 中的 792 MHz 参数。流程包含 PLL、DRAM controller、
PHY、ZQ、DQS training、rank/位宽探测和容量扫描。初始化完成后还会测试
DDR 首尾各一个 word。

页分配器管理探测到的整个 DDR 区间。bitmap 放在 DDR 起始位置并占用所需
的前几个物理页；内核线程栈、用户 L1/L2 页表和用户物理页都从 DDR 分配。
SPL 初始化 DDR 后，把镜像内嵌的 OS payload 从 SRAM load address 复制到
DDR `0x40200000`。SRAM 只保留 Boot0 header、early UART、DDR training、
复制/跳转代码和临时栈；正式内核向量、BSS、L1 页表和内核启动栈都位于
DDR。

当前链接布局（具体 payload 尾地址会随代码大小变化）：

```text
SRAM 0x00020000              SPL entry / Boot0 header
SRAM __kernel_load_start     embedded kernel payload LMA
SRAM __kernel_load_end       payload end / SPL runtime storage follows
DDR  0x40200000              kernel_entry / kernel VMA
DDR  __kernel_l1_table       16 KiB-aligned kernel L1
DDR  __kernel_reserved_end   physical page allocator begins after this
```

预期初始化信息：

```text
miniOS SPL: 100ASK T113-S3
SPL: running from SRAM, DDR/MMU/cache off
DRAM: SyterKit DDR3 training at 792 MHz...
DRAM: size-MB=0x00000080 range=[0x40000000, 0x48000000) boundary test OK
SPL: copy kernel SRAM 0x???????? -> DDR 0x40200000 bytes=0x????????
SPL: jump kernel_entry @ 0x40200000
miniOS kernel: executing from DDR
page allocator: pool=[0x4020b000, 0x48000000) pages=... bitmap-pages=...
```

这不是 `sbrk`。页分配器管理 DDR 物理页；未来的 `sbrk`/`brk` 系统调用负责扩大
用户虚拟堆，并通过页分配器取得物理页。

演示用户地址空间包含：

```text
VA 0x00100000   用户只读、可执行代码页
VA 0x008ff000   用户可读写、不可执行栈页
```

每个用户 L1 表先复制内核恒等映射，但 Domain 0 配置为 Client，内核 section
的 AP 权限为 privileged-only，所以进入 User 模式后不能访问内核映射。
目前只创建并检查地址空间，尚未执行 User 模式代码；后续还需要 ARM32
`pt_regs`、SVC handler、TTBR0 进程切换和异常返回路径。

## 构建

需要 `arm-none-eabi-gcc`：

```sh
make t113-clean
make t113
```

输出文件：

```text
build-t113/minios-t113.elf
build-t113/minios-t113.map
build-t113/minios-t113.bin
```

## FEL 启动验证

让开发板进入 FEL 模式，然后使用 `xfel`：

```sh
xfel write 0x20000 build-t113/minios-t113.bin
xfel exec 0x20000
```

UART3 使用 PB6/PB7，串口参数为 115200 8N1。预期输出：

```text
miniOS: 100ASK T113-S3 bring-up
CPU: ARMv7-A Cortex-A7, mode: SVC32
UART3: PB6/PB7 @ 115200 8N1
Board port stage 1 OK
MMU: ARMv7 short-descriptor identity map, SCTLR=0x???????? TTBR0=0x00024000
L1 identity: SRAM[0]=0x0000140e MMIO[0x02000000]=0x02010416 DRAM[0x40000000]=0x4000140e
scheduler: two ARM32 kernel threads ready
GIC + Timer0 IRQ ready: expect one tick per second
timer0 tick 0x00000001
schedule: 0x00000000 -> 0x00000001
running kernel-thread-A pid=0x00000001 sp=0x????????
timer0 tick 0x00000002
schedule: 0x00000001 -> 0x00000002
running kernel-thread-B pid=0x00000002 sp=0x????????
```

`timer0 tick` 是在 IRQ handler 中打印的。持续看到该输出，才表示 VBAR、
IRQ 模式栈、GIC 路由、Timer0 清中断、GIC EOI 和异常返回整条路径都已经
在真机上工作；确认后再接入进程切换。

## SD 卡启动

Boot0 通常放在介质 8 KiB 偏移。写入前务必确认设备名：

```sh
sudo dd if=build-t113/minios-t113.bin of=/dev/目标设备 bs=1k seek=8 conv=fsync
```

不要把 `/dev/目标设备` 原样执行，也不要选择系统盘。
