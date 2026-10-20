# miniOS 网络栈与 WiFi 驱动分层

本文说明 miniOS 的网络代码按 Linux 驱动分层重新组织后的结构：每一层放在
哪个目录、对应 Linux 的哪个模块、层与层之间通过什么接口说话，以及一个数据
包从 UDP 走到 XR829 固件、再从空口回到 socket 的完整路径。

XR829 的 SDIO 枚举、HIF 寄存器、固件下载等硬件细节见
[WIFI_XR829_DRIVER.md](WIFI_XR829_DRIVER.md)；`/boot`（FAT32）和 tftp 写文件
见 [BOOT_FAT32.md](BOOT_FAT32.md)。

## 分层总览

```text
 用户态  ifconfig / ping / tftp / wifi        (user-t113/*.c)
            │ T113_SYS_NETCTL / T113_SYS_TFTP
 ─────────── src/kernel/syscall.c ─────────────────────────────────────
            │
 net/tftp   tftp.c (协议状态机)  tftp_udp.c (收进内存 → 写 /boot)
            │ udp_open/sendto/recvfrom
 net/ipv4   udp.c  icmp.c  ip_input.c  ip_output.c  arp.c
            devinet.c (地址)  ipconfig.c (DHCP)  af_inet.c (注册协议)
            │ ip_rcv / arp_rcv  ←── packet_type ───  dev_queue_xmit
 net/ethernet  eth.c (eth_header / eth_type_trans)
 net/core   skbuff.c  dev.c (net_device, netif_rx, backlog, notifier, rtnl)
            │ ndo_start_xmit / ndo_poll
 ═══════════ struct net_device "wlan0" ═════════════════════════════════
 net/wpa    supplicant.c (wpa_supplicant 的活)  eapol.c (四次握手)
            │ cfg80211_scan / cfg80211_connect / control port / add_key
 net/wireless (cfg80211)  core.c  scan.c (BSS 表)  sme.c (连接状态)  util.c
            │ struct cfg80211_ops
 net/mac80211  cfg.c  mlme.c (auth/assoc/deauth)  rx.c  tx.c  key.c  scan.c  main.c
            │ struct ieee80211_ops            ↑ ieee80211_rx_irqsafe / tx_status
 ═══════════ drivers/net/wireless/xradio ═══════════════════════════════
            sta.c (ops)  txrx.c  scan.c  main.c (probe/注册)
            wsm.c (WSM 命令/confirm/indication)
            bh.c  (HIF 队列收发)   fwio.c (固件下载)   hwio.c (HIF 寄存器)
            sdio.c (sdio_driver)
            │ sdio_memcpy_toio / fromio (CMD53)
 drivers/mmc  core.c (SDIO core)  host/sunxi-smhc.c
```

依赖只向下：驱动不知道 IP，IP 不知道 802.11，supplicant 只通过 cfg80211
接口操作无线设备。每一层的头文件放在 `src/include/net/` 下，名字与 Linux
一致（`skbuff.h`、`netdevice.h`、`cfg80211.h`、`mac80211.h` …），驱动私有
头文件留在驱动目录里（`xradio.h`、`wsm.h`、`hwio.h`），和 Linux 的
`drivers/net/wireless/xradio/` 一样。

## 目录与 Linux 对照

| miniOS | Linux 对应 | 作用 |
| --- | --- | --- |
| `src/net/core/skbuff.c` | `net/core/skbuff.c` | 固定池（32 个）的 `sk_buff`；`skb_push/pull/put` 让每层原地加减头部 |
| `src/net/core/dev.c` | `net/core/dev.c` | `register_netdev`、notifier、`netif_rx` backlog、`dev_queue_xmit`、`rtnl_lock`、轮询入口 `net_poll` |
| `src/net/ethernet/eth.c` | `net/ethernet/eth.c` | 以太网头的构造与解析 |
| `src/net/ipv4/*` | `net/ipv4/*` | ARP、IPv4 收发、ICMP echo、UDP socket、地址配置、DHCP（`ipconfig.c` 对应内核 IP autoconfig） |
| `src/net/wireless/*` | `net/wireless/`（cfg80211） | wiphy、BSS 表、SME 连接状态、EAPOL control port、802.11↔802.3 转换 |
| `src/net/mac80211/*` | `net/mac80211/` | SoftMAC：组 auth/assoc/deauth 帧、数据帧封装、密钥、扫描、RX tasklet |
| `src/net/wpa/*` | 用户态 `wpa_supplicant` | 读 `/boot/wifi.txt`、选 AP、RSN IE、PBKDF2、四次握手、装钥、开端口、DHCP |
| `src/lib/crypto/wpa_crypto.c` | `lib/crypto/` | PBKDF2/PRF/HMAC-SHA1/AES unwrap |
| `src/net/tftp/*` | 无（应用协议） | TFTP 客户端 |
| `src/drivers/net/wireless/xradio/sdio.c` | `xradio/sdio.c` | `xradio_sdio_driver`：probe、CMD53 自检、提速 |
| `.../hwio.c` | `xradio/hwio.c` | HIF 寄存器、APB/AHB 间接访问 |
| `.../fwio.c` | `xradio/fwio.c` | DPLL、bootloader、固件 FIFO 下载、SDD |
| `.../bh.c` | `xradio/bh.c` | 底半部：HIF 队列读写、序号、固件输入缓冲计数 |
| `.../wsm.c` | `xradio/wsm.c` | WSM 请求编码、confirm 等待、indication 分派 |
| `.../main.c` | `xradio/main.c` | 核心 probe：装固件 → WSM 启动 → CONFIGURATION → 注册到 mac80211 |
| `.../sta.c` | `xradio/sta.c` | `ieee80211_ops`：start、JOIN 与关联参数、set_key、poll |
| `.../scan.c` | `xradio/scan.c` | `hw_scan` → WSM START_SCAN；完成通知 |
| `.../txrx.c` | `xradio/txrx.c` | 802.11 帧 ↔ WSM TX/RX；剥 IV/MIC；TX confirm |

## 接口边界

**驱动 ↔ mac80211**（`include/net/mac80211.h`）：驱动实现 `ieee80211_ops`
（`start`、`tx`、`hw_scan`、`bss_info_changed`、`set_key`、`poll`），在
probe 里 `ieee80211_alloc_hw()` + `ieee80211_register_hw()`。驱动向上只用
四个函数：`ieee80211_rx_irqsafe()`、`ieee80211_tx_status()`、
`ieee80211_scan_completed()`、`ieee80211_beacon_loss()`。驱动只搬帧和下命令，
不构造任何 802.11 管理帧。

**mac80211 ↔ cfg80211**（`include/net/cfg80211.h`）：mac80211 实现
`cfg80211_ops`（`scan`、`auth`、`assoc`、`deauth`、`add_key`、
`tx_control_port`）。cfg80211 保存扫描得到的 BSS 表，`cfg80211_connect()`
依次调 auth、assoc。

**cfg80211 ↔ supplicant**：supplicant 调 `cfg80211_scan()`、
`cfg80211_get_bss()`、`cfg80211_connect()`、`cfg80211_add_key()`，
EAPOL 帧经 control port 收发（Linux 里是 nl80211），握手完成后调
`cfg80211_port_authorized()` 打开数据端口、置 carrier。

**net_device**：mac80211 注册 `wlan0`，`ndo_start_xmit` 把以太网帧转成
802.11 数据帧，`ndo_poll` 驱动整个无线栈。IP 层只看到一个以太网设备。

## 一个包怎么走

发送（`ping 192.168.1.1`）：

```text
icmp_ping → ip_queue_xmit (加 IP 头, arp_resolve 下一跳)
  → eth_header (加以太网头) → dev_queue_xmit
  → ieee80211_subif_start_xmit (去掉以太网头, 加 LLC/SNAP、CCMP 预留、802.11 头 ToDS)
  → ieee80211_tx_skb (cookie = WSM packet id) → xradio_tx
  → wsm_tx_frame (24 字节 wsm_tx 头, 队列/速率策略) → xradio_bh_tx → CMD53
```

接收：

```text
xradio_bh_poll → wsm_handle_rx → xradio_rx_cb
  (WSM RX indication → skb, 剥 CCMP IV/MIC, 填 rx_status)
  → ieee80211_rx_irqsafe  [只入队]
mac80211 RX tasklet (ieee80211_poll 在驱动 poll 之后跑):
  管理帧 → 扫描中: cfg80211_inform_bss_frame；已加入: mlme
  数据帧 → ieee80211_data_to_8023 → EAPOL: control port → supplicant
                                   → 其他: eth_type_trans → netif_rx
net_rx_action: backlog → ip_rcv / arp_rcv → icmp_rcv / udp_rcv → socket 队列
```

一个 skb 从 UDP payload 到 802.11 帧都是原地 `skb_push`，不复制；
`NET_SKB_PAD` 128 字节的头部余量足够放 UDP+IP+以太网/802.11+CCMP+LLC。

## 连接流程

`wlan0` 注册时 supplicant 收到 `NETDEV_REGISTER` 通知，自动连接；
`wifi` 命令走的是同一个 `wpa_supplicant_connect()`。

```text
wpa: 读 /boot/wifi.txt
cfg80211_scan (信道 1-13 被动扫描) → mac80211 hw_scan → xradio scan.c → WSM START_SCAN
   beacon → BSS 表；SCAN_COMPLETE → ieee80211_scan_completed
wpa: 选 SSID，校验 RSN（CCMP 单播，CCMP/TKIP 组播，PSK），PBKDF2 算 PMK
cfg80211_connect
   → ieee80211_mgd_auth: bss_info_changed(BSSID) → xradio: 预加入 MIB + WSM JOIN + 过滤 MIB
                          发 Open System auth，等 AP 回复
   → ieee80211_mgd_assoc: 发 assoc req（带 RSN IE），等 assoc resp
                          bss_info_changed(ASSOC) → xradio: 关联模式/BSS 参数/PM/slot MIB
EAPOL M1..M4 (control port) → eapol.c
   M4 的 TX status 回来后装钥：cfg80211_add_key → set_key → WSM ADD_KEY
cfg80211_port_authorized → carrier on → "wlan0: link up"
ipconfig_dhcp 或 wifi.txt 里的静态地址
```

## 执行上下文（没有中断时的规则）

miniOS 没有接 SDIO 中断，全部轮询，但仍按 Linux 的上下文划分来写：

- **底半部**：`xradio_bh_poll()` 读 HIF 队列并分派。它调用的回调
  （`ieee80211_rx_irqsafe`、`ieee80211_tx_status`、
  `ieee80211_scan_completed`、`ieee80211_beacon_loss`）只能入队或记录状态，
  不能发帧、不能下 WSM 命令。bh 用静态接收缓冲，`in_rx` 守卫禁止重入。
- **tasklet**：`ieee80211_poll()` 在驱动 poll 之后运行 mac80211 RX
  tasklet，这里可以发帧、下命令（例如装钥匙）。`in_tasklet` 防止嵌套。
- **工作项**：`net_schedule_work()` 相当于 workqueue，在
  `__net_poll()` 末尾执行；supplicant 用它在 M4 发送完成后装钥。
- **rtnl_lock**：一把不可递归的大锁。对外入口（`udp_*`、`icmp_ping`、
  `wpa_supplicant_connect`、`net_poll`）自己加锁；带 `__` 前缀的函数要求调用者
  已持锁。`ipconfig_dhcp` 走加锁的 UDP 接口，所以不能在持锁时调用。
- 在 `net_rx_action` 里需要 ARP 时，`arp_resolve` 只发请求并返回 `-EBUSY`，
  不在接收路径里轮询。

## Kconfig

```text
Networking support            src/net/Kconfig
  NET                         core + ethernet + ipv4 + DHCP
  TFTP_CLIENT
  CFG80211                    src/net/wireless/Kconfig
  MAC80211                    src/net/mac80211/Kconfig
  WPA2_PSK                    src/net/wpa/Kconfig（依赖 CFG80211）
Device Drivers
  Network device support      src/drivers/net/Kconfig
    WLAN
      WLAN_XRADIO             依赖 WLAN && SDIO && MAC80211
        WLAN_XRADIO_XR829
```

Makefile 按同样的开关挑目标文件；树莓派（kernel8.img）构建排除整个
`src/net/` 和 `src/lib/crypto/`。

## 加一块新网卡要做什么

1. 在 `src/drivers/net/wireless/<厂商>/` 实现 `ieee80211_ops`；
2. probe 里 `ieee80211_alloc_hw()`、`ieee80211_register_hw(hw, mac, rates, n)`；
3. 底半部收帧时构造 skb、填 `IEEE80211_SKB_RXCB`，调
   `ieee80211_rx_irqsafe()`；TX 完成调 `ieee80211_tx_status(hw, cookie, status)`。

有线网卡则直接 `register_netdev()` 一个 `net_device`，实现
`ndo_start_xmit`/`ndo_poll`，收包时 `eth_type_trans()` + `netif_rx()`，
IP 层和 tftp 不用改。

## 从旧结构的对应关系

| 旧文件 | 现在 |
| --- | --- |
| `src/net/net.c` | `net/core/*`、`net/ethernet/eth.c`、`net/ipv4/*` |
| `src/drivers/net/wireless/xradio/sta.c`（扫描、JOIN、auth/assoc、EAPOL、数据帧转换） | 802.11 状态机 → `net/mac80211/`；BSS 表与连接 → `net/wireless/`；wifi.txt/RSN/握手/装钥 → `net/wpa/supplicant.c`；固件 MIB 设置 → `xradio/sta.c` |
| `src/drivers/net/wireless/xradio/xr829_core.c` | `sdio.c`、`hwio.c`、`fwio.c`、`main.c` |
| `src/drivers/net/wireless/xradio/wsm.c` | 传输 → `bh.c`；命令编码与分派 → `wsm.c` |
| `src/net/eapol.c` | `src/net/wpa/eapol.c` |
| `src/net/tftp.c`、`tftp_udp.c` | `src/net/tftp/` |
| `src/lib/wpa_crypto.c`、`include/net/wpa_crypto.h` | `src/lib/crypto/`、`include/crypto/` |
| `include/net/net.h`、`include/net/xradio/*` | `include/net/{skbuff,netdevice,if_ether,ip,arp,icmp,udp,ipconfig,ieee80211,cfg80211,mac80211,wpa}.h`；WSM 头移到驱动目录 |
| `xr829_driver` | `xradio_sdio_driver` |
| `xradio_sta_connect()` | `wpa_supplicant_connect(dev)` |
| `net_dhcp` / `net_ping` / `net_set_addr` / `net_parse_ip` | `ipconfig_dhcp` / `icmp_ping` / `inet_set_addr` / `in4_pton` |

固件交互的顺序和参数（预加入 MIB、JOIN、过滤 MIB、关联 MIB、钥匙槽位
0/1、速率策略）与旧实现逐项保持一致。

## 验证

- `make t113`（`-Wall -Wextra`）零警告，内核链接通过。
- 主机端联调：把 `src/net`、`lib/crypto` 和 xradio 的 `wsm/main/sta/scan/txrx`
  在 x86 上用 ASan/UBSan 编译，`bh.c` 换成假固件，另一端是 Python 写的
  WPA2 AP。跑通：扫描 → JOIN → 认证 → 关联 → 四次握手（双方 MIC 校验、
  装进固件的 TK/GTK 与 AP 一致）→ DHCP → ping 网关 → TFTP 下载 1000 字节并
  校验 → 组播密钥更新 → AP 踢下线（链路断开）→ 重新连接 → ping。
- 尚未上板：SDIO、固件真实行为需要在 T113 板子上确认。

上板时预期的串口日志（顺序）：

```text
mmc1:0001:1: firmware running
wsm: firmware startup: ...
mmc1:0001:1: configured MAC 02:0a:9e:22:82:01 ...
cfg80211: phy0 registered, 12 bitrates
net: wlan0 registered, hwaddr 02:0a:9e:22:82:01
wpa: /boot/wifi.txt ssid="TP-Link_B114" psk=<set>
cfg80211: passive scan, 13 channels
cfg80211: AP ssid="..." bssid=... channel=... rcpi=... secured
wpa: selected SSID="TP-Link_B114" ...
wlan0: joining BSS
wlan0: open-system authentication
wlan0: association request
wlan0: associated, AID ...
wpa: WPA2 4-way handshake
wpa: WPA2 keys installed
wlan0: link up
dhcp: bound 192.168.x.x gateway ...
```
