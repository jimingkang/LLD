# miniOS WiFi 驱动（XR829 / SDIO 枚举与固件下载）

本文对应当前 miniOS 的实现，说明 100ASK T113-Pro 板上 XR829 WiFi/BT
模组驱动的分层结构、SDIO 枚举与 CMD53 数据通路、SMHC 主机控制器、
HIF 寄存器/间接寻址、固件下载全流程，以及固件镜像的打包与加载。

当前已打通的链路：

- SDIO 枚举（CMD0/5/3/7 + CMD52 读 CCCR/FBR/CIS）；
- CMD53 双向数据通路（PIO，非 DMA）与 HIF 寄存器自检；
- 总线提速（400 kHz → 12 MHz 默认速度、1-bit）并在高速下复测；
- HIF 间接访问（SRAM/AHB 端口）与 DPLL/唤醒序列；
- boot_xr829 载入 + fw_xr829 通过 32 KiB 下载 FIFO 传输；
- 切到 queue（消息）模式，解析 WSM startup indication；
- WSM 命令/confirm 串行化、RX indication 分派、TX confirm、MIB 读写；
- WSM CONFIGURATION、2.4 GHz 定向主动扫描，以及 beacon/probe response 解析；
- WPA2-PSK 所需 PBKDF2/PTK/MIC/AES unwrap 通用密码学模块。

尚未实现：STA JOIN、EAPOL 四次握手和 TCP/IP 栈；主机侧没有用中断
（IRQ 73 已声明但全部轮询）。

## 硬件连接

XR829 WiFi/BT 合封模组挂在 SMHC1 上，原理图参考
`100ASK_T113-Pro_Base-SCH_V1.2` p4/p9：

| 信号 | 引脚 | 功能号 | 说明 |
| --- | --- | --- | --- |
| SDC1-CLK | PG0 | 2 | 串 33R 电阻 |
| SDC1-CMD | PG1 | 2 | 上拉 |
| SDC1-D0..D3 | PG2..PG5 | 2 | 上拉 |
| CLK-FANOUT1 | PG11 | 5 | 给模组喂 32.768 kHz 时钟 |
| WL_WAKE_AP | PG10 | - | 未使用（当前轮询，无中断） |
| WL_REG_ON | PG12 | GPIO 输出 | 模组使能，高有效 |

- SMHC1 寄存器基址 `0x04021000`（`T113_SMHC_BASE(1)`），长度 4 KiB；
- IRQ 73（GIC SPI 41，`T113_IRQ_SMHC1`）在平台资源里声明了，但驱动
  纯轮询，目前没有使用；
- 32.768 kHz 由 CCU 的 CLK_FANOUT1 输出：XR829 没有内部 RTC 时钟，
  睡眠时钟必须由 SoC 提供，否则模组上电后不响应 CMD5。

板级引脚和电源时序描述在 `src/include/t113/wifi.h` 的
`t113_mmc_platform_data`，具体数值在 `board.c` 的 `sdc1_pdata`。

## 文件组成

| 文件 | 角色 |
| --- | --- |
| `src/boards/100ask_t113/smhc.c` | SMHC（sunxi-mmc）主机控制器驱动：命令 + PIO 数据阶段，platform 总线驱动，轮询 |
| `src/boards/100ask_t113/sdio_core.c` | 轻量 MMC/SDIO core：CMD52/CMD53、CCCR/CIS 解析、sdio 总线、卡枚举、`mmc_set_clock()` |
| `src/drivers/net/wireless/xradio/xr829_core.c` | SDIO function 驱动：probe/remove、HIF 寄存器、固件装载与 WSM 启动 |
| `src/drivers/net/wireless/xradio/wsm.c` | 与总线无关的 WSM 消息层：queue、command/confirm、indication、MIB、TX |
| `src/drivers/net/wireless/xradio/sta.c` | STA 管理层：固件配置、定向主动扫描、目标 AP 信息提取 |
| `src/include/net/xradio/wsm.h` | WSM wire-format、命令号和对上层公开的接口 |
| `src/include/net/xradio/sta.h` | STA 管理层接口 |
| `src/lib/wpa_crypto.c` | 通用 WPA2-PSK 密码学，不依赖 XR829、SDIO 或板级代码 |
| `src/include/net/wpa_crypto.h` | WPA2 密码学公共接口 |
| `src/boards/100ask_t113/bootpack.c` | 内核侧 bootpack 查询（SPL 把 header 拷到 DDR 固定地址） |
| `src/include/t113/bootpack.h` | bootpack 容器格式，与 miniBoot、mkbootpack 共用 |
| `src/include/t113/mmc.h` | `mmc_host`/`sdio_card`/`sdio_func`/`sdio_driver`、CMD53 API、CCCR/FBR 定义 |
| `src/include/t113/wifi.h` | `t113_mmc_platform_data`：sdcN 平台数据（总线引脚 + 模组电源时序） |
| `src/boards/100ask_t113/board.c` | `sdc1_device` 平台设备定义、驱动注册顺序 |
| `src/boards/100ask_t113/driver_model.c` | 初始化顺序：设备 -> 驱动 -> `mmc_rescan_all()` |
| `miniBoot/tools/mkbootpack.c` | 主机侧打包工具：kernel + 固件镜像 -> bootpack.bin |
| `rpi_bm/Makefile` | 检测 `firmware/xr829/*.bin` 并自动填入 `BOOTPACK_EXTRA` |

固件镜像本身（boot/fw/sdd）是 Tina SDK 的有版权文件，不进入 git
（`rpi_bm/.gitignore` 忽略 `/firmware/`），构建时从本地目录打入
bootpack。

## 分层结构

整体照 Linux 的形状搭（名字和回调都尽量对齐），但实现极小：

```text
platform 总线                          sdio 总线
──────────────────────                ──────────────────────
sdc1_device  ──match──>  t113_smhc_driver
    │                          │ probe: 开 CCU 时钟/复位, pinmux,
    │                          │         复位控制器, 注册 mmc_host
    ▼                          ▼
  struct device            struct mmc_host (mmc1)
                                  │  mmc_rescan_all() 枚举
                                  ▼
                            struct sdio_card
                                  │  sdio_add_funcs()
                                  ▼
                            struct sdio_func (func 1)
                                  │  device_register() 后作为
                                  │  /bus/sdio/devices/mmc1:0001:1
                                  ▼
   mmc1:0001:1 ──match──>  xr829_driver ("xradio_wlan")
                                  │ probe:
                                  │   使能 function, 设块大小 512
                                  │   CMD53 自检 -> 提速到 12 MHz
                                  │   HIF 间接访问 -> 下载固件
                                  │   queue 模式 -> 读首条 WSM
                                  ▼
                              struct xr829_dev
```

代码目录按 Linux 的 bus/core/protocol/MLME 边界组织：

```text
src/boards/100ask_t113/
├── smhc.c                 SoC host controller（硬件层）
└── sdio_core.c            MMC/SDIO core 与 sdio_bus（总线层）

src/drivers/net/wireless/xradio/
├── xr829_core.c           sdio_driver + HIF + firmware lifecycle
├── wsm.c                  firmware WSM protocol
└── sta.c                  scan/JOIN/WPA 状态机（当前完成到 scan）

src/include/net/xradio/wsm.h   WSM 公共契约
src/lib/wpa_crypto.c           与具体网卡无关的 WPA2 primitive
```

依赖方向保持单向：板级 SMHC → SDIO core → XR829/HIF → WSM → 后续
STA/WPA 层；`wpa_crypto` 只提供算法，不反向依赖驱动。

数据面走的是 SDIO function 1 的 CMD53：

```text
xr829_core.c
├── xr829_reg_read32/write32()      CMD53 4 字节, 访问 HIF 寄存器窗口
├── apb_write/apb_read32()          SRAM_BASE_ADDR + SRAM_DPORT 间接访问 APB
├── ahb_write32/ahb_read32()        SRAM_BASE_ADDR + AHB_DPORT 间接访问 AHB
└── sdio_memcpy_fromio/toio()       CMD53 块/字节传输
        └── sdio_io_rw_extended()
                └── mmc_command + mmc_data
                        └── smhc_request() -> smhc_pio() FIFO 搬运
```

对应 Linux 里的映射关系：

| miniOS | Linux / xradio |
| --- | --- |
| `mmc_host` + `mmc_host_ops` | `struct mmc_host` + `mmc_host_ops` |
| `sdio_card` / `sdio_func` | `mmc_card` / `sdio_func` |
| `sdio_bus_type` + `sdio_driver` | `sdio_bus_type` + `sdio_driver` |
| `sdio_driver_register()` | `sdio_register_driver()` |
| `sdio_io_rw_extended()` | `mmc_io_rw_extended()` |
| `mmc_rescan_all()` | `mmc_rescan()`（Linux 里在 workqueue 中跑） |
| `xr829_reg_*` / HIF id | xradio `hwio.c` 的 `xradio_reg_read_32()` 等 |
| 固件下载流程 | xradio `fwio.c` 的 `xradio_load_firmware()` |

## 总调用链

```text
t113_driver_core_init()
├── bus_register(&sdio_bus_type)               sdio 总线先就位
├── t113_board_register_devices()
│   └── platform_device_register(&sdc1_device) 只登记, 不碰硬件
├── t113_board_register_drivers()
│   ├── platform_driver_register(&t113_smhc_driver)
│   │   └── t113_smhc_probe()
│   │       ├── platform_get_resource()           SMHC1 基址 0x04021000
│   │       ├── CCU: 复位->开 gate, mod clock = HOSC 24 MHz (/2 后 12 MHz)
│   │       ├── t113_pinmux_apply(sdc1_pins)      PG0..PG5 func 2
│   │       ├── smhc_reset()                      GCTRL 软复位
│   │       ├── HWRST 拉低 10us 再拉高            控制器硬复位
│   │       ├── NTSR |= NEW_MODE                  D1 系列 SMHC 必须 new timing
│   │       ├── smhc_set_ios(400 kHz, 1-bit)      识别期时钟
│   │       └── mmc_add_host()                    登记 host, 卡扫描推迟
│   └── sdio_driver_register(&xr829_driver)       此时总线上还没有设备
└── mmc_rescan_all()                              核心: 不在任何 probe 里
    └── sdio_attach_card(host)
        ├── smhc_power(host, 1)                   32k fanout + WL_REG_ON 时序
        ├── CMD0/CMD5/CMD3/CMD7                   SDIO 识别
        ├── CMD52 读 CCCR/CIS                     vendor/device = 0x0a9e:0x2282
        └── sdio_add_funcs(host)
            ├── CMD52 读 FBR                     class + per-function CIS
            └── device_register(&f->dev)
                └── sdio_bus_match() -> sdio_bus_probe()
                    └── xr829_probe()
                        ├── sdio_enable_func()           IOEx -> 等 IORx
                        ├── sdio_set_block_size(512)
                        ├── xr829_cmd53_selftest(verbose=1)
                        │   ├── CMD53 读 HIF_CONFIG 两次（必须一致）
                        │   ├── CMD53 写/读 HIF_TSET_GEN（3 组模式）
                        │   └── 恢复原值，打印结果
                        ├── mmc_set_clock(12 MHz) + 自检(verbose=0)
                        │   └── 失败则 mmc_set_clock(0) 回 400 kHz
                        ├── xr829_load_firmware()
                        │   ├── bootpack_find("boot/fw/sdd_xr829")
                        │   ├── CMD53 读 HIF_CONFIG，检查 hw-type 位
                        │   ├── parse_sdd() -> 参考时钟 -> DPLL 值
                        │   ├── CMD53 写 HIF_TSET_GEN，回读校验
                        │   ├── CONTROL.WUP=0，轮询 CONTROL.RDY
                        │   ├── CONFIG |= ACCESS_MODE（direct 模式）
                        │   ├── update_dpllctrl()（WLAN PWRCTRL 握手）
                        │   ├── download_bootloader()
                        │   │   └── AHB 间接写：32 位字 -> AHB 0x08000000
                        │   ├── 释放 CPU：清 CPU_RESET / CPU_CLK_DIS
                        │   ├── 轮询 IMAGE_SIZE == I_AM_HERE
                        │   ├── 1 KiB/块写 download FIFO（put/get 环形窗口）
                        │   ├── 轮询 STATUS == SUCCESS（失败打印 TRACE_PC）
                        │   └── CONFIG: 使能 IRQ，清 ACCESS_MODE（queue 模式）
                        └── xr829_read_first_message()
                            └── 轮询 CONTROL.NEXT_LEN，从 queue 读出并打印
```

## 初始化顺序与驱动核心约束

`device_register()` 会拿驱动核心锁并触发匹配绑定（probe 也在同一把
锁下运行）。卡枚举要注册 `sdio_func` 设备，如果放在 SMHC 的 probe 里
就会在持锁状态下再次注册设备——死锁。所以
`t113_driver_core_init()` 先把所有设备、驱动注册完，最后统一调
`mmc_rescan_all()`，对应 Linux 把 `mmc_rescan` 扔进 workqueue 的做法。

同理，注册顺序也有要求：`xr829_driver` 必须在 `mmc_rescan_all()`
之前注册，否则 function 设备注册时找不到驱动（本模型没有
deferred-probe 重试；未绑定时会打印 `no sdio driver matched`）。

另一个后果是：**整段固件下载都在 xr829_probe() 里、在驱动核心锁下
忙等完成**。这在 Linux 里不可接受（probe 必须快、可睡眠），这里因为
只有这一个 SDIO 设备、且下载在 12 MHz 下只需约 0.2 s 量级（失败回退
到 400 kHz 时约数秒），所以先保持最简单的同步实现。后续接中断/工作
队列时应把固件下载移出 probe。

`xr829_probe()` 即使 CMD53 或固件下载失败也返回 0，保持绑定关系，
方便驱动模型打印出设备状态并在串口留下诊断信息（若 probe 返回负值，
绑定不会建立，现场更难分析）。

## SDIO 枚举

### CMD52：单字节读写

所有 CCCR/FBR 寄存器访问走 `sdio_io_rw_direct()`，命令参数位域：

```text
bit 31     R/W        1 = 写
bit 30:28  function   0 = CCCR/FBR 空间, 1..7 = 各 function 寄存器
bit 27     RAW        写后立即回读
bit 26     保留 0
bit 25:9   地址       17 位
bit  7:0   数据       写方向是数据, 读方向是 stuff
```

响应 R5 的错误位掩码取 `0xcb00`（与 Linux `mmc_io_rw_direct()` 相同）：

```text
bit 15  COM_CRC_ERROR     CRC 校验失败
bit 14  ILLEGAL_COMMAND
bit 13  ERROR             通用错误
bit 10  FUNCTION_NUMBER   function 号超范围
bit  8  OUT_OF_RANGE      地址超范围
```

封装（`sdio_core.c`）：

- `sdio_readb/writeb`：指定 function 的单字节读写；
- `sdio_f0_readb/writeb`：固定 function 0，即 CCCR/FBR 配置空间；
- `sdio_enable_func`：IOEx 置位 function 位后轮询 IORx 对应位，最长
  1 秒；
- `sdio_set_block_size`：写 FBR+0x10/0x11，并同步记录到
  `sdio_func.blksz`（CMD53 块模式要用）。

### CCCR / FBR / CIS

CCCR（function 0 公共配置）：

| 地址 | 名称 | 作用 |
| --- | --- | --- |
| 0x00 | CCCR | 低 4 位 CCCR 版本, 高 4 位 SD 版本 |
| 0x02 | IOEx | 各 function I/O 使能（写） |
| 0x03 | IORx | 各 function 就绪状态（只读） |
| 0x08 | CAPS | 能力（低功耗、DMA、高速支持） |
| 0x09..0x0b | CIS | 指向公共 CIS 元组链表的 24 位指针（小端） |

FBR（每个 function n 一份，基址 `n*0x100`）：

| 偏移 | 名称 | 作用 |
| --- | --- | --- |
| +0x00 | STD_IF | 低 4 位 standard interface code；XR829 不用它匹配（驱动按 CIS 的 vendor/device 匹配） |
| +0x09.. | CIS | 该 function 自己的 CIS 指针 |
| +0x10/0x11 | BLKSIZE | 块大小低/高字节 |

CIS 是元组链表：每项一字节 code + 一字节 link（长度），跟着内容。
`parse_cis_manfid()` 沿链表走，找 `CISTPL_MANFID(0x20)`，取前 4 字节
得到 vendor/device。

实测这块 100ASK T113-Pro 上的 XR829 报 **0x0a9e:0x2282**；开源
xradio 驱动里的老 XR819 是 0x0020:0x2281（ST-Ericsson 历史遗留 ID）。
`xr829_ids[]` 两个都匹配，另外各留一条只限 vendor 的兜底项：

```c
{ SDIO_ANY_ID, 0x0a9e, 0x2282 },        /* XR829, 本板实测 */
{ SDIO_ANY_ID, 0x0020, 0x2281 },        /* XR819 per xradio */
{ SDIO_ANY_ID, 0x0a9e, SDIO_ANY_ID },
{ SDIO_ANY_ID, 0x0020, SDIO_ANY_ID },
{ 0, 0, 0 },
```

## CMD53 与数据通路

`sdio_io_rw_extended()` 实现 CMD53，参数位域：

```text
bit 31     R/W        1 = 写
bit 30:28  function   function 1
bit 27     block     1 = 块模式, 0 = 字节模式
bit 26     incr      1 = 地址自增（内存型）, 0 = 固定地址（FIFO 口）
bit 25:9   地址       17 位
bit  8:0   count      字节模式 = 字节数（512 编码为 0）
                      块模式 = 块数
```

约束与选择逻辑（都强制 4 字节对齐）：

| 条件 | 模式 | 说明 |
| --- | --- | --- |
| `len <= 512` | 字节模式 | 单次传输，`data.blksz = len`, `blocks = 1` |
| `len > 512` | 块模式 | `len` 必须是 `f->blksz` 的整数倍，块数 ≤ 511 |

对外接口：

- `sdio_memcpy_fromio(func, dst, addr, len)` / `sdio_memcpy_toio()`：
  地址自增的 CMD53，HIF 的寄存器、FIFO、队列都走它；
- HIF 寄存器访问封装成 `xr829_reg_read32/write32()`（4 字节），
  声明在 `mmc.h` 末尾；
- 1 KiB 固件块 = 2 × 512 字节块传输。

### SMHC PIO 数据阶段

数据阶段不用 DMA、不用中断，CPU 直接搬 FIFO：

```text
smhc_request() 带 mmc_data 时：
├── CMD 寄存器置 DATA(b9) | WAIT_PRE(b13) | WRITE(b10)
├── GCTRL |= AHB(b31) | FIFO_RST(b1)，等 FIFO_RST 自清
├── BLKSZ = blksz, BYTECNT = blksz * blocks
├── 启动命令后进 smhc_pio()
│   ├── 写：STATUS.FIFO_FULL(b3) 为 0 时写 SMHC_FIFO(0x200)
│   ├── 读：STATUS.FIFO_EMPTY(b2) 为 0 时读 SMHC_FIFO
│   ├── 每搬 4 字节检查一次 RINT 错误位，有错立即 -EIO
│   └── 连续 ~200 ms 没有进展 -> -ETIMEDOUT
└── 等 RINT.CMD_DONE(b2) | DATA_OVER(b3)
```

`SMHC_FIFO` 在偏移 `0x200`（D1/T113 的 NCAT2 布局）。出错时和纯命令
路径一样：`smhc_reset()` + 重新应用时钟，避免状态机卡死。

## SMHC 主机控制器

`smhc.c` 是命令级轮询驱动：命令 + PIO 数据，不接中断。

用到的寄存器（偏移）：

| 偏移 | 名称 | 用途 |
| --- | --- | --- |
| 0x000 | GCTRL | 软/FIFO/DMA 复位（`0x7`），bit1 FIFO 复位，bit31 CPU 访存 FIFO |
| 0x004 | CLKCR | bit16 时钟使能, bit17 省电, bit31 MASK_D0, [7:0] 分频 |
| 0x008 | TMOUT | 超时配置（初始化写 `0xffffff40`） |
| 0x00c | WIDTH | 0 = 1-bit, 1 = 4-bit |
| 0x010 | BLKSZ | 数据阶段块大小 |
| 0x014 | BYTECNT | 数据阶段总字节数 |
| 0x018 | CMD | bit31 启动, b21 UPCLK_ONLY, b15 INIT_SEQ, b13 WAIT_PRE, b10 WRITE, b9 DATA, b8/7/6 CRC/长响应/响应 |
| 0x01c | ARG | 命令参数 |
| 0x020 | RESP0 | 32 位响应（136 位响应在 RESP0..3） |
| 0x030 | IMASK | 全 0：不用中断 |
| 0x038 | RINT | b2 命令完成, b3 数据完成, b8 响应超时, 错误掩码 0xbfc2 |
| 0x03c | STATUS | b2 FIFO 空, b3 FIFO 满, b9 卡忙（R1b 判忙用） |
| 0x05c | NTSR | bit31 new timing 模式 |
| 0x078 | HWRST | 0 = 复位, 1 = 释放 |
| 0x200 | FIFO | PIO 数据端口（NCAT2） |

时钟（CCU，`ccu-sun20i-d1` 布局）：

- 模块时钟 `0x830 + 4N`：bit31 gate，bit24-26 mux（0 = HOSC 24 MHz），
  P b8-9、M b0-3，**固定后分频 2**，即有效源时钟 12 MHz；
- 总线 gate/复位 `0x84c`：gate bit N，reset bit 16+N；
- fanout gate `0xf30` bit4、fanout 配置 `0xf3c`：每通道 3 位源选择
  （0 = 32k）+ bit21+n gate。

`smhc_set_ios()` 的换频序列是 D1/T113 的坑点，Linux sunxi-mmc 同款：

1. 关 CLKCR_ENABLE、置 MASK_D0，发一次 UPCLK_ONLY 命令；
2. 写新分频 + ENABLE + MASK_D0，再发 UPCLK_ONLY；
3. 清掉 MASK_D0。

换频期间必须把 DATA0 屏蔽掉，否则卡时钟抖动会让总线上出现非法
电平。分频公式 `div = ceil(12M / (2*hz))` 保证实际时钟只会更低：

| 目标 | 分频 | 实际时钟 |
| --- | --- | --- |
| 400 kHz（识别/下载回退） | 15 | 400 kHz |
| 12 MHz（源时钟上限，提速目标） | 0 | 12 MHz |

XR829 驱动用 `mmc_set_clock(host, 12 MHz)` 提速，`mmc_set_clock(host, 0)`
回退到 host 的 `f_init`（400 kHz）。12 MHz 是本板 SMHC 源时钟
（HOSC 24 MHz 固定 /2）能给出的上限，配合 1-bit 总线；没有做
high-speed 模式（那需要 CMD6 切时序）。

命令超时/错误处理：轮询 RINT，命中错误掩码就按 RESP_TMO 区分
`-ETIMEDOUT` / `-EIO`；出错后控制器状态机可能卡死，所以每次错误都
做 `smhc_reset()` + 重设时钟再返回。

## HIF 寄存器与间接寻址

XR829 的 host 接口（HIF）固定在 SDIO function 1 的地址空间，遵循
xradio `hwio.h` 的寻址方式：

```text
SDIO 地址 = (buf_id << 7) | (reg_id << 2)
```

即 32 个 128 字节的 buffer 窗口；寄存器 id 在窗口内按 4 字节步进
（本驱动用到 0..6）。direct 模式用 buf_id 0 访问寄存器：

| reg_id | 名称 | 作用 |
| --- | --- | --- |
| 0 | HIF_CONFIG | 全局配置：访问模式、prefetch、CPU 复位/时钟、IRQ 使能、hw-type |
| 1 | HIF_CONTROL | WUP/RDY 握手、NEXT_LEN（待收消息长度） |
| 2 | HIF_IN_OUT_QUEUE | queue 模式的数据窗口 |
| 3 | HIF_AHB_DPORT | AHB 间接访问端口 |
| 4 | HIF_SRAM_BASE_ADDR | 间接访问的目标地址 |
| 5 | HIF_SRAM_DPORT | APB/SRAM 间接访问端口 |
| 6 | HIF_TSET_GEN_R_W | DPLL 配置寄存器（写完由硬件读取） |

CONFIG / CONTROL 关键位：

```text
CONFIG b10 ACCESS_MODE      1 = direct（端口）模式, 0 = queue（消息）模式
CONFIG b11 AHB_PFETCH       AHB 读预取中
CONFIG b12 CPU_CLK_DIS      CPU 时钟关
CONFIG b13 PFETCH           SRAM 读预取中
CONFIG b14 CPU_RESET        CPU 复位
CONFIG b16|b17 IRQ 使能
CONFIG b26 hw-type 标识     固件下载前必须为 1
CONTROL b11:0 NEXT_LEN      下一条消息长度（16-bit 字为单位）
CONTROL b12 WUP             写 0 唤醒设备
CONTROL b13 RDY             设备就绪
```

设备内存不在 SDIO 地址空间里，要通过间接窗口访问：

```text
写:  SRAM_BASE_ADDR = 目标地址
     CMD53 写 SRAM_DPORT（APB 空间）或 AHB_DPORT（AHB 空间）

读:  SRAM_BASE_ADDR = 目标地址
     CONFIG |= PFETCH（SRAM）或 AHB_PFETCH（AHB）
     轮询 CONFIG 直到该位清零（退避等待, 最多约 190 ms）
     CMD53 读对应端口
```

地址空间：

- AHB `0x08000000` 起：设备 CPU 的内存，bootloader 镜像写到这里；
- APB `0x09000000` 起：设备外设空间，下载 FIFO/控制块在这里；
- AHB `0x0ac80000`：WLAN 电源控制（PWRCTRL）寄存器组。

所有 HIF 传输都是地址自增的 CMD53（与 xradio 的 hwio 一致），
寄存器访问是 4 字节字节模式传输。

## 固件下载

### 镜像

| bootpack 名称 | 文件 | 大小 | 加载地址 | 作用 |
| --- | --- | --- | --- | --- |
| `boot_xr829` | boot_xr829.bin | 2184 B | 0x40100000 | 设备侧下载器（写 AHB 内存后由 CPU 执行） |
| `fw_xr829` | fw_xr829.bin | 174624 B | 0x40110000 | 主固件，经下载 FIFO 灌入 |
| `sdd_xr829` | sdd_xr829.bin | 744 B | 0x40140000 | RF/时钟校准数据，取参考时钟频率 |

目录里另有 `etf_xr829.bin`、`fw_xr829_bt.bin`（蓝牙固件），当前不打包。

### 流程

`xr829_load_firmware()` 按 xradio `fwio.c xradio_load_firmware()` 的
顺序执行：

1. 从 bootpack 取三个镜像；缺任何一个打印 `missing bootpack image`
   并放弃（probe 仍返回成功，保持绑定）。
2. CMD53 读 CONFIG，检查 hw-type 位（bit26）：不是 XRadio HIF 就退出。
3. 解析 SDD：遍历 `{u8 id, u8 len, data}` 元素，取 `0xc5`
   （reference frequency，kHz，小端 16 位），按表换算 DPLL 值：

   | 参考时钟 | DPLL 值 |
   | --- | --- |
   | 13 MHz | 0x1d89d241 |
   | 16 MHz | 0x000001e1 |
   | 16.8 MHz | 0x124931c1 |
   | 19.2 MHz | 0x00000191 |
   | 24 MHz | 0x00000141 |
   | 26 MHz | 0x0ec4f121 |
   | 33.6 MHz | 0x092490e1 |
   | 38.4 MHz | 0x100010c1 |
   | 40 MHz | 0x000000c1 |
   | 48 MHz | 0x000000a1 |
   | 52 MHz | 0x07627091 |

4. CMD53 把 DPLL 写进 TSET_GEN_R_W，延迟 5 ms 后回读校验。
5. CONTROL.WUP 写 0 唤醒设备，退避轮询 CONTROL.RDY（累计约 0.6 s）。
6. CONFIG 置 ACCESS_MODE（direct 端口模式）。
7. `update_dpllctrl()`：在 AHB 0x0ac80000 的 PWRCTRL 上等 WLAN 仲裁
   （ARBT 且非 BT），把 DPLL 值写进 DPLL_CTRL（带使能 bit0），再置
   COMMON_CFG.DONE；最后清 START_CFG。
8. `download_bootloader()`：把 boot_xr829 以 32 位字逐个写入 AHB
   0x08000000（每字一次 CMD53 AHB 间接写）。
9. 清 CONFIG.CPU_RESET 和 CPU_CLK_DIS，释放设备 CPU。
10. 轮询 APB 的 IMAGE_SIZE 寄存器直到读到 `I_AM_HERE`
    （100 × 10 ms）：设备侧 downloader 已跑起来。

然后 `download_firmware()`：

1. 初始化控制块：IMAGE_SIZE = `ARE_YOU_HERE`，PUT/GET = 0，
   STATUS = `PENDING`，FLAGS = 0。
2. 再次检查块大小：1024 必须能被 `f->blksz` 整除且 `blksz ≤ 1024`，
   否则设成 512。
3. IMAGE_SIZE = 实际镜像字节数。
4. 以 1 KiB 为块循环（镜像 171 块）：
   - 读 STATUS，必须仍是 PENDING；
   - 数据拷进 1 KiB 对齐缓冲，最后一块补零；
   - 等 FIFO 空间：`put - get <= 32 KiB - 1 KiB`（留一块余量）；
   - CMD53 把 1 KiB 写到 FIFO 环内偏移 `put & 0x7fff`；
   - `put += 实际字节数`，写回 PUT 寄存器；
   - 每 32 块打印一次进度（32/64/96/128/160 KiB）。
5. 退避轮询 STATUS 直到非 PENDING；必须等于 `SUCCESS`（0），否则
   打印 STATUS 和 TRACE_PC。
6. CONFIG 使能设备中断位（b16|b17），再清 ACCESS_MODE 切到
   queue（消息）模式，延迟 10 ms。

### 下载 FIFO 协议

```text
APB 0x09004000  32 KiB 下载 FIFO（put/get 环形窗口, 掩码 0x7fff）
APB 0x0900ff80  控制块:
  +0x00 IMAGE_SIZE    握手: ARE_YOU_HERE -> I_AM_HERE, 随后写镜像大小
  +0x04 FLAGS
  +0x08 PUT           生产者字节计数（host 更新）
  +0x0c TRACE_PC      失败时设备侧 PC
  +0x10 GET           消费者字节计数（设备更新）
  +0x14 STATUS        PENDING / SUCCESS / 错误码
```

常量：`ARE_YOU_HERE=0x87654321`、`I_AM_HERE=0x12345678`、
`PENDING=0xffffffff`、`SUCCESS=0`。

这是典型的单生产者/单消费者环形队列：host 只推进 PUT，设备只推进
GET；host 靠 `put - get` 判断剩余空间。最后一块补零写入但 PUT 只按
实际镜像长度推进，设备按 IMAGE_SIZE 截断。

### 进入 queue 模式

固件跑起来后，数据通路从“端口 + 间接地址”切换为“消息队列”：

- 读：`HIF_IN_OUT_QUEUE` 端口，RX buffer id 从 1 开始按
  `+1 & 3` 轮转（`buf_id_rx`）；
- 写：同一端口用 TX buffer id（当前仅初始化，尚未发送消息）；
- 消息长度由 CONTROL.NEXT_LEN 给出。

## WSM 首条消息

固件启动后通过 queue 主动推一条 WSM startup indication
（id `0x0801`），驱动把它当作“固件活着”的证据：

```text
xr829_read_first_message()
├── 轮询 CONTROL，直到 NEXT_LEN != 0（100 × 10 ms）
├── len = NEXT_LEN * 2（16-bit 字 -> 字节）
├── 读长度 = len + 2（消息头之后还有 2 字节的下一个 CONTROL 值）
│   ├── <= 512: 向上 4 字节对齐（字节模式）
│   └── >  512: 向上按 blksz 对齐（块模式）
├── buf_id = buf_id_rx + 1，CMD53 从 queue 端口读
└── 打印 WSM 头: id（h[1]）、len（h[0]），前几个数据字
```

WSM 头是两个小端 u16：`length` 在前、`id` 在后；`id & 0x0fff == 0x0801`
时标注 `(startup indication)`。队列读取失败或超时都会打印对应信息，
但不再重试。

## 固件打包与加载（bootpack）

固件比 SRAM 大得多，必须放在 DDR 里由 SPL 预加载。miniOS 用一个小
容器把 kernel 和附加镜像一起放到 SD 卡：

```text
SD 8 KiB      Boot0（miniBoot SPL）
SD 128 KiB    bootpack: 512 B header + 镜像, 每项 512 对齐
```

bootpack header（`src/include/t113/bootpack.h`，miniBoot、miniOS、
mkbootpack 三方共用）：

| 字段 | 说明 |
| --- | --- |
| magic / version | `"MPAK"` / 1 |
| count / total_size | 条目数（≤8）/ 总字节数 |
| entry[] | `name[16]`、offset、size、load_addr、crc32 |
| header_crc32 | 除本字段外整个 header 的 CRC32 |

SPL 按条目把镜像拷到 `load_addr` 并校验 CRC32，再把 header 复制到
`BOOTPACK_DDR_ADDR = 0x401ff000`，最后跳到 kernel。内核通过
`t113_bootpack_find(name)` 查条目，启动时 `t113_bootpack_dump()` 打印
全部条目。

DDR 布局（AUX 窗口是 kernel 下方的 2 MiB）：

```text
0x40000000  AUX_BASE
0x40100000  boot_xr829.bin   (2184 B)
0x40110000  fw_xr829.bin     (174624 B, 结束于 0x4013aa20)
0x40140000  sdd_xr829.bin    (744 B)
0x401ff000  bootpack header 副本
0x40200000  kernel（页分配器从这里往后）
```

打包由 `miniBoot/tools/mkbootpack.c` 完成：

```sh
mkbootpack bootpack.bin kernel=minios-kernel.bin@0x40200000 \
    boot_xr829=.../boot_xr829.bin@0x40100000 \
    fw_xr829=.../fw_xr829.bin@0x40110000 \
    sdd_xr829=.../sdd_xr829.bin@0x40140000
```

顶层 `rpi_bm/Makefile` 会自动处理：`firmware/xr829/` 下 boot/fw/sdd
三个文件齐全时填入 `BOOTPACK_EXTRA`，否则打印 `WiFi firmware not
packed` 并只打包 kernel。安装时 Boot0 写 8 KiB、bootpack 写 128 KiB：

```sh
make t113
make install T113_DISK=/dev/目标设备
```

## 预期串口输出

（地址、CRC、HIF 寄存器值和 WSM 数据以实测为准，下面是格式示例）

```text
bootpack: kernel @0x40200000 bytes=0x????????
bootpack: boot_xr829 @0x40100000 bytes=0x00000888
bootpack: fw_xr829 @0x40110000 bytes=0x0002aa20
bootpack: sdd_xr829 @0x40140000 bytes=0x000002e8
sdc1: SMHC host ready (card scan deferred to rescan)
mmc1: SDIO card rca 0x0001 OCR 0xffff0000 funcs 1 vendor 0x0a9e device 0x2282
mmc1: func 1 class 0x0000 vendor 0x0a9e device 0x2282
mmc1:0001:1: XRadio WiFi 0x0a9e:0x2282 enabled (IOEx 0x0002 IORx 0x0002 blksz 0x0200)
mmc1:0001:1: HIF_CONFIG 0x???????? (stable) HIF_CONTROL 0x????????
mmc1:0001:1: CMD53 write/read-back OK (HIF_TSET_GEN, 3 patterns)
mmc1:0001:1: SDIO clock 12000 kHz
mmc1:0001:1: SDD ref clock 26000 kHz, DPLL 0x0ec4f121
mmc1:0001:1: device awake
mmc1:0001:1: bootloader loaded (2184 bytes)
mmc1:0001:1: bootloader answered I_AM_HERE
mmc1:0001:1: firmware 32 KiB
mmc1:0001:1: firmware 64 KiB
mmc1:0001:1: firmware 96 KiB
mmc1:0001:1: firmware 128 KiB
mmc1:0001:1: firmware 160 KiB
mmc1:0001:1: firmware download complete (174624 bytes)
mmc1:0001:1: firmware running
mmc1:0001:1: WSM msg id 0x0801 len 0x???? (startup indication) data 0x???? 0x???? ...
```

## 排障提示

启动阶段：

- `mmc1: no SDIO card (CMD5 timeout)`——先查 WL_REG_ON 电平和 32k
  fanout 是否真的在输出（`smhc_dump()` 会打印 FANOUT_GATE/CFG 和
  PG 组引脚配置）；
- `card OCR has no 2.7-3.6V window`——R4 回来了但 OCR 位图异常，
  多半是总线信号质量（CLK 上没串 33R 就容易出这个）；
- `card never became ready (CMD5)`——模组在初始化，可适当加大
  `power_on_delay_ms`；
- `no sdio driver matched (N registered)`——vendor/device 不在
  `xr829_ids[]` 里，看上一行打印的实测 ID；
- `missing bootpack image ...`——固件没打进 bootpack：确认
  `firmware/xr829/` 三个文件存在，重跑 `make t113`（make 阶段应有
  `NOTE: ... missing: WiFi firmware not packed` 提示）。

CMD53 与固件下载：

| 打印 | 含义 |
| --- | --- |
| `CMD53 not working; firmware download impossible` | HIF 寄存器读/写失败；查 pinmux、PIO FIFO 和总线时钟 |
| `CMD53 fails at the fast clock, back to the init clock` | 12 MHz 下总线不稳，已回退 400 kHz，下载变慢但仍可完成 |
| `not an XRadio HIF (CONFIG)` | CONFIG 的 hw-type 位不是 1：芯片/固件不匹配或访问错窗口 |
| `DPLL register did not stick` | TSET_GEN 写入没生效，检查间接/直连访问模式 |
| `device did not wake up, CONTROL` | WUP 后 RDY 未置位：DPLL 或 32k 时钟问题 |
| `DPLL access timeout, COMMON_CFG` | WLAN PWRCTRL 仲裁一直没拿到（BT 占用或时钟未起） |
| `bootloader not ready, IMAGE_SIZE reads` | boot_xr829 没跑起来：AHB 载入地址/CPU 释放/镜像损坏 |
| `bootloader reported error` | 设备侧 downloader 拒收，看 STATUS 值 |
| `timeout waiting for download FIFO` | GET 长时间不推进，设备侧卡住 |
| `firmware download failed, status ... trace pc ...` | 下载失败，TRACE_PC 是设备侧出错位置 |
| `no WSM message from firmware, CONTROL` | 固件下载成功但没发 startup indication，通常是 fw/sdd 版本不匹配 |

## 当前边界与下一步

已实现：

- SDIO 枚举、CCCR/FBR/CIS、CMD52；
- CMD53 字节/块模式 + SMHC PIO 数据阶段；
- HIF 寄存器、SRAM/AHB 间接寻址、prefetch；
- SDD 参考时钟解析、DPLL 配置、设备唤醒；
- bootloader 载入、1 KiB 分块固件下载、下载 FIFO 协议；
- queue 模式切换与首条 WSM 消息读取。

未实现（按依赖顺序）：

1. **HIF queue 收发层**：TX/RX buffer 管理、NEXT_LEN 驱动的消息循环、
   主机侧中断/轮询调度（目前只读一条消息）；
2. **WSM 协议**：confirm/indication 状态机，扫描、认证、关联；
3. **802.11 数据面 + TCP/IP 栈**；
4. 可选：SMHC DMA、high-speed 时序、蓝牙固件（fw_xr829_bt.bin）
   与 ETF 测试镜像。

其他刻意简化：卡/函数结构用静态池（`card_pool[3]`、`func_pool[21]`，
外加 1 KiB 的静态下载缓冲）而不是分配器；所有等待用 `mdelay`/`udelay`
忙等；固件下载在 probe 内同步完成，尚未搬到工作队列。
