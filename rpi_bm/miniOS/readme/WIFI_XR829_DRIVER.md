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

主机侧没有接 SDIO 中断（IRQ 73 已声明但全部轮询），整条 WiFi 链路
是轮询驱动的。

> 更新：STA JOIN、WPA2 四次握手（EAPOL）和 IPv4/UDP/DHCP/tftp 都已
> 实现，网络栈和驱动已按 Linux 分层重新组织（cfg80211 / mac80211 /
> supplicant / xradio 驱动拆分），网络栈细节见
> [NET_STACK.md](NET_STACK.md)；`/boot` 固件加载已改为内核直接读写
> FAT32，见 [BOOT_FAT32.md](BOOT_FAT32.md)。本文硬件、SDIO 和固件
> 下载部分的说明不变，"文件组成""分层结构"两节已按新文件名更新。

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

## 图解：硬件连接与上电时序

```text
              T113-S3（Cortex-A7）                                    XR829 WiFi/BT 模组
┌──────────────────────────────────────────┐                ┌──────────────────────────────────┐
│ SMHC1  @0x04021000（sunxi-smhc.c）        │                │ SDIO 从设备                       │
│   CLK  ── PG0  func2 ──[33R]─────────────┼───────────────→│ SDIO_CLK                          │
│   CMD  ── PG1  func2  上拉 ──────────────┼←──────────────→│ SDIO_CMD    命令/响应              │
│   D0   ── PG2  func2  上拉 ──────────────┼←──────────────→│ SDIO_D0     数据（1-bit 只用 D0）   │
│   D1-3 ── PG3..PG5 func2 上拉 ───────────┼←──────────────→│ SDIO_D1..D3（4-bit 模式才用）       │
│                                          │                │                                  │
│ CCU CLK_FANOUT1 ── PG11 func5 ───────────┼── 32.768 kHz ─→│ LPO 睡眠时钟（模组内无 RTC 晶振）   │
│ GPIO PG12 输出 ──────────────────────────┼── WL_REG_ON ──→│ 电源/复位使能，高有效              │
│ GPIO PG10（未用）←───────────────────────┼── WL_WAKE_AP ──│ 唤醒主机（当前全部轮询）            │
│ GIC IRQ 73（SPI 41，已声明未用）          │                │                                  │
│                                          │                │ 内部 CPU                         │
│ SMHC0  @0x04020000 ── PF0..PF5 ──→ TF 卡  │                │   AHB 0x08000000  代码/数据 RAM    │
│   分区 1 FAT32：/boot/*_xr829.bin        │ ── 固件来源     │   APB 0x09000000  下载 FIFO/控制块 │
│   分区 2 minifs：/                       │                │   PWRCTRL 0x0ac80000              │
└──────────────────────────────────────────┘                │ 2.4 GHz 射频 ── 天线               │
                                                            └──────────────────────────────────┘
```

两个 SD 控制器分工明确：SMHC0 接 TF 卡，负责根文件系统和 `/boot`；
SMHC1 接 XR829。WiFi 驱动启动时，要先经 SMHC0 从 FAT32 读出三个固件文件，
再经 SMHC1 灌进模组。

上电时序在 `smhc_power()`（`sunxi-smhc.c`）里，由 `sdio_attach_card()` 在
发 CMD0 之前调用：

```text
                smhc_power(host, 1)                              sdio_attach_card()
                |                                                |
32k FANOUT1  ___+-----------------------------------------------------------------
                 (1) CCU 0xf30 bit4 开 fanout 门控，0xf3c 选 32k 源并开 fanout1，PG11 切 func5
WL_REG_ON    ------+                    +---------------------------------------------
                   |____________________|
                   (2) 拉低             (3) 拉高
                   |<----- 10 ms ------>|<----- power_on_delay_ms = 100 ms ----->|
SDIO_CLK                                                                 400 kHz |||||||
CMD 线                                                                   CMD0 -> CMD5 ...
```

32k 时钟必须先于 WL_REG_ON 拉高：XR829 的内部电源管理靠它计时，没有它模组
不会响应 CMD5。`PLL_PERIPH0` 没开时 fanout 也出不来，`smhc_power()` 会打印
提示。

## 文件组成

| 文件 | 角色 |
| --- | --- |
| `src/drivers/mmc/host/sunxi-smhc.c` | SMHC（sunxi-mmc）主机控制器驱动：命令 + PIO 数据阶段，platform 总线驱动，轮询 |
| `src/drivers/mmc/core.c` | 轻量 MMC/SDIO core：CMD52/CMD53、CCCR/CIS 解析、sdio 总线、卡枚举、`mmc_set_clock()` |
| `src/drivers/net/wireless/xradio/sdio.c` | SDIO function 驱动 `xradio_sdio_driver`：probe/remove、CMD53 自检、提速 |
| `src/drivers/net/wireless/xradio/hwio.c` | HIF 寄存器、APB/AHB 间接访问 |
| `src/drivers/net/wireless/xradio/fwio.c` | DPLL、bootloader 与固件下载、SDD |
| `src/drivers/net/wireless/xradio/bh.c` | 底半部：HIF 队列读写、序号、固件输入缓冲计数 |
| `src/drivers/net/wireless/xradio/wsm.c` | WSM 命令编码、confirm、indication 分派、MIB、TX |
| `src/drivers/net/wireless/xradio/main.c` | 核心 probe：固件 → WSM 启动 → CONFIGURATION → 注册到 mac80211 |
| `src/drivers/net/wireless/xradio/sta.c` | `ieee80211_ops`：start、JOIN/关联参数、set_key、poll |
| `src/drivers/net/wireless/xradio/scan.c`、`txrx.c` | 硬件扫描；802.11 帧 ↔ WSM TX/RX |
| `src/drivers/net/wireless/xradio/{xradio,wsm,hwio}.h` | 驱动私有头文件（WSM wire-format、HIF 定义） |
| `src/net/`（core、ethernet、ipv4、wireless、mac80211、wpa、tftp） | 网络栈，见 NET_STACK.md |
| `src/lib/crypto/wpa_crypto.c`、`src/include/crypto/wpa_crypto.h` | 通用 WPA2-PSK 密码学 |
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
   mmc1:0001:1 ──match──>  xradio_sdio_driver ("xradio_wlan")
                                  │ probe (sdio.c):
                                  │   使能 function, 设块大小 512
                                  │   CMD53 自检 -> 提速到 12 MHz
                                  │ xradio_core_probe (main.c):
                                  │   fwio.c 下载固件 -> WSM startup
                                  │   CONFIGURATION -> ieee80211_register_hw
                                  ▼
                       struct xradio_common -> mac80211 -> wlan0
```

代码目录按 Linux 的 bus/core/protocol/MLME 边界组织：

```text
src/drivers/mmc/
├── host/sunxi-smhc.c      SoC host controller（硬件层）
└── core.c                 MMC/SDIO core 与 sdio_bus（总线层）

src/drivers/net/wireless/xradio/
├── sdio.c                 sdio_driver
├── hwio.c / fwio.c        HIF 访问 / 固件下载
├── bh.c / wsm.c           消息传输 / WSM 协议
├── main.c                 核心 probe，注册到 mac80211
└── sta.c scan.c txrx.c    ieee80211_ops 实现

src/net/mac80211/ src/net/wireless/ src/net/wpa/   802.11 状态机、cfg80211、supplicant
src/lib/crypto/wpa_crypto.c    与具体网卡无关的 WPA2 primitive
```

依赖方向保持单向：板级 SMHC → SDIO core → xradio 驱动 → mac80211 →
cfg80211 → supplicant；`wpa_crypto` 只提供算法，不反向依赖驱动。

数据面走的是 SDIO function 1 的 CMD53：

```text
hwio.c
├── xradio_reg_read_32/write_32()   CMD53 4 字节, 访问 HIF 寄存器窗口
├── xradio_apb_write/apb_read_32()  SRAM_BASE_ADDR + SRAM_DPORT 间接访问 APB
├── xradio_ahb_write_32/read_32()   SRAM_BASE_ADDR + AHB_DPORT 间接访问 AHB
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
| `xradio_reg_*` / HIF id | xradio `hwio.c` 的 `xradio_reg_read_32()` 等 |
| 固件下载流程 | xradio `fwio.c` 的 `xradio_load_firmware()` |

## 总调用链

从驱动核心初始化到 `wlan0` 注册：

```text
kernel_boot()
└── t113_driver_core_init()                          boards/100ask_t113/driver_model.c
    ├── platform_bus_init() / i2c_bus_init() / sdio_bus_init()
    ├── t113_board_register_devices()
    │   └── platform_device_register(&sdc1_device)   只登记，不碰硬件
    ├── t113_board_register_drivers()
    │   ├── platform_driver_register(&t113_smhc_driver)
    │   │   └── t113_smhc_probe(sdc1)                drivers/mmc/host/sunxi-smhc.c
    │   │       ├── platform_get_resource()          SMHC1 基址 0x04021000
    │   │       ├── CCU 0x84c：复位 → 开门控；0x834：mod clock = HOSC（/2 后 12 MHz）
    │   │       ├── t113_pinmux_apply(sdc1_pins)     PG0..PG5 func 2
    │   │       ├── smhc_reset()；HWRST 拉低 10 us 再拉高
    │   │       ├── NTSR |= NEW_MODE；TMOUT；IMASK = 0（不用中断）
    │   │       ├── smhc_set_ios(400 kHz, 1-bit)
    │   │       └── mmc_add_host()                   卡扫描推迟
    │   └── sdio_driver_register(&xradio_sdio_driver)    总线上还没有设备
    └── mmc_rescan_all()                             不在任何 probe 里，避免持锁注册设备
        └── sdio_attach_card(host) → sdio_add_funcs(host)   （上一节的状态机）
            └── device_register(func) → xradio_sdio_probe(func)      xradio/sdio.c
                ├── sdio_enable_func()、sdio_set_block_size(512)
                ├── xradio_cmd53_selftest(verbose = 1)
                │   ├── CMD53 读 HIF_CONFIG 两次，必须一致
                │   └── CMD53 写/读 HIF_TSET_GEN 三组模式，再恢复原值
                ├── mmc_set_clock(12 MHz) + 自检；失败 → mmc_set_clock(0) 回 400 kHz
                └── xradio_core_probe(func)                          xradio/main.c
                    ├── xradio_load_firmware(hw_priv)                xradio/fwio.c
                    │   ├── need_image("/boot/boot_xr829.bin")       经 VFS → FAT32 → SMHC0
                    │   ├── need_image("/boot/fw_xr829.bin")
                    │   ├── need_image("/boot/sdd_xr829.bin")        SDD 留在内存给 CONFIGURATION
                    │   ├── CONFIG 的 hw-type 位检查
                    │   ├── parse_sdd() → DPLL；写 TSET_GEN 并回读
                    │   ├── CONTROL.WUP，等 RDY；CONFIG |= ACCESS_MODE
                    │   ├── update_dpllctrl()
                    │   ├── download_bootloader()   AHB 0x08000000，逐字写
                    │   ├── download_firmware()     释放 CPU，握手，1 KiB 块写下载 FIFO
                    │   └── CONFIG：开 IRQ 位，清 ACCESS_MODE → queue 模式
                    ├── wsm_init(func, 2000)                         xradio/wsm.c
                    │   ├── xradio_bh_init(func)                     xradio/bh.c
                    │   ├── 循环 xradio_bh_poll(10)，直到 STARTUP 0x0801
                    │   │   └── parse_startup()：num_bufs、buf_size、固件版本
                    │   │       └── xradio_bh_set_caps()              流控上限
                    │   └── CONTROL = WUP                            保持唤醒
                    ├── xradio_setup_mac()
                    │   ├── wsm_configuration(MAC, SDD)              CONFIGURATION 0x0009
                    │   └── wsm_read_mib(CURRENT_TX_POWER)           诊断
                    ├── ieee80211_alloc_hw(&xradio_ops, hw_priv)     net/mac80211/main.c
                    └── ieee80211_register_hw(hw, mac, xradio_rates, 12)
                        ├── wiphy_new() / wiphy_register()           cfg80211
                        ├── xradio_start()                           ops->start
                        │   ├── OPERATIONAL_POWER_MODE MIB
                        │   ├── wsm_set_edca_default()               4 个 AC 的 EDCA
                        │   └── wsm_set_tx_policies()                速率重试表
                        └── register_netdev(wlan0)
                            └── NETDEV_REGISTER 通知 → wpa_netdev_event()   自动连接
```

## 初始化顺序与驱动核心约束

`device_register()` 会拿驱动核心锁并触发匹配绑定（probe 也在同一把
锁下运行）。卡枚举要注册 `sdio_func` 设备，如果放在 SMHC 的 probe 里
就会在持锁状态下再次注册设备——死锁。所以
`t113_driver_core_init()` 先把所有设备、驱动注册完，最后统一调
`mmc_rescan_all()`，对应 Linux 把 `mmc_rescan` 扔进 workqueue 的做法。

同理，注册顺序也有要求：`xradio_sdio_driver` 必须在 `mmc_rescan_all()`
之前注册，否则 function 设备注册时找不到驱动（本模型没有
deferred-probe 重试；未绑定时会打印 `no sdio driver matched`）。

另一个后果是：**整段固件下载都在 xradio_sdio_probe() 里、在驱动核心锁下
忙等完成**。这在 Linux 里不可接受（probe 必须快、可睡眠），这里因为
只有这一个 SDIO 设备、且下载在 12 MHz 下只需约 0.2 s 量级（失败回退
到 400 kHz 时约数秒），所以先保持最简单的同步实现。后续接中断/工作
队列时应把固件下载移出 probe。

`xradio_sdio_probe()` 即使 CMD53 或固件下载失败也返回 0，保持绑定关系，
方便驱动模型打印出设备状态并在串口留下诊断信息（若 probe 返回负值，
绑定不会建立，现场更难分析）。

## 图解：SDIO 协议与初始化

### 命令与响应的格式

SDIO 沿用 SD 卡的物理层：主机在 CMD 线上发 48 位命令，卡在 CMD 线上回响应，
数据走 D0（4-bit 模式下走 D0–D3）。

```text
命令（主机 → 卡，48 位）
 47   46   45 ...... 40   39 .................. 8   7 ... 1   0
┌───┬────┬────────────┬────────────────────────┬─────────┬───┐
│ 0 │ 1  │ 命令号 6 位 │ 参数 32 位              │ CRC7    │ 1 │
└───┴────┴────────────┴────────────────────────┴─────────┴───┘
 起始 方向=主机                                           结束

SMHC 只要软件给出“命令号 + 参数 + 期望的响应类型”，起始位、CRC7 和结束位由硬件生成：
  SMHC_ARG = 参数
  SMHC_CMD = START | 命令号 | RESP_EXPIRE [| LONG_RESP] [| CHK_CRC] [| DATA | WAIT_PRE [| WRITE]]
  轮询 SMHC_RINT 等 CMD_DONE（有数据时再等 DATA_OVER）
  SMHC_RESP0 = 响应里的 32 位内容
```

SDIO 初始化用到的命令和响应：

| 命令 | 名称 | 参数 | 响应 | miniOS 用它做什么 |
| --- | --- | --- | --- | --- |
| CMD0 | GO_IDLE_STATE | 0 | 无 | 复位卡的状态机；带 `INIT_SEQ` 位，让 SMHC 先发初始化时钟（规范要求至少 74 个） |
| CMD5 | IO_SEND_OP_COND | 0，之后是 OCR | R4 | 先问电压窗口，再反复协商直到就绪 |
| CMD3 | SEND_RELATIVE_ADDR | 0 | R6 | 卡给出 16 位 RCA |
| CMD7 | SELECT_CARD | RCA << 16 | R1b | 选中卡，进入可传输状态 |
| CMD52 | IO_RW_DIRECT | 见下 | R5 | 读写一个字节：CCCR、FBR、CIS |
| CMD53 | IO_RW_EXTENDED | 见下 | R5 + 数据 | 批量读写：HIF 寄存器、下载 FIFO、消息队列 |

响应里用到的位：

```text
R4（CMD5，无 CRC）
 31   30..28      27   26..24   23 ............... 0
┌───┬──────────┬────┬────────┬─────────────────┐
│ C │ 功能数    │ MP │ 保留    │ OCR 电压窗口     │   C = 1：卡已就绪
└───┴──────────┴────┴────────┴─────────────────┘   miniOS 取 OCR & 0x00ff8000（2.7–3.6 V）

R6（CMD3）
 31 ......... 16   15 ......... 0
┌──────────────┬──────────────┐
│ RCA          │ 卡状态        │
└──────────────┴──────────────┘

R5（CMD52/CMD53）
 31 ... 16   15        14        13..12    11     10   9        8      7 ...... 0
┌─────────┬─────────┬─────────┬─────────┬──────┬────┬────────┬──────┬──────────┐
│ 保留     │ CRC 错  │ 非法命令 │ IO 状态  │ 错误 │ 0  │ 功能号错│ 越界  │ 读到的数据 │
└─────────┴─────────┴─────────┴─────────┴──────┴────┴────────┴──────┴──────────┘
R5_ERROR_MASK = 0xcb00（位 15、14、11、9、8），命中就返回 -EIO
```

### 初始化状态机

```text
sdio_attach_card(host)                            drivers/mmc/core.c
│
├── smhc_power(host, 1)                           32k + WL_REG_ON 时序
├── set_ios(400 kHz, 1-bit)
│
├── CMD0                        卡：任何状态 → Idle
├── CMD5  arg = 0       → R4    读 OCR 和功能数，不改变状态
│     OCR & 0x00ff8000 == 0 → "card OCR has no 2.7-3.6V window"
├── CMD5  arg = ocr     → R4    循环，每次间隔 10 ms，最多 100 次
│     R4.C == 1  →  卡：Idle → Ready
├── CMD3                → R6    RCA；卡：Ready → Stand-by
├── CMD7  RCA << 16     → R1b   卡：Stand-by → Command（可以收发数据）
│
├── CMD52 读 CCCR 0x00          CCCR/SDIO 版本
├── CMD52 读 CCCR 0x08          能力位
├── CMD52 读 CCCR 0x09..0x0b    公共 CIS 指针
│     └── parse_cis_manfid()    沿元组链表找 CISTPL_MANFID(0x20)
│                               → vendor 0x0a9e，device 0x2282
└── sdio_add_funcs(host)        对每个 function n = 1..功能数
      ├── CMD52 读 FBR n×0x100 + 0x00     标准接口类别
      ├── CMD52 读 FBR n×0x100 + 0x09     本 function 的 CIS 指针 → MANFID
      └── device_register(&func->dev)     名字 "mmc1:0001:1"
            └── sdio_bus_match()          按 xradio_sdio_ids[] 匹配
                  └── xradio_sdio_probe(func)            xradio/sdio.c
                        ├── sdio_enable_func()
                        │   ├── CMD52 读改写 CCCR 0x02 IOEx |= 1 << 1
                        │   └── CMD52 轮询 CCCR 0x03 IORx bit1   function 1 就绪
                        ├── sdio_set_block_size(512)
                        │   └── CMD52 写 FBR1 + 0x10 = 0x00，+ 0x11 = 0x02
                        ├── xradio_cmd53_selftest(verbose)      CMD53 能不能用
                        ├── mmc_set_clock(12 MHz) → 再自检一次，不行退回 400 kHz
                        └── xradio_core_probe(func)            进入固件阶段
```

miniOS 没有发 CMD52 去写 CCCR 0x07（总线宽度），所以卡一直停在默认的 1-bit
模式；也没有用 CMD52 写 CCCR 0x04（IENx）打开卡中断。这两项是 Linux 的
`mmc_attach_sdio()` 会做、而 miniOS 刻意省掉的。

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
bit 15     COM_CRC_ERROR     CRC 校验失败
bit 14     ILLEGAL_COMMAND
bit 13:12  IO_CURRENT_STATE  卡的 I/O 状态，不算错误
bit 11     ERROR             通用错误
bit  9     FUNCTION_NUMBER   function 号超范围
bit  8     OUT_OF_RANGE      地址超范围
```

封装（`drivers/mmc/core.c`）：

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
`xradio_sdio_ids[]` 两个都匹配，另外各留一条只限 vendor 的兜底项：

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
- HIF 寄存器访问封装成 `xradio_reg_read_32/write_32()`（4 字节，hwio.c），
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

`sunxi-smhc.c` 是命令级轮询驱动：命令 + PIO 数据，不接中断。

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

`xradio_load_firmware()` 按 xradio `fwio.c xradio_load_firmware()` 的
顺序执行：

1. `need_image()` 经 VFS 从 `/boot` 读三个镜像（正常是 FAT32；FAT32 挂载失败时是 bootfs 的 DDR 视图）。缺任何一个就打印 `cannot load <路径>` 并放弃，`xradio_sdio_probe()` 仍返回 0，保持绑定。
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
- 写：同一端口用 TX buffer id（`buf_id_tx` 在 0..31 间轮转，见“通信协议”一节）；
- 消息长度由 CONTROL.NEXT_LEN 给出。

## 通信协议：从 SDIO 到 WSM

### 协议分层

```text
┌─────────────────────────────────────────────────────────────────┐
│ 802.11 帧（mac80211 组好的管理帧、数据帧）                          │  net/mac80211
├─────────────────────────────────────────────────────────────────┤
│ WSM 消息：{u16 len, u16 id} + 负载                                 │  xradio/wsm.c
│   请求 0x00xx → confirm 0x04xx；固件主动发 indication 0x08xx        │
├─────────────────────────────────────────────────────────────────┤
│ HIF 队列：IN_OUT_QUEUE 端口、buf_id 轮转、3 位序号、NEXT_LEN、       │  xradio/bh.c
│           固件输入缓冲计数                                          │
├─────────────────────────────────────────────────────────────────┤
│ HIF 寄存器窗口：SDIO 地址 = HIF_ADDR(buf_id, reg_id)                │  xradio/hwio.c
├─────────────────────────────────────────────────────────────────┤
│ SDIO：CMD52 一个字节（function 0 配置空间）                          │  drivers/mmc/core.c
│       CMD53 多字节（function 1，字节模式 ≤ 512 B，或 512 B 块模式）  │
├─────────────────────────────────────────────────────────────────┤
│ SMHC1：命令寄存器 + FIFO，CPU 轮询搬运                               │  mmc/host/sunxi-smhc.c
├─────────────────────────────────────────────────────────────────┤
│ CLK / CMD / D0                                                    │
└─────────────────────────────────────────────────────────────────┘
```

XR829 的 HIF 有两种工作模式，`CONFIG.ACCESS_MODE`（bit10）切换：

| 模式 | 何时 | 怎么访问设备 |
| --- | --- | --- |
| direct（ACCESS_MODE = 1） | 固件下载期间 | 寄存器窗口 + `SRAM_BASE_ADDR` 间接访问 AHB/APB 内存 |
| queue（ACCESS_MODE = 0） | 固件跑起来以后 | 只通过 `IN_OUT_QUEUE` 端口收发 WSM 消息 |

### HIF 地址

```text
CMD53 参数里的 17 位地址（function 1）
 16 ... 12   11 ...... 7    6 ...... 2    1  0
┌──────────┬─────────────┬───────────┬──────┐
│    0     │ buf_id 5 位  │ reg_id    │ 0  0 │
└──────────┴─────────────┴───────────┴──────┘
HIF_ADDR(buf_id, reg_id) = (buf_id & 0x1f) << 7 | reg_id << 2

寄存器访问：buf_id = 0，reg_id = 0..6（CONFIG、CONTROL、IN_OUT_QUEUE、AHB_DPORT、
                                     SRAM_BASE_ADDR、SRAM_DPORT、TSET_GEN）
队列写：    buf_id = tx 序号 0..31，reg_id = 2      每写一条消息 +1
队列读：    buf_id = rx 序号 + 1（1..4），reg_id = 2  每读一次 +1，模 4
```

### WSM 消息格式

```text
字节  0 ...... 1      2 ............... 3      4 ...
    ┌─────────────┬──────────────────────┬──────────────┐
    │ len（LE）    │ id（LE）              │ 负载           │   len 含这 4 字节头
    └─────────────┴──────────────────────┴──────────────┘

id 的位
 15 ... 13   12   11   10    9 ...... 6     5 ...... 0
┌─────────┬────┬────┬────┬───────────┬──────────────┐
│ 序号     │保留│ IND│ CFM│ 接口/链路号│ 消息号        │
└─────────┴────┴────┴────┴───────────┴──────────────┘
WSM_MSG_ID(id) = id & 0x0c3f     去掉序号和链路号
0x00xx 请求    0x04xx confirm（= 请求 | 0x0400）   0x08xx indication
```

TX 请求（`wsm_tx_frame()`，0x0004）在 4 字节头之后还有 20 字节，一共 24 字节：

| 偏移 | 字段 | miniOS 填什么 |
| --- | --- | --- |
| 4 | packetID（u32） | mac80211 的 cookie，TX confirm 原样带回 |
| 8 | queueId | 链路号左移 2 位再加队列号；STA 的链路号是 0，队列 VO 3、VI 2、BE 0、BK 1 |
| 9 | more | 0 |
| 10 | DataOffset | 24，802.11 帧从这里开始 |
| 11 | EPTA 优先级 | 0 |
| 12 | TxRateEntry（u16） | 管理帧 0x000f，数据帧 0x00a4 |
| 14 | TxPolicyIndex | 管理帧 0，数据帧 1 |
| 15 | ExpireTimeSetting | 0 |
| 16 | expireTime（u32）+ 保留 | 0，用固件默认 |
| 24 | 802.11 帧 | 头 + 数据，不带 FCS |

RX indication（0x0804）的 16 字节头：

| 偏移（相对负载） | 字段 |
| --- | --- |
| 0 | status（u32），非 0 表示出错或没有钥匙，驱动丢弃 |
| 4 | channel（u16） |
| 6 | 收到的速率表项（u16） |
| 11 | RCPI/RSSI |
| 12 | flags（u32），低 3 位是加密类型：0 无、2 TKIP、3 AES |
| 16 | 802.11 帧（固件已解密，但 IV 和 MIC 还在） |

用到的消息：

| 方向 | id | 名字 | 谁处理 |
| --- | --- | --- | --- |
| 请求 | 0x0004 | TX | `wsm_tx_frame()` |
| 请求 | 0x0005 / 0x0006 | READ_MIB / WRITE_MIB | `wsm_read_mib()` / `wsm_write_mib()` |
| 请求 | 0x0007 | START_SCAN | `wsm_scan()` |
| 请求 | 0x0009 | CONFIGURATION（带 SDD） | `wsm_configuration()` |
| 请求 | 0x000b | JOIN | `wsm_join()` |
| 请求 | 0x000c / 0x000d | ADD_KEY / REMOVE_KEY | `wsm_add_key_*()` / `wsm_remove_key()` |
| 请求 | 0x0010 / 0x0011 / 0x0013 | SET_PM / SET_BSS_PARAMS / SET_EDCA | `sta.c` |
| confirm | 0x0404 / 0x041e | TX confirm / 多个 TX confirm | `xradio_tx_confirm_cb()` |
| indication | 0x0800 | EXCEPTION | 打印并 `xradio_bh_halt()` |
| indication | 0x0801 | STARTUP | `parse_startup()` |
| indication | 0x0804 | RX | `xradio_rx_cb()` |
| indication | 0x0805 | EVENT（BSS_LOST 等） | `xradio_event_cb()` |
| indication | 0x0806 | SCAN_COMPLETE | `xradio_scan_complete_cb()` |
| indication | 0x0809 | SET_PM 完成 | 记标志 |

### 一次队列传输

```text
读（rx_one）
├── 有上次捎带的 CONTROL 就用它，否则 CMD53 读 HIF_CONTROL（4 字节）
├── len = NEXT_LEN × 2（NEXT_LEN 以 16 位字为单位）；为 0 表示没有消息
├── rd = align_len(len + 2)          ≤ 512 → 4 字节对齐的字节模式
│                                     > 512 → 512 B 的整数块
├── CMD53 读 HIF_ADDR(buf_id_rx + 1, IN_OUT_QUEUE)，rd 字节
├── 末尾 2 字节 = 下一个 CONTROL 值（捎带，省一次寄存器读）
├── 校验 3 位序号（期望 rx_seq，之后 +1 模 8）
└── 一次传输里可能有多条消息（multi-rx），逐条：
    ├── release_buffers()            confirm 归还固件输入缓冲
    └── wsm_handle_rx()

写（xradio_bh_tx）
├── while hw_bufs_used ≥ num_bufs：xradio_bh_poll(10)   等 confirm 还缓冲，最多 2 s
├── 写 len，把 tx_seq 填进 id 的 15..13 位
├── wlen = align_len(len)，短消息至少 16 字节，补零
├── CMD53 写 HIF_ADDR(buf_id_tx, IN_OUT_QUEUE)
└── buf_id_tx = (buf_id_tx + 1) & 31；tx_seq++；hw_bufs_used++
```

### 流控：固件输入缓冲

STARTUP indication 告诉主机固件有几个输入缓冲（`num_bufs`）、每个多大
（`buf_size`）。每个请求（包括 TX）占一个，每个 confirm 还一个：

```text
主机 hw_bufs_used                          固件输入缓冲（num_bufs 个）
0 ── wsm_cmd(JOIN) ─ CMD53 写 ───────────→ [J][ ][ ][ ]...        1
1 ── wsm_tx_frame(EAPOL M2) ─────────────→ [J][T][ ][ ]...        2
2 ←─ JOIN confirm 0x040b ─ CMD53 读 ────── [ ][T][ ][ ]...        1   release_buffers()
1 ←─ TX confirm 0x0404（packetID）──────── [ ][ ][ ][ ]...        0
满 → xradio_bh_tx() 先轮询收 confirm，腾出缓冲再写
```

### 命令和 confirm 的配对

```text
wsm_cmd(req, payload, len, cfm, cap, timeout)
├── mutex_lock(&command_mutex)                一次只有一个命令在等
├── wait_cfm = req | 0x0400，cfm_done = 0
├── xradio_bh_tx(cmd_buf)
├── while !cfm_done：xradio_bh_poll(5)         自己驱动底半部
│   └── rx_one → wsm_handle_rx
│       ├── id == wait_cfm → 拷负载，cfm_status = 负载前 4 字节，cfm_done = 1
│       ├── TX confirm → ieee80211_tx_status()   照常分派，不影响等待
│       └── indication → 各自回调（只入队或记标志）
└── 返回 cfm_status（0 = WSM_STATUS_SUCCESS）
```

Linux 的 xradio 用 `wait_event_timeout()` 睡眠，由 bh 线程收到 confirm 后
唤醒；miniOS 没有中断也没有 bh 线程，等 confirm 的人自己调
`xradio_bh_poll()`。为防止回调里再次进入底半部，`bh.in_rx` 会让嵌套的
`xradio_bh_poll()` 返回 `-EBUSY`。

### 启动握手

固件下载完、切到 queue 模式后，固件先主动发 STARTUP indication。驱动在
它之前不能发任何命令：

```text
xradio_core_probe()
├── xradio_load_firmware()        结束时 ACCESS_MODE = 0（queue 模式）
├── wsm_init(func, 2000)
│   ├── xradio_bh_init()          num_bufs = 1，序号和 buf_id 清零
│   └── 循环 xradio_bh_poll(10)
│       └── wsm_handle_rx(0x0801) → parse_startup()
│           ├── num_bufs、buf_size → xradio_bh_set_caps()
│           ├── hw_id、fw_type、fw_api、固件标签
│           └── status == 0 → wsm.ready = 1
├── CONTROL = WUP                 一直保持唤醒（不做省电）
└── wsm_configuration(MAC, SDD)   第一条命令必须是 CONFIGURATION：把 SDD 交给固件
    └── confirm 带回固件实际使用的 MAC、频段和速率掩码
```

## 固件打包与加载（bootpack，现为后备路径）

> 现在固件的正常来源是内核直接读写 SD 卡 FAT32 分区上的
> `/boot/*.bin`（见 [BOOT_FAT32.md](BOOT_FAT32.md)）；本节的 bootpack
> 预载 + DDR 交接是 FAT32 挂载失败时的后备路径。

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

## 图解：数据流

### 发送：一个 UDP 包到空口

```text
用户态 tftp / ping
  │ svc：T113_SYS_TFTP / T113_SYS_NETCTL
  ▼
udp_sendto(s, ip, port, data, len)            net/ipv4/udp.c，加 rtnl_lock
  │ skb = alloc_skb(len)                       头部预留 NET_SKB_PAD = 128 B
  │ skb_push(8)                                UDP 头
  ▼
ip_queue_xmit(skb, daddr, IPPROTO_UDP)        net/ipv4/ip_output.c
  │ skb_push(20)                               IP 头 + 校验和
  │ arp_resolve(dev, 下一跳, mac)              表里没有就发 ARP 请求并返回 -EBUSY
  │ eth_header()：skb_push(14)                 以太网头
  ▼
dev_queue_xmit(skb)                           net/core/dev.c，检查 carrier
  │ dev->netdev_ops->ndo_start_xmit
  ▼
ieee80211_subif_start_xmit(skb, wlan0)        net/mac80211/tx.c
  │ 取出目的 MAC 和 ethertype，skb_pull(14)
  │ ieee80211_build_data_hdr()
  │   ├── LLC/SNAP 8 B（AA AA 03 00 00 00 + ethertype）
  │   ├── 有 PTK 时头部预留 CCMP IV 8 B、尾部预留 MIC 8 B，置 Protected 位
  │   └── 802.11 头 24 B：ToDS，A1 = BSSID，A2 = 本机，A3 = 目的
  ▼
ieee80211_tx_skb(local, skb, AC_BE, ...)
  │ cookie = ++next_cookie，登记 tx_status[cookie % N] = PENDING
  │ local->hw.ops->tx
  ▼
xradio_tx(hw, skb)                            xradio/txrx.c
  │ AC → WSM 队列；数据帧用策略 1、速率表 0x00a4
  ▼
wsm_tx_frame(cookie, frame, len, queue, ...)    xradio/wsm.c
  │ 拷进 tx_buf：24 B wsm_tx 头 + 802.11 帧        （之后 mac80211 释放 skb）
  ▼
xradio_bh_tx(tx_buf, len, cap)                xradio/bh.c
  │ 等固件输入缓冲，写 len 和序号，对齐
  ▼
sdio_memcpy_toio(func, HIF_ADDR(buf_id_tx, IN_OUT_QUEUE), buf, wlen)
  │ sdio_io_rw_extended()：CMD53，写，function 1，地址自增
  ▼
smhc_request() → smhc_pio()                   SMHC1：CPU 逐字写 FIFO（0x200），1-bit 12 MHz
  ▼
XR829 固件：用 TK 做 CCMP 加密、算 MIC 和 FCS，按速率表发送和重试
  │
  └── TX confirm 0x0404 {packetID = cookie, status}
        → 下一次 xradio_bh_poll() 收到 → xradio_tx_confirm_cb()
        → ieee80211_tx_status(hw, cookie, status)     记到 tx_status 槽
```

一路上 skb 只在两个地方被拷贝：用户数据进 skb 一次，skb 进 `tx_buf` 一次
（因为 CMD53 要求 4 字节对齐的连续缓冲，而且长度要按块对齐）。

### 接收：从空口到 socket

```text
XR829 固件：收帧、查 BSSID 过滤、用 TK/GTK 解密（保留 IV 和 MIC）
  │ RX indication 0x0804 放进输出队列，CONTROL.NEXT_LEN ≠ 0
  ▼
（谁在轮询）udp_recvfrom / icmp_ping / wpa 握手 / net_poll
  └── __net_poll(dev, 10)                         net/core/dev.c
      └── ndo_poll = ieee80211_poll()             net/mac80211/main.c
          ├── ops->poll = xradio_poll() → xradio_bh_poll(10)        【底半部】
          │   └── rx_one()
          │       ├── CMD53 读 IN_OUT_QUEUE      SMHC1 PIO 读 FIFO
          │       └── wsm_handle_rx(msg)
          │           └── xradio_rx_cb(msg, len)                     xradio/txrx.c
          │               ├── status ≠ 0 → 丢弃
          │               ├── alloc_skb，拷贝 802.11 帧
          │               ├── AES：头部后移 8 B 盖住 IV，尾部去掉 8 B MIC
          │               ├── rx_status：channel、signal、DECRYPTED | IV_STRIPPED | MIC_STRIPPED
          │               └── ieee80211_rx_irqsafe(hw, skb)          只入 local->rx_queue
          └── ieee80211_rx_tasklet(local)                           【tasklet】
              └── ieee80211_rx_one(skb)
                  ├── 管理帧
                  │   ├── 扫描中 → ieee80211_scan_rx() → cfg80211 BSS 表
                  │   └── 已加入 → ieee80211_rx_mgmt()：auth/assoc 响应、deauth
                  └── 数据帧 → ieee80211_rx_data()
                      ├── 只收 FromDS 且来自本 BSSID 的
                      ├── 加密帧必须已被硬件解密
                      ├── ieee80211_data_to_8023()    802.11 + LLC → 以太网帧
                      ├── EAPOL（0x888e）→ cfg80211_rx_control_port() → wpa_rx_eapol()
                      └── 其他：端口已授权才收
                          └── eth_type_trans() → netif_rx(skb)       入 backlog
      └── net_rx_action()                                            【软中断】
          └── deliver_skb()：按 skb->protocol 查 packet_type
              ├── ETH_P_ARP → arp_rcv()
              └── ETH_P_IP  → ip_rcv()
                  ├── ICMP → icmp_rcv()
                  └── UDP  → udp_rcv() → 按端口挂到 udp_sock.rx_queue
      └── run_net_work()                                             【工作队列】
          └── 例如 supplicant 的 key_work：M4 的 TX status 回来后装钥

udp_recvfrom() 看到 rx_queue 非空 → 出队拷给调用者
```

三个层次对应 Linux 的三种上下文。没有中断时，它们由同一次 `__net_poll()`
按顺序跑完：

| 层次 | Linux | miniOS 里的位置 | 允许做什么 |
| --- | --- | --- | --- |
| 底半部 | SDIO 中断 → xradio bh 线程 | `xradio_bh_poll()` | 读队列、分派；回调只能入队或记标志 |
| tasklet | mac80211 RX tasklet | `ieee80211_rx_tasklet()` | 处理 802.11 帧，可以发帧、下命令 |
| 软中断 | NET_RX softirq | `net_rx_action()` | 交给 IP/ARP，转到 socket |
| 工作队列 | workqueue | `run_net_work()` | 需要等待的事，例如装钥 |

## 调用链：连接一个 WPA2 AP

```text
register_netdev(wlan0) → NETDEV_REGISTER → wpa_netdev_event()
（或用户命令 wifi → T113_SYS_NETCTL → NETCTL_WIFI）
└── wpa_supplicant_connect(dev)                                   net/wpa/supplicant.c
    ├── rtnl_lock()
    ├── __wpa_connect(dev)
    │   ├── cfg80211_disconnect()；清 IP
    │   ├── load_config()               读 /boot/wifi.txt：ssid、psk、可选静态 IP
    │   ├── cfg80211_scan(dev, 信道 1–13，50–110 ms)
    │   │   └── ieee80211_scan() → xradio_hw_scan()             xradio/scan.c
    │   │       └── wsm_scan() → START_SCAN 0x0007
    │   │           beacon / probe resp → RX → ieee80211_scan_rx() → BSS 表
    │   │           SCAN_COMPLETE 0x0806 → ieee80211_scan_completed()
    │   ├── select_bss()                按 wifi.txt 的 SSID 查 BSS 表，没配置时试内置默认 SSID
    │   ├── build_rsn()                 CCMP 单播，CCMP/TKIP 组播，PSK
    │   ├── wpa_pbkdf2(psk, ssid) → PMK；eapol_init()
    │   ├── cfg80211_connect(dev, {bss, RSN IE})                   net/wireless/sme.c
    │   │   ├── ieee80211_mgd_auth()                              net/mac80211/mlme.c
    │   │   │   ├── bss_info_changed(BSSID) → xradio_do_join()
    │   │   │   │   ├── 预加入 MIB：电源模式、BA 策略、PMF 策略
    │   │   │   │   ├── wsm_join()              JOIN 0x000b：信道、BSSID、SSID、基本速率
    │   │   │   │   └── 过滤 MIB：RX 过滤、beacon 过滤表/开关、BSSID 过滤
    │   │   │   └── 发 Open System auth（管理帧，最低速率），等 auth 响应
    │   │   └── ieee80211_mgd_assoc()
    │   │       ├── 发 assoc request（带 RSN IE），等 assoc 响应
    │   │       └── bss_info_changed(ASSOC) → xradio_set_assoc()
    │   │           └── 关联模式、keep-alive、BSS 参数（AID）、beacon 唤醒周期、PM、slot
    │   └── 等四次握手（__net_poll 循环，最长 HANDSHAKE_TIMEOUT）
    │       M1 ← EAPOL 经 control port → eapol.c 生成 SNonce，算 PTK
    │       M2 → cfg80211_tx_control_port() → ieee80211_tx_control_port()
    │       M3 ← 校验 MIC，解出 GTK
    │       M4 → 发送；TX status 回来后 net_schedule_work(key_work)
    │       key_work → install_keys()
    │           └── cfg80211_add_key() → ieee80211_cfg_add_key() → xradio_set_key()
    │               ├── wsm_add_key_pairwise()   ADD_KEY 0x000c，槽 0，AES 成对钥
    │               └── wsm_add_key_group()      槽 1，GTK + RSC
    ├── cfg80211_port_authorized()     打开数据端口，carrier on，打印 "wlan0: link up"
    ├── rtnl_unlock()
    └── wifi.txt 有静态 IP → inet_set_addr()；否则 ipconfig_dhcp()
```

## T113 实现与 Linux xradio 驱动的区别

| 方面 | Linux（Allwinner xradio + mac80211） | T113 miniOS |
| --- | --- | --- |
| 事件来源 | SDIO 卡中断（DAT1）或 `WL_WAKE_AP` GPIO 中断，唤醒 bh 线程 | 没有中断。bh 在 `ieee80211_poll()`、等 confirm、等缓冲时被调用 |
| 总线 | 4-bit，可到 50 MHz 高速模式 | 1-bit，12 MHz（HOSC 24 MHz 固定 /2，是 SMHC 源时钟上限） |
| 数据搬运 | SMHC 内部 DMA（IDMAC） | CPU 读写 FIFO |
| 固件来源 | `request_firmware()`，从 `/lib/firmware` | `t113_vfs_open("/boot/*.bin")`，从 SD 卡 FAT32 分区；失败时用 SPL 预加载的 bootfs |
| 固件下载时机 | probe 很快返回，下载放在工作队列 | 在 `xradio_sdio_probe()` 里同步完成，此时持有驱动核心锁 |
| bh | 内核线程，等待队列 + 原子计数 | 普通函数 `xradio_bh_poll()`，单线程，`in_rx` 防重入 |
| 命令等待 | `wait_event_timeout()` 睡眠 | 循环 `xradio_bh_poll(5)` 忙等 |
| TX 队列 | 每个 AC 一个队列，按 link 流控、可重排 | 不排队，直接写；只用 `hw_bufs_used` 节流 |
| 虚拟接口 | 最多两个（STA + AP/P2P） | 只有 STA，接口号 0 |
| 省电 | PS-Poll、动态休眠、SDIO 睡眠唤醒 | 一直保持 WUP，PM 关闭 |
| 加密 | 硬件加解密 | 同样交给固件；驱动在 RX 时剥 IV/MIC，TX 时 mac80211 预留 IV 和 MIC 的位置 |
| 802.11n | HT、A-MPDU、40 MHz | 只做 11b/g 关联，BA 策略写 0 |

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
wsm: firmware startup: ? x ???? B input buffers, hw ?.?, type ?, api 0x????????
wsm: firmware label "..."
mmc1:0001:1: WSM command layer ready
mmc1:0001:1: configure firmware, SDD bytes=0x000002e8
mmc1:0001:1: configured MAC 02:0a:9e:22:82:01 bands=0x???????? rates=0x????????
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
  `xradio_sdio_ids[]` 里，看上一行打印的实测 ID；
- `cannot load /boot/..._xr829.bin`——`/boot` 下缺固件：把三个 `*_xr829.bin` 拷到 SD 卡的 FAT32 分区（`make install-firmware`），启动后用 `ls /boot` 确认；如果串口打印了 `fat32: mount failed`，再检查 bootpack 是否打包了固件。

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
| `wsm: no startup indication from firmware` | 固件下载成功但没发 STARTUP indication，通常是 fw/sdd 版本不匹配 |

## 当前边界与下一步

硬件与固件链路（本文主线）已实现：

- SDIO 枚举、CCCR/FBR/CIS、CMD52；
- CMD53 字节/块模式 + SMHC PIO 数据阶段；
- HIF 寄存器、SRAM/AHB 间接寻址、prefetch；
- SDD 参考时钟解析、DPLL 配置、设备唤醒；
- bootloader 载入、1 KiB 分块固件下载、下载 FIFO 协议；
- queue 模式切换、HIF 队列收发（bh.c）与 WSM 协议（命令/confirm/
  indication、MIB）。

协议与数据面（见 NET_STACK.md）也已实现：硬件扫描、WSM JOIN、
认证/关联、WPA2-PSK 四次握手与装钥、802.11 ↔ 以太网数据帧转换、
ARP/IPv4/ICMP/UDP/DHCP、tftp 客户端与用户命令。

未实现（按优先级）：

1. SMHC/SDIO 中断（现在整条链路轮询，吞吐受限）；
2. 可选：SMHC DMA、high-speed 时序、蓝牙固件（fw_xr829_bt.bin）
   与 ETF 测试镜像。

其他刻意简化：卡/函数结构用静态池（`card_pool[3]`、`func_pool[21]`，
外加 1 KiB 的静态下载缓冲）而不是分配器；所有等待用 `mdelay`/`udelay`
忙等；固件下载在 probe 内同步完成，尚未搬到工作队列。
