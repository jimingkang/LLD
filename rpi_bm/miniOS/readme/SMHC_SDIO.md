# SMHC 主机控制器：SD 卡与 SDIO WiFi 两条通路

本文说明 T113-S3 的 SMHC（SD/MMC Host Controller）怎样同时服务两类从设备：
SMHC0 接 TF 卡（SD 存储协议，块读写），SMHC1 接 XR829（SDIO 协议，
CMD52/CMD53 读写模组寄存器和消息队列）。内容依次是芯片内部结构、
驱动分层、信号时序，然后和 xv6-aarch64 的块设备、Linux sunxi-mmc
以及树莓派 3 的 WiFi 硬件做对照。

相关源码：

| 文件 | 作用 |
| --- | --- |
| `src/drivers/mmc/sunxi-sd.c` | SMHC0 的 SD 卡块驱动（miniBoot 和 miniOS 共用） |
| `src/drivers/mmc/host/sunxi-smhc.c` | SMHC 主机驱动（platform_driver），当前只绑定 SMHC1 |
| `src/drivers/mmc/core.c` | MMC/SDIO 核心：SDIO 枚举、CMD52/CMD53、sdio 总线 |
| `src/include/t113/mmc.h` | `mmc_host`、`sdio_card`、`sdio_func`、`sdio_driver` |
| `src/boards/100ask_t113/board.c` | `sdc1_device`：SMHC1 的资源、引脚、WL_REG_ON、32k fanout |
| `src/drivers/net/wireless/xradio/sdio.c` | XR829 的 SDIO function 驱动 |

## SMHC 芯片结构

### 三个实例

T113 有三个 SMHC，寄存器窗口相隔 0x1000（`T113_SMHC_BASE(n)`）：

| 实例 | 基址 | 板上用途 | 引脚 | 中断 |
| --- | --- | --- | --- | --- |
| SMHC0 | 0x04020000 | TF 卡（启动盘、根文件系统、`/boot`） | PF0–PF5 func 2 | 未使用 |
| SMHC1 | 0x04021000 | XR829 WiFi（SDIO） | PG0–PG5 func 2 | 73（GIC SPI 41），已声明未使用 |
| SMHC2 | 0x04022000 | 板上未用（通常接 eMMC） | — | — |

SMHC0 的引脚按 sun20i-d1 pinctrl 排列：PF0 = D1、PF1 = D0、PF2 = CLK、
PF3 = CMD、PF4 = D3、PF5 = D2。`sunxi-sd.c` 把 `PF_PULL0` 写成 0x545，
也就是除 CLK（PF2）以外全部上拉。SMHC1 的 PG0 = CLK、PG1 = CMD、PG2–PG5 = D0–D3，
CLK 不上拉，其余上拉，定义在 `board.c` 的 `sdc1_pins[]`。

### 内部框图

```text
                         AHB 总线（CPU 读写寄存器和 FIFO）
                                    │
┌───────────────────────────────────┼──────────────────────────────────────────┐
│ SMHCn                             │                                          │
│  ┌──────────────┐   ┌─────────────┴────────────┐   ┌───────────────────────┐ │
│  │ 时钟单元      │   │ 寄存器组                  │   │ 数据 FIFO（+0x200）    │ │
│  │ CLKCR 分频    │   │ GCTRL CMD ARG RESPx       │   │ CPU 逐字读写           │ │
│  │ UPCLK 同步    │   │ BLKSZ BYTECNT TMOUT WIDTH │   │ （IDMA 内部 DMA 未用）  │ │
│  │ NTSR 新时序   │   │ RINT IMASK STATUS         │   └───────────┬───────────┘ │
│  └──────┬───────┘   └─────────────┬────────────┘               │             │
│         │                         │                            │             │
│         │            ┌────────────┴─────────────┐   ┌──────────┴───────────┐ │
│         │            │ 命令状态机                │   │ 数据状态机            │ │
│         │            │ 生成起始位/CRC7/结束位    │   │ 起始位/CRC16/结束位   │ │
│         │            │ 收响应、校验 CRC、超时    │   │ 写：CRC 状态 + busy   │ │
│         │            └────────────┬─────────────┘   └──────────┬───────────┘ │
└─────────┼─────────────────────────┼────────────────────────────┼─────────────┘
          │ CLK                     │ CMD                        │ D0..D3
          ▼                         ▼                            ▼
                         卡（TF 卡 或 XR829）
```

软件只负责“填参数、写 CMD、等 RINT”。起始位、方向位、CRC7/CRC16、
结束位、响应接收和 CRC 校验都由状态机完成。

### 寄存器

两个驱动用到的寄存器完全相同（偏移来自 U-Boot `sunxi_mmc.h`，D1/T113 属于
NCAT2 布局，FIFO 在 +0x200）：

| 偏移 | 名称 | 用到的位 | 含义 |
| --- | --- | --- | --- |
| 0x000 | GCTRL | b0–2 复位（soft/FIFO/DMA），b31 `AHB` | 复位；b31 = 1 表示 CPU 直接读写 FIFO |
| 0x004 | CLKCR | b0–7 分频，b16 使能，b17 省电，b31 `MASK_D0` | 卡时钟 |
| 0x008 | TMOUT | b0–7 响应超时，b8–31 数据超时 | 写 0xffffff40：响应 64 个时钟，数据 0xffffff 个时钟 |
| 0x00c | WIDTH | 0 = 1-bit，1 = 4-bit | 总线宽度，两路都写 0 |
| 0x010 | BLKSZ | | 块大小 |
| 0x014 | BYTECNT | | 本次数据总字节数 |
| 0x018 | CMD | b0–5 命令号，b6 要响应，b7 长响应，b8 校验 CRC，b9 有数据，b10 写，b13 等前一个完成，b15 发初始化时钟，b21 只更新时钟，b31 START | 写入即启动 |
| 0x01c | ARG | | 命令参数 |
| 0x020–0x02c | RESP0–3 | | 响应；长响应时 RESP3 是最高 32 位 |
| 0x030 | IMASK | | 中断屏蔽，写 0（不用中断） |
| 0x038 | RINT | b2 CMD_DONE，b3 DATA_OVER，错误位掩码 0xbfc2 | 原始中断状态，写 1 清除 |
| 0x03c | STATUS | b2 FIFO 空，b3 FIFO 满，b9 卡忙 | |
| 0x05c | NTSR | b31 新时序模式 | D1/T113 必须打开 |
| 0x078 | HWRST | | 卡硬件复位脚，先 0 后 1 |
| 0x200 | FIFO | | 数据端口 |

RINT 的错误位 0xbfc2 包括：响应错（b1）、响应 CRC 错（b6）、数据 CRC 错（b7）、
响应超时（b8）、数据超时（b9）、数据饥饿超时（b10）、FIFO 溢出（b11）、
命令忙非法写（b12）、起始位错（b13）、结束位错（b15）。

### 时钟树

```text
HOSC 24 MHz
  │
  ▼  CCU 0x830 + 4n（SMHCn 模块时钟）：b31 门控，b24–26 源选择 0 = HOSC，N = M = 0
  │  D1/T113 的模块时钟后面固定 /2
  ▼
12 MHz（SMHC_SRC_HZ）
  │
  ▼  CLKCR[7:0] = div：div = 0 直通，否则 card_clk = 12 MHz / (2 × div)
  │
卡时钟：识别阶段 div = 15 → 400 kHz；数据阶段 div = 0 → 12 MHz

CCU 0x84c（SMHC 总线门控/复位）：b(n) 门控，b(16 + n) 复位
```

两路驱动都只用 HOSC，不碰 PLL_PERIPH0，所以最高只能到 12 MHz。
Linux sunxi-mmc 会把源切到 PLL_PERIPH0（600 MHz）再分频，才能跑到
SD 高速模式的 50 MHz。SMHC1 的 32k fanout 依赖 PLL_PERIPH0 已开，这一点和
SMHC 本身的时钟无关，见[WIFI_XR829_DRIVER.md](WIFI_XR829_DRIVER.md)的上电时序。

## 驱动架构

### 两条软件栈

```text
        SD 卡路径（SMHC0）                              WiFi 路径（SMHC1）

  minifs（/）        fat32（/boot）                xradio：fwio.c / bh.c / wsm.c
      │                  │                              │ sdio_memcpy_toio/fromio
      │                bio.c（bcache）                  │ sdio_readb/writeb、sdio_set_block_size
      │                  │                              ▼
  rootdev.c              │                    drivers/mmc/core.c
      │                  │                     ├─ sdio 总线：match / probe
      └────────┬─────────┘                     ├─ 枚举：CMD0/5/3/7、CCCR/FBR/CIS
               │ t113_sd_read/write            └─ sdio_io_rw_direct（CMD52）
               │ （sd_lock 互斥）                 sdio_io_rw_extended（CMD53）
               ▼                                        │ host->ops->request / set_ios / power
  drivers/mmc/sunxi-sd.c                                ▼
   直接操作 SMHC0 寄存器，                    drivers/mmc/host/sunxi-smhc.c
   没有 mmc_host 抽象                          platform_driver "sunxi-mmc"
               │                                        │ 资源来自 board.c 的 sdc1_device
               ▼                                        ▼
  SMHC0 @0x04020000 ── PF0..PF5 ── TF 卡      SMHC1 @0x04021000 ── PG0..PG5 ── XR829
                                                  PG11 32k fanout、PG12 WL_REG_ON
```

两条栈在硬件上是同一种控制器，软件上却完全分开：

- **SD 卡路径**是一个独立的块驱动。它要在 miniBoot（SPL，没有驱动模型、
  没有定时器）里也能用，所以写成不依赖任何框架的形式：寄存器地址写死为
  SMHC0，延时用空循环 `spin_us()`，对外只有 `t113_sd_init/read/write` 三个函数。
  在 miniOS 里，`MINIOS_KERNEL` 宏打开 `sd_lock` 互斥锁，因为 minifs 的 rootdev
  和 FAT32 的 bio 会从不同进程访问同一张卡。
- **WiFi 路径**按 Linux 的三层组织：主机驱动（`sunxi-smhc.c`）只实现
  `mmc_host_ops` 的四个回调；核心（`core.c`）负责协议和枚举；function 驱动
  （`xradio/sdio.c`）按 vendor/device 匹配后接管。

### 主机接口 `mmc_host_ops`

| 回调 | `sunxi-smhc.c` 的实现 | 作用 |
| --- | --- | --- |
| `request(host, cmd)` | `smhc_request()` | 发一条命令，有数据时 CPU 搬 FIFO，等 CMD_DONE（和 DATA_OVER），取响应；出错就复位控制器并恢复时钟 |
| `set_ios(host, hz, width)` | `smhc_set_ios()` | 改分频和总线宽度 |
| `power(host, on)` | `smhc_power()` | 32k fanout + WL_REG_ON 上电时序 |
| `dump(host)` | `smhc_dump()` | 失败时打印 SMHC、CCU、PG 口寄存器 |

`struct mmc_command` 只带命令号、参数、响应类型（`MMC_RSP_R1/R1B/R4/R5/R6`）和
可选的 `struct mmc_data`（缓冲区、块大小、块数、方向）。这与 Linux
`mmc_request` 的形状相同，只是没有 stop 命令、DMA 映射和完成回调。

### 注册与扫描

```text
t113_driver_core_init()
├── sdio_bus_init()                               注册 "sdio" 总线
├── platform_device_register(&sdc1_device)        mem = SMHC1，irq = 73，platform_data = sdc1_pdata
├── platform_driver_register(&t113_smhc_driver)
│   └── t113_smhc_probe(sdc1)
│       ├── idx = (mem - SMHC0_BASE) / 0x1000 = 1
│       ├── CCU 0x84c：复位位拉低 10 us 再和门控一起置 1
│       ├── CCU 0x834 = 1 << 31                    模块时钟 = HOSC
│       ├── t113_pinmux_apply(sdc1_pins)
│       ├── smhc_reset()；HWRST 0 → 1
│       ├── NTSR |= NEW_MODE；TMOUT = 0xffffff40；IMASK = 0
│       ├── smhc_set_ios(400 kHz, 1-bit)
│       └── mmc_add_host()                         只登记到 hosts[1]
├── sdio_driver_register(&xradio_sdio_driver)
└── mmc_rescan_all()                              对每个还没有卡的 host
    └── sdio_attach_card() → sdio_add_funcs() → device_register(func)
        └── sdio_bus_match() → xradio_sdio_probe()
```

SMHC0 不在 `hosts[]` 里，`mmc_rescan_all()` 不会扫描它。TF 卡在更早的
`kernel_boot()` → `t113_minifs_mount_rootdev()` → `t113_rootdev_init()` →
`t113_sd_init()` 里就初始化好了，因为根文件系统要在驱动模型启动之前挂载。

### 与 Linux sunxi-mmc 的对照

| 方面 | Linux | miniOS |
| --- | --- | --- |
| 主机驱动 | 一个 `sunxi-mmc.c` 服务全部 SMHC | SMHC1 用 `sunxi-smhc.c`；SMHC0 用独立的 `sunxi-sd.c` |
| SD 卡 | `mmc_rescan` → `mmc_attach_sd()` → `mmc_blk` 块设备 → 块层 | `t113_sd_read/write`，由 rootdev 和 bio 直接调用 |
| SDIO | `mmc_attach_sdio()` → `sdio_func` 设备 → 驱动 | 同样的结构，在 `core.c` 里 |
| 扫描时机 | 工作队列里的 `mmc_rescan`，支持热插拔 | 启动时一次 `mmc_rescan_all()`，不支持热插拔 |
| 数据搬运 | IDMA 描述符链 | CPU 逐字读写 FIFO |
| 完成通知 | 中断 + `mmc_request_done()` | 轮询 RINT |
| 时钟 | PLL_PERIPH0 分频，SD 高速 50 MHz | HOSC，最高 12 MHz |
| 总线宽度 | 协商到 4-bit（ACMD6 / CCCR 0x07） | 一直 1-bit |
| SDIO 中断 | `sdio_irq` 线程或 SMHC 的 SDIO 中断 | 不用，`bh.c` 轮询 |

## 时序

### 命令与响应

一条命令在 CMD 线上是 48 个时钟。卡在命令结束后 2–64 个时钟（N_CR）内开始回
响应。TMOUT 低 8 位写 0x40，正好是规范上限 64 个时钟。

```text
CLK     _|-|_|-|_|-|_ ... _|-|_|-|_|-|_ ... _|-|_|-|_|-|_ ... _|-|_
CMD     --|S|D| 命令号 + 参数 + CRC7 |E|----------|S|D| 响应 + CRC7 |E|---
           <--------- 48 个时钟 ------->          <----- 48 个时钟 ---->
                                       |<- N_CR ->|
                                         2..64 时钟
S = 起始位 0，D = 方向位（主机发 1，卡回 0），E = 结束位 1
```

| 时钟 | 一个 48 位帧 | 一次 CMD52（命令 + N_CR + 响应） |
| --- | --- | --- |
| 400 kHz | 120 us | 约 0.25–0.4 ms |
| 12 MHz | 4 us | 约 8–13 us |

软件每发一条命令的顺序是固定的：

```text
smhc_request(host, cmd)                      sunxi-sd.c 的 send_cmd() 相同
├── [有数据] GCTRL |= AHB | FIFO_RST，等 FIFO_RST 自清
├── [有数据] BLKSZ = blksz；BYTECNT = blksz × blocks
├── RINT = 0xffffffff                        清掉旧状态
├── ARG = arg
├── CMD = START | opcode | RESP_EXPIRE | CHK_CRC [| LONG_RESP] [| DATA | WAIT_PRE [| WRITE]]
│         CMD0 额外加 INIT_SEQ：先发 80 个初始化时钟（规范要求至少 74 个）
├── [有数据] smhc_pio()：按 STATUS 的 FIFO 空/满逐字搬运
├── 轮询 RINT：错误位 → -EIO 或 -ETIMEDOUT；CMD_DONE（+ DATA_OVER）→ 成功
├── 读 RESP0（长响应读 RESP0..3）
├── [R1b] 等 STATUS.CARD_BUSY 清零（D0 被卡拉低表示忙）
└── 出错：smhc_reset() + 重新 set_ios()，因为错误会卡住状态机
```

### 改时钟

D1/T113 的 SMHC 改分频时必须先屏蔽 D0，再发一个“只更新时钟”的伪命令，让新的
CLKCR 同步到卡时钟域：

```text
smhc_set_ios(host, hz, width)
├── CLKCR = 原值 & ~ENABLE | MASK_D0       1. 停卡时钟，屏蔽 D0
├── CMD = START | UPCLK_ONLY | WAIT_PRE    2. 同步，等 START 自清
├── CLKCR = 新 div | ENABLE | MASK_D0      3. 新分频，开时钟
├── CMD = START | UPCLK_ONLY | WAIT_PRE    4. 再同步
├── CLKCR = 新 div | ENABLE                5. 取消 D0 屏蔽
└── WIDTH = 0（1-bit）或 1（4-bit）
```

`MASK_D0` 和 NTSR 新时序模式都是 D1/T113 才有的要求，Linux `sunxi-mmc.c`
里同样的写法。

### SD 卡初始化（SMHC0）

```text
t113_sd_init()                                      时钟      卡状态
├── CCU 0x84c bit0 / bit16，CCU 0x830 = HOSC
├── PF0..PF5 func 2，上拉 0x545
├── 复位；HWRST；NTSR；TMOUT；WIDTH = 1-bit
├── set_clock(400 kHz)
├── CMD0  GO_IDLE_STATE（INIT_SEQ）                 400 kHz   → idle
├── CMD8  SEND_IF_COND 0x1AA → R7，回显 0x1AA 就是 v2 卡
├── 循环（最多 1000 次，间隔约 1 ms）：
│   ├── CMD55 APP_CMD
│   └── ACMD41 SD_SEND_OP_COND（HCS | 0x00ff8000）→ R3，b31 = 1 时就绪   → ready
│       b30（CCS）= 1 → SDHC/SDXC，按扇区号寻址
├── CMD2  ALL_SEND_CID → R2（136 位）                         → ident
├── CMD3  SEND_RELATIVE_ADDR → R6，取 RCA                     → stby
├── CMD7  SELECT_CARD(RCA) → R1b，等 CARD_BUSY                → tran
├── [SDSC] CMD16 SET_BLOCKLEN 512
└── set_clock(12 MHz)                               12 MHz
```

没有 ACMD6（切 4-bit）和 CMD6（切高速），所以 TF 卡一直是 1-bit、12 MHz。

### 单块读 CMD17

```text
CMD   |CMD17 + 地址|   |R1|
D0    -----------------------------|S| 512 字节数据（4096 位）| CRC16 |E|----
                   |<---- N_AC ---->|
CPU                                  逐字读 FIFO（128 个字），直到 RINT 有 CMD_DONE | DATA_OVER
```

1-bit、12 MHz 时，数据段约 4114 个时钟，即约 343 us。理论吞吐约
1.49 MB/s，实际还要加上命令、N_AC 和逐字轮询的开销。4-bit 能把数据段缩到
四分之一。

### 单块写 CMD24

```text
CMD   |CMD24 + 地址|   |R1|
D0    ----------------------|S| 512 字节 | CRC16 |E|--|S|010|E|________ 忙 ________|---
                                                     CRC 状态    卡编程期间拉低 D0
CPU   逐字写 FIFO（STATUS 不满就写）                  等 CMD_DONE | DATA_OVER，再等 CARD_BUSY 清零
```

CRC 状态 010 表示卡接受了数据；随后卡在编程闪存期间一直拉低 D0，SMHC 把
它反映为 STATUS b9。`write_block()` 在这里等待，所以 `t113_sd_write()`
返回时数据已经写进卡里，FAT32 的写顺序约束靠的就是这一点。

### SDIO 初始化与 CMD53（SMHC1）

SDIO 的上电时序（32k → WL_REG_ON 低 10 ms → 高 → 等 100 ms）、枚举状态机和
R4/R5/R6 位图，在[WIFI_XR829_DRIVER.md](WIFI_XR829_DRIVER.md)已经画过。
这里只补 CMD52/CMD53 的参数格式和数据时序：

```text
CMD52 参数（IO_RW_DIRECT）
 31   30..28   27    26   25 ............ 9   8   7 ....... 0
┌───┬────────┬─────┬────┬─────────────────┬───┬───────────┐
│R/W│ 功能号  │ RAW │ 0  │ 寄存器地址 17 位 │ 0 │ 写入的字节 │
└───┴────────┴─────┴────┴─────────────────┴───┴───────────┘

CMD53 参数（IO_RW_EXTENDED）
 31   30..28   27      26     25 ............ 9   8 ........ 0
┌───┬────────┬───────┬──────┬─────────────────┬────────────┐
│R/W│ 功能号  │ 块模式 │ 递增 │ 寄存器地址 17 位 │ 字节/块计数 │
└───┴────────┴───────┴──────┴─────────────────┴────────────┘
字节模式：计数 1..512（512 写成 0）
块模式：计数 = 块数，块大小取 FBR1 0x10/0x11（xradio 设为 512）
递增 = 0：地址固定，用于 HIF 的数据端口（FIFO）
```

`sdio_io_rw_extended()` 的规则：长度 ≤ 512 用字节模式，否则用块模式且长度必须是
`blksz` 的整数倍；缓冲区和长度都要 4 字节对齐，因为 FIFO 按 32 位访问。
数据段的波形和 CMD17/CMD24 一样；SDIO 写完也有 CRC 状态和 busy。

XR829 的时钟分两步：枚举和 CMD53 自检都在 400 kHz 下做，自检通过后
`mmc_set_clock(12 MHz)` 再自检一次，失败就退回 400 kHz。

### 两路对照

| 方面 | SMHC0：TF 卡 | SMHC1：XR829 |
| --- | --- | --- |
| 协议 | SD 存储（物理层 + 存储命令集） | SDIO（同一物理层 + IO 命令集） |
| 驱动 | `sunxi-sd.c`，无框架 | `sunxi-smhc.c` + `core.c` + `xradio/sdio.c` |
| 初始化命令 | CMD0、8、55/41、2、3、7（16） | CMD0、5（重复到就绪）、3、7，然后 CMD52 读 CCCR/FBR/CIS |
| 数据命令 | CMD17 读 / CMD24 写，每次 512 B | CMD53，字节模式或 512 B 块模式 |
| 寻址 | 扇区号（SDHC）或字节地址（SDSC） | 功能号 + 17 位寄存器地址 |
| 上电 | 卡座直接供电，无时序 | 32k 时钟 + WL_REG_ON 时序 |
| 时钟 | 400 kHz → 12 MHz | 400 kHz → 12 MHz（自检失败退回） |
| 位宽 | 1-bit | 1-bit |
| 并发 | `sd_lock`：rootdev、bio 两个用户 | 只有 xradio 一个用户，bh 单线程 |
| 出错恢复 | 复位 + UPCLK，单块重试 3 次 | 复位 + 重新 set_ios，返回错误给调用者 |
| 中断 / DMA | 不用 | 不用（IRQ 73 只声明） |

## 和 xv6-aarch64 的区别

xv6-aarch64 没有 SD 或 SDIO 驱动。它跑在 QEMU virt 机器上，磁盘是
virtio-blk（`kernel/virtio_disk.c`，MMIO 基址 `VIRTIO0` = KERNBASE + 0x0a000000，
中断 48），另有一个 `ramdisk.c` 备用。所以能比的是“块设备驱动的写法”，
以及 SDIO 那一层在 xv6 里根本不存在。

### 一次读盘的调用链

```text
xv6-aarch64                                      T113 miniOS（FAT32 路径）
bread(dev, blockno)                              bread(blockno)
└── bget()  睡眠锁 b->lock                        └── bget()（24 个 512 B 缓冲，LRU）
└── virtio_disk_rw(b, 0)                          └── t113_sd_read(lba, 1, b->data)
    ├── acquire(&disk.vdisk_lock)                     ├── mutex_lock(&sd_lock)
    ├── alloc3_desc()：没有空描述符就 sleep           ├── read_block(lba)
    ├── 描述符 0：virtio_blk_req{type, sector}        │   ├── 写 BLKSZ/BYTECNT/ARG/CMD
    ├── 描述符 1：b->data（1024 B）                   │   ├── 轮询 STATUS，CPU 读 128 个字
    ├── 描述符 2：1 字节状态                          │   └── 轮询 RINT 到 DATA_OVER
    ├── avail ring 放入描述符 0                       │   失败重试 3 次
    ├── *R(QUEUE_NOTIFY) = 0                          └── mutex_unlock(&sd_lock)
    └── while (b->disk == 1) sleep(b)  让出 CPU   调用者一直在轮询里等，CPU 不让出
virtio_disk_intr()（IRQ 48）
├── 遍历 used ring
├── b->disk = 0；wakeup(b)
└── 释放描述符
```

### 差异表

| 方面 | xv6-aarch64 virtio-blk | T113 SMHC0 SD 卡 | T113 SMHC1 SDIO |
| --- | --- | --- | --- |
| 设备 | QEMU 模拟的半虚拟化磁盘 | 真实 TF 卡 | 真实 SDIO 模组 |
| 发现设备 | 读 MMIO 魔数 0x74726976、设备号 2 | 写死 SMHC0 | platform 设备 + CMD5 + CIS 里的 MANFID |
| 协商 | virtio 特性位（关掉 RO、SCSI、MQ 等） | CMD8 / ACMD41 的电压和容量 | OCR 电压窗口、IOEx/IORx、块大小 |
| 请求格式 | 3 个描述符串成链（头、数据、状态） | 一条命令 + 一个数据块 | CMD52 一字节 / CMD53 多字节 |
| 数据搬运 | 设备直接读写内存（DMA 语义） | CPU 逐字搬 FIFO | CPU 逐字搬 FIFO |
| 完成通知 | 中断 + `wakeup()` | 轮询 RINT | 轮询 RINT |
| 等待方式 | `sleep()`，调度别的进程 | 忙等 | 忙等 |
| 锁 | spinlock `vdisk_lock` + 每块睡眠锁 | mutex `sd_lock` | 无（单用户） |
| 块大小 | 1024 B（BSIZE），一次请求两个扇区 | 512 B 扇区；minifs 1 KiB 块拆成两次 | 字节或 512 B 块 |
| 并发请求 | 最多 NUM = 8 个描述符在途 | 一次一个 | 一次一个 |
| 总线/驱动模型 | 无：`main()` 直接调 `virtio_disk_init()` | 无 | sdio 总线 + match/probe |
| 出错 | `panic` | 复位控制器、重试 | 复位控制器、报错 |

要把 SMHC 移植进 xv6-aarch64，替换的是 `virtio_disk_rw()` 这一个函数：
按 `b->blockno × 2` 读两个扇区，`virtio_disk_init()` 换成 `t113_sd_init()`。
想保留 xv6 的 sleep/wakeup 语义，就要打开 SMHC 的中断（IMASK 打开 CMD_DONE、
DATA_OVER 和错误位，在 GIC 上使能 SMHC0 的中断），在中断处理里 `wakeup(b)`，
或者改用 IDMA 让控制器自己搬数据。

## XR829 与树莓派 3 WiFi 的硬件区别

miniOS 的树莓派板级代码（`src/boards/raspberrypi/drivers/emmc/`）只有 SD 卡
驱动，没有 WiFi 驱动。下表里树莓派 3 一侧来自公开的原理图说明和 Linux
设备树（`bcm2837-rpi-3-b.dts`），没有在本仓库代码里验证。

### 连接方式

```text
树莓派 3B（BCM2837）                                   T113-S3（100ASK T113-Pro）
┌───────────────────────────────┐                     ┌───────────────────────────────┐
│ SDHOST ── GPIO48..53 ALT0 ─→ TF 卡                  │ SMHC0 ── PF0..PF5 ─→ TF 卡     │
│ EMMC（Arasan SDHCI）          │                     │ SMHC1 ── PG0..PG5 ─→ XR829     │
│   └── GPIO34..39 ALT3 ─→ CYW43438 SDIO              │ CLK_FANOUT1 PG11 ─→ 32k LPO    │
│ 固件 GPIO 扩展 expgpio 1 ─→ WL_ON                    │ PG12 ─→ WL_REG_ON              │
│ 固件 GPIO 扩展 expgpio 0 ─→ BT_ON                    │ PG10 ←─ WL_WAKE_AP（未用）     │
│ UART0（PL011）GPIO32/33 ─→ CYW43438 蓝牙            │ 蓝牙 UART：miniOS 未接         │
└───────────────────────────────┘                     └───────────────────────────────┘
```

树莓派 3 有两个 SD 控制器，并且可以通过引脚复用互换：Linux 默认让 SDHOST
接 TF 卡、Arasan EMMC 接 WiFi。miniOS 的 `emmc_init()` 反过来，把 GPIO34–39
设为输入（断开 WiFi），把 GPIO48–52 设为 ALT3，让 Arasan EMMC 去读 TF 卡。
所以 miniOS 在树莓派上要加 WiFi，得先把 TF 卡改到 SDHOST，或者 WiFi 改用 SDHOST。
T113 没有这种取舍：两个 SMHC 实例各自有固定的引脚。

### 对照表

| 方面 | 树莓派 3B：CYW43438（BCM43438） | 100ASK T113-Pro：XR829 |
| --- | --- | --- |
| 厂商 | Broadcom / Cypress（现 Infineon） | 全志 XRadio |
| SDIO vendor:device | 0x02d0:0xa9a6 | 0x0a9e:0x2282（实测） |
| 制式 | 2.4 GHz 802.11b/g/n，1T1R | 2.4 GHz 802.11b/g/n，1T1R |
| 蓝牙 | 有，经 UART0 | 有，miniOS 没用 |
| 主机控制器 | Arasan SDHCI（SD Host Controller 标准寄存器） | 全志 SMHC（私有寄存器组） |
| 电源控制 | WL_ON 在 VideoCore 固件管理的 GPIO 扩展上，要经 mailbox | WL_REG_ON 是 SoC 的普通 GPIO PG12 |
| 32k 睡眠时钟 | Linux 设备树不需要主机驱动开 | 主机必须开 CLK_FANOUT1 送到模组，否则 CMD5 无响应 |
| SDIO function | F1 = 背板（寄存器窗口），F2 = WLAN 数据 | 驱动只用 F1：HIF 寄存器 + 消息队列 |
| 片内处理器 | ARM Cortex-M3 + SOCRAM | 片内 CPU，代码 RAM 在 AHB 0x08000000 |
| 固件 | `brcmfmac43430-sdio.bin` + NVRAM 文本 + CLM blob | `boot_xr829.bin` + `fw_xr829.bin` + `sdd_xr829.bin` |
| 下载方式 | 经 F1 背板窗口（SBADDR 寄存器选 32 KiB 窗口）写 SOCRAM，NVRAM 放在 RAM 末尾，再放开 ARM 复位 | 先写 bootloader 到 AHB 0x08000000，再经下载 FIFO 按 1 KiB 块灌固件，握手 |
| 主机协议 | SDPCM 帧（控制 / 事件 / 数据三个通道）+ BCDC ioctl | HIF 队列 + WSM 消息（请求 / 确认 / 指示） |
| MAC 分工 | FullMAC：扫描、认证、关联在固件里，主机经 ioctl 下命令 | 主机侧走 mac80211（SoftMAC 分工），固件做下层 MAC |
| Linux 驱动 | `brcmfmac` | `xradio_wlan`（out-of-tree） |
| 主机唤醒 | SDIO 带内中断（DAT1）或带外 GPIO | WL_WAKE_AP（PG10）或 SDIO 中断；miniOS 都不用，轮询 |

对 miniOS 来说，最大的区别是 MAC 分工。CYW43438 是 FullMAC，连接一个 AP
只要几个 ioctl（设 SSID、设 WPA 参数）。XR829 走 mac80211 那一套，所以
miniOS 要自己实现扫描结果处理、认证/关联帧、EAPOL 四次握手和装钥，这就是
`src/net/mac80211`、`src/net/wireless` 和 supplicant 那一层存在的原因
（见[NET_STACK.md](NET_STACK.md)）。
