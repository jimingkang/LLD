# miniOS `/boot`：从 bootpack 视图到可读写 FAT32

本文说明 `/boot` 的两代实现：改动前的 bootfs（bootpack 交接视图）和
现在的 FAT32 文件系统（xv6 风格的 bio + fat32 分层），以及它们和 SPL、
XR829 固件加载、tftp 的关系。根文件系统 minifs、VFS 挂载表、devfs 的
整体结构见 [ROOTFS_DEVFS.md](ROOTFS_DEVFS.md)。

一句话总结：

- **改动前**：读 FAT32 的是 SPL，内核里的 `/boot` 只是把 SPL 预先
  搬进 DDR 的三份固件包装成文件，只读、只认三个写死的路径、不能列目录。
- **改动后**：内核自己读写 SD 卡上的 FAT32 分区，`/boot` 是真正的文件
  系统，可以按文件名查找、列目录、创建和写入文件；tftp 下载的文件直接
  落盘到卡上。老的 bootfs 只在 FAT32 挂载失败时作为后备。

## 改动前：bootfs 只是 bootpack 的视图

### 加载流程

```text
miniBoot SPL  load_bootpack()
├── 读 SD 128 KiB bootpack，装 kernel → 0x40200000
├── bootpack header 拷到 0x401ff000
└── load_fat32_firmware()                 SPL 里的只读 FAT32 解析器
    ├── fat32_mount()                     MBR 找 FAT32 分区，解析 BPB
    ├── fat32_load_root() × 3             只在根目录按名字找，沿簇链读入 DDR
    │   ├── boot_xr829.bin → 0x40100000
    │   ├── fw_xr829.bin   → 0x40110000
    │   └── sdd_xr829.bin  → 0x40140000
    └── bootpack_slot()                   往 header 补 3 个条目（offset=0 表示常驻镜像），重算 CRC

miniOS 内核  bootfs.c（63 行）挂在 /boot
├── lookup("/boot/fw_xr829.bin")
│   └── 路径写死映射 → t113_bootpack_find("fw_xr829")
│       → node.id = load_addr（DDR 物理地址当文件 id）
└── read() = 从 node.id + offset 处 memcpy
```

### 本质

bootfs 本质上是 **bootpack 解析器**，挂到 `/boot` 只是借用 VFS 的接口，
让 XR829 驱动可以用 `t113_vfs_open("/boot/fw_xr829.bin")` 拿固件，而
不用知道 bootloader 私有的地址常量。它不是文件系统：

| 能力 | bootfs | 原因 |
| --- | --- | --- |
| 按文件名查找 | ✗ | `entry_name()` 只认三个硬编码路径，映射到 bootpack 条目名 |
| 列目录（`ls /boot`） | ✗ | `readdir = 0` |
| 读任意文件 | ✗ | 只有 SPL 预加载的三份固件 |
| 写入 / 创建 | ✗ | 没有 `write`、`create` |
| 看到运行期卡上的变化 | ✗ | 数据是启动时的 DDR 快照，内核从不访问 FAT32 分区 |

所以当时 tftp 之类"把文件存进 `/boot`"的功能无从实现。

## 改动后：分层结构

照 xv6 的 `bio.c` / `fs.c` 分层：

```text
用户态  open(O_CREAT|O_TRUNC) / read / write / readdir / tftp
   │
VFS     src/kernel/fs/vfs.c        挂载表最长前缀匹配，/boot → fat32_ops
   │
fat32   src/kernel/fs/fat32.c      路径 → 目录项，文件偏移 → 簇链；inode 表
   │
bio     src/kernel/fs/bio.c        512 B 扇区缓存，24 块 LRU，写直达
   │
SD      src/drivers/mmc/sunxi-sd.c t113_sd_read / t113_sd_write（CMD17/CMD24，轮询）
```

### 挂载顺序

`src/kernel/init/main.c` 的 `kernel_boot()`：

```c
t113_vfs_init();
/* The root device initialises the SD card that /boot shares. */
if (t113_minifs_mount_rootdev() < 0)        /* 先挂 /，顺带初始化 SD 卡 */
    kernel_platform_panic("cannot mount root filesystem");
if (t113_fat32_mount_vfs() < 0) {           /* 再挂 /boot（FAT32 读写） */
    t113_uart_puts("fat32: mount failed, using SPL handoff images\n");
    if (t113_bootfs_mount_vfs() < 0)        /* 后备：老的 bootpack 视图 */
        kernel_platform_panic("cannot mount boot filesystem at /boot");
}
if (t113_devfs_init() < 0) ...
```

与之前相比，`/` 改为先挂（rootdev 里会做 `t113_sd_init()`，`/boot` 和
`/` 共用同一张卡、同一个 SMHC0 控制器）。两者都在调度器启动前完成，
此时互斥锁实际不生效，SD 访问是串行的。

## bio：扇区缓存（`bio.c`）

| 项 | 值 |
| --- | --- |
| 块大小 `BSIZE` | 512 B（= SD 扇区，块号就是卡上的绝对 LBA） |
| 缓冲数 `NBUF` | 24 |
| 替换策略 | 双向链表 LRU，`brelse` 后放到表头 |
| 写策略 | **写直达**：`bwrite()` 立刻 `t113_sd_write()` |
| 对齐 | `data[]` 4 字节对齐（SD 驱动用 CPU 搬 FIFO，按字访问） |

接口和 xv6 一致，多了一个 `bget_blank()`：

| 函数 | 作用 |
| --- | --- |
| `bread(lba)` | 返回带引用的缓冲，未命中时从卡上读 |
| `bget_blank(lba)` | 返回带引用的缓冲但**不读卡**，给"整块覆盖"的调用者（写满一个扇区、清零新簇）省一次读 |
| `bwrite(b)` | 写回卡上 |
| `brelse(b)` | 释放引用，缓冲留在缓存里 |

同一块的并发访问由上层串行化（fat32 每个操作都持有自己的锁），所以
bio 不像 xv6 那样给每个 buf 配 sleeplock。

因为是写直达，卡上的内容永远不比缓存旧，fat32 读大段数据时可以绕开
缓存直接读卡（见下文"读路径"）。

## fat32（`fat32.c`）

### 挂载 `t113_fat32_mount_vfs()`

1. `binit()`，`bread(0)` 读 MBR，验 `55 AA`，取 **第一个** 类型为
   `0x0B/0x0C/0x1B/0x1C`（FAT32 CHS/LBA，含隐藏变体）的分区表项。
2. 读分区首扇区（BPB），校验：`55 AA`、每扇区 512 字节、每簇扇区数
   非零、FAT 个数非零、根目录项数为 0（FAT32 特征）、每 FAT 扇区数和
   总扇区数非零。
3. 算出布局：

```text
part_lba
├── 保留区（含 BPB、FSInfo）         fat_lba  = part + BPB[14] 保留扇区数
├── FAT × fats                       data_lba = fat_lba + fats × sectors_per_fat
└── 数据区                           簇 n 的 LBA = data_lba + (n-2) × spc
```

4. 簇数 = (总扇区 − 元数据扇区) / spc，并用 FAT 表能描述的条目数封顶；
   根目录簇号必须合法。
5. 挂到 `/boot`，打印 `fat32: /boot mounted rw, partition lba=… clusters=… cluster-bytes=…`。

### 内存中的 inode 表

FAT32 没有 inode，文件的元数据（首簇、大小）存在目录项里。为了对齐
xv6 的 icache，fat32.c 维护一个 16 项的 `fat_inode` 表：

```c
struct fat_inode {
    uint32_t ref;
    uint32_t dir;          /* 1 for a directory */
    uint32_t first;        /* first cluster, 0 for an empty file */
    uint32_t size;
    uint32_t ent_lba;      /* sector of the short entry, 0 for the root */
    uint32_t ent_off;      /* byte offset of that entry in the sector */
    uint32_t dirty;        /* first/size changed: rewrite the entry */
    uint32_t cur_index;    /* last cluster looked up: index in chain... */
    uint32_t cur_cluster;  /* ...and its number (0 = none) */
};
```

- **身份** = 短目录项所在的 `(ent_lba, ent_off)`，同一个文件被打开两次
  会拿到同一个 inode（`iget` 按位置查找，引用计数 +1）。
- `vfs_node.private_data` 指向这个 inode，VFS 后续的 read/write/close
  都通过它找到文件。
- `cur_index / cur_cluster` 缓存上一次查到的簇，顺序读写时沿簇链只往
  前走一步，不用每次从首簇开始数（簇链是单向链表）。
- `dirty`：写入导致首簇或大小变化时置位，**最后一次 close 时**
  `iupdate()` 把首簇（高 16 位 @20、低 16 位 @26）和大小（@28）写回
  目录项。

### 路径解析

`resolve(path)` 先用 `mount_relative()` 去掉 `/boot` 前缀，然后逐个
分量在目录簇链里用 `dir_find()` 查找：

- 目录遍历器 `dir_next()` 同时拼接长文件名（LFN）片段，并用短名校验
  和（`short_checksum()`）确认 LFN 和后面的短目录项属于同一个文件，
  否则退回用 8.3 短名。
- 名字比较不区分大小写；短名会按 NT 保留字节（byte 12）的大小写标志
  还原成小写。
- 支持任意层子目录；`..` 指向根目录时首簇为 0，按根目录簇处理。
- 根目录本身用 `lba = 0` 表示（它没有目录项）。

### 读路径

```text
fat32_read(node, offset, dst, count)
└── 循环
    ├── ibmap(ip, pos / 簇大小, alloc=0)   沿簇链找到所在簇
    ├── 扇区对齐 + 剩余 ≥ 512 + dst 4 字节对齐
    │   └── t113_sd_read(lba, n, dst) 直接读进调用者缓冲（一次读完簇内剩余整扇区）
    └── 否则 bread(lba) → copy 部分扇区 → brelse
```

读大文件（固件、内核镜像）时绝大多数数据走直读，不占缓存也不多拷一次。

### 写路径

```text
fat32_write(node, offset, src, count)
├── offset > size → 拒绝（不支持稀疏文件）
└── 循环
    ├── ibmap(ip, pos / 簇大小, alloc=1)   不够就 fat_alloc() 接到链尾
    ├── 写满一个扇区 → bget_blank()；否则 bread()（读改写）
    ├── copy → bwrite()（写直达）→ brelse
    └── 文件变长 → ip->size 更新, dirty = 1
```

- `fat_alloc(prev)`：从 `free_hint` 开始线性扫 FAT 找值为 0 的簇，标成
  链尾 `0x0FFFFFFF`，再把 `prev` 指向它。
- `fat_set()` 同时写 **所有 FAT 副本**（通常 2 份），保持一致，Windows
  和 macOS 的 fsck 不会报 FAT 不一致。
- 写 FAT 项只改低 28 位，保留高 4 位（规范要求）。
- **FSInfo**：第一次分配簇之前把 FSInfo 里的"空闲簇数 / 下一个空闲簇"
  标成未知（`0xFFFFFFFF`），让其它系统下次挂载时自己重新计算。这样
  内核就不需要维护精确的空闲计数。

### 创建 `fat32_create()`（`open` 带 `O_CREAT`）

1. `resolve(path, parent=1)` 找到父目录和最后一个分量。
2. 文件已存在就直接打开；否则 `create_entry()`：
   - 名字能直接放进 8.3（`fit_short()`，大写字母、合法字符、基名 ≤ 8、
     扩展名 ≤ 3；全小写的名字用 NT 大小写标志记录）→ 只写一个短目录项；
   - 否则生成别名 `NAME~N.EXT`（`make_alias()`，N 从 1 递增直到不冲突），
     再写 ⌈长度/13⌉ 个 LFN 项 + 1 个短目录项，LFN 项带短名校验和。
   - `find_slots()` 在父目录里找足够的连续空位（`0x00` / `0xE5`），
     不够就给目录追加一个清零的新簇。
   - 创建日期写固定的 2026-01-01（`0x5c21`），没有 RTC。
3. 新文件首簇为 0、大小为 0，第一次写入时才分配簇。

### 截断 `fat32_truncate()`（`open` 带 `O_TRUNC`）

顺序是 **先改目录项、再释放簇链**：首簇和大小清零 → `iupdate()` 写回
→ `fat_free_chain()`。如果中途掉电，最坏情况是留下一条无人引用的簇链
（fsck 能回收），而不会出现目录项指向已经释放的簇。

### 列目录 `fat32_readdir()`

跳过隐藏项、卷标、`.` 和 `..`；类型取值和 minifs 一致（1 = 目录，2 =
文件），所以现有的 `ls` 不用改。`vfs_dirent.name` 只有 31 字节，超过
30 个字符的长文件名在 `ls` 里会被截断显示（打开文件时用完整名字没问题）。

### 不支持

`mkdir`、`unlink`、`rename`、时间戳更新、稀疏文件、多分区（只认 MBR 里
第一个 FAT32 分区）、FAT12/16、exFAT。

## VFS 的配套改动

`include/fs/vfs.h`：

```c
#define VFS_O_ACCMODE 3u
#define VFS_O_CREATE 0x200u      /* xv6 fcntl.h values */
#define VFS_O_TRUNC  0x400u

struct vfs_backend_ops {
    ...
    /* Optional: create an empty regular file (O_CREATE). */
    int (*create)(const char *path, struct vfs_node *node);
    /* Optional: discard a file's contents (O_TRUNC). */
    int (*truncate)(struct vfs_node *node);
    /* Optional: the last reference to an open node is gone. */
    void (*close)(struct vfs_node *node);
};
```

`t113_vfs_open()` 的流程：

```text
find_mount(path)                    最长前缀匹配
├── lookup(path) 失败
│   └── 带 O_CREATE 且后端有 create → create(path)
├── 带 O_TRUNC（必须是 O_RDWR）→ truncate(node)
└── 分配 open_files 槽位
t113_vfs_write()   成功后更新 file->node.size
t113_vfs_close()   引用计数归零 → ops->close(node)   fat32 在这里写回目录项
```

三个新回调都是可选的：minifs、devfs、bootfs 不实现它们，行为不变
（对它们带 `O_CREATE` 会失败）。

用户态：`fcntl.h` 增加 `O_CREATE` / `O_CREAT`（0x200）和 `O_TRUNC`
（0x400），`sys_open` 接受这两个标志。

## 谁在用 `/boot`

### XR829 固件

驱动代码没有改：`need_image()`（现在在 `xradio/fwio.c`）一直是

```c
struct vfs_file *file = t113_vfs_open("/boot/fw_xr829.bin", VFS_O_RDONLY);
```

变的是 VFS 下面的后端。现在这个调用由 fat32 处理：在 FAT32 根目录里按
名字查找，沿簇链从卡上读出。也就是说固件加载现在走的是真正的文件系统
查找；只有 FAT32 挂载失败时才会退回 bootfs 的 DDR 视图。

> SPL 里的 `load_fat32_firmware()` 仍然会把三份固件预读进 DDR，内核
> 正常路径已经不依赖它，只给 bootfs 后备路径用。上板确认 FAT32 稳定后
> 可以删掉这段，启动会快一点。

### tftp

`src/net/tftp/tftp_udp.c` 的 `tftp_get()`：先把整个文件收进内存（最多 8 MiB），
传输完成后才 `t113_vfs_open(local, O_RDWR | O_CREATE | O_TRUNC)` 写入，
关闭后再重新打开读回、比对 CRC32。传输中断不会在 `/boot` 留下写了一半
的文件。用户命令 `tftp <服务器IP> <远端文件> [本地路径]`，本地路径默认
`/boot/<文件名>`。

### WiFi 配置

supplicant（`src/net/wpa/supplicant.c` 的 `wpa_supplicant_connect()`）从 `/boot/wifi.txt` 读 `ssid=`、`psk=`（以及可选的
`ip=`、`netmask=`、`gateway=`）。密码只放在 FAT32 分区上，不进源码；
仓库里对应的 `rpi_bm/firmware/wifi.txt` 被 `.gitignore` 忽略。

### SPL 从 FAT32 加载内核

miniBoot `spl.c` 新增 `load_fat32_kernel()`：SD 初始化后先在 FAT32 根目录
找 `kernel_minios.img`（最大 8 MiB），读到 `0x40200000`，打印大小和
CRC32；找到了就跳过 bootpack 里的 kernel 条目，找不到就按原来的
bootpack 流程走。配合 tftp，可以在板子上直接更新内核：

```sh
tftp 192.168.0.100                        # 写入 /boot/kernel_minios.img
# 重启后 SPL 加载新内核
```

想回到 bootpack 里的内核，删掉 FAT32 分区上的 `kernel_minios.img` 即可。

## FAT32 图解（参照 xv6 book 第 8 章）

xv6 book 讲文件系统时，先给一张分层图，再给磁盘布局，然后逐层讲
buffer cache、inode、目录、路径名，最后串起 `open/read/write`。本节按同样
的顺序讲 miniOS 的 FAT32，每一层都和 xv6 的对应层并排比较。

### 分层

```text
        xv6 文件系统（7 层）                     miniOS /boot（T113）
 ┌───────────────────────────────┐      ┌──────────────────────────────────────┐
 │ 文件描述符  file.c sysfile.c  │      │ task->files[4] → struct vfs_file     │ vfs.c
 ├───────────────────────────────┤      ├──────────────────────────────────────┤
 │ 路径名      namei / namex     │      │ find_mount() 选后端（最长前缀）       │ vfs.c
 ├───────────────────────────────┤      │ resolve() 逐级 dir_find()            │ fat32.c
 │ 目录        dirlookup/dirlink │      ├──────────────────────────────────────┤
 ├───────────────────────────────┤      │ 目录项 32 B 短名 + LFN 长名           │ fat32.c
 │ inode       iget/ilock/bmap   │      │ fat_inode（内存）+ ibmap() 走簇链     │ fat32.c
 ├───────────────────────────────┤      ├──────────────────────────────────────┤
 │ 日志        begin_op/end_op   │      │ （无日志：直写 + 写入顺序约定）        │
 ├───────────────────────────────┤      ├──────────────────────────────────────┤
 │ buffer cache  bread/bwrite    │      │ bio.c  24 个 512 B 扇区缓冲，LRU      │ bio.c
 ├───────────────────────────────┤      ├──────────────────────────────────────┤
 │ 磁盘        virtio_disk.c     │      │ t113_sd_read/write  SMHC0 CMD17/CMD24 │ sunxi-sd.c
 └───────────────────────────────┘      └──────────────────────────────────────┘
```

xv6 的 inode 层同时负责“文件数据在哪些块”（`addrs[]` 加间接块）和“文件
元数据存在哪”（磁盘 inode 区）。FAT32 把这两件事拆开了：

- 数据块的位置记在 FAT 表里，一簇接一簇连成链表；
- 文件大小和首簇号记在父目录的 32 字节目录项里。

所以 miniOS 的 `fat_inode` 只是内存里的一个句柄，记住“我的目录项在磁盘哪个
位置”，关闭文件时把首簇和大小写回去。

### 磁盘布局

整张卡和 FAT32 分区内部：

```text
整张 SD 卡（512 B 扇区，LBA = 扇区号）
LBA 0          MBR：446 B 引导码 | 4 × 16 B 分区表 | 55 AA
               表项 1  type 0x0b/0x0c   → FAT32  → 挂到 /boot
               表项 2  type 0x83        → minifs → 挂到 /
LBA 16         Boot0 SPL（8 KiB 处）
LBA 256        bootpack（128 KiB 处）
part_lba       FAT32 分区开始 ─────────────┐
                                           ▼
part_lba   ┌─────────────────────────────────┐ ┐
           │ 扇区 0  引导扇区（BPB）          │ │
           │ 扇区 1  FSInfo                  │ │ 保留区：BPB_RsvdSecCnt 个扇区
           │ 扇区 6  备份引导扇区             │ │ （常见 32）
           │ ...                              │ │
fat_lba    ├─────────────────────────────────┤ ┘ = part_lba + RsvdSecCnt
           │ FAT #1                          │   sectors_per_fat 个扇区
           │ 每个簇一项，4 字节，低 28 位有效 │   一个扇区放 128 项
           ├─────────────────────────────────┤
           │ FAT #2（镜像）                   │   fat_set() 两份都写
data_lba   ├─────────────────────────────────┤ = fat_lba + fats × sectors_per_fat
           │ 簇 2   根目录通常从这里开始       │   cluster_lba(c) = data_lba + (c - 2) × spc
           │ 簇 3                            │
           │ ...                              │
           │ 簇 clusters+1                   │
           └─────────────────────────────────┘
```

xv6 的 `mkfs` 布局是连续的几段，块号由超级块给出：

```text
xv6 (BSIZE = 1024)
[ 0 boot | 1 super | 2.. log | inodestart.. inode 块 | bmapstart.. 位图 | 数据块 ... ]
```

两者对照：

| xv6 | FAT32 | miniOS 里在哪 |
| --- | --- | --- |
| 超级块 `struct superblock` | 引导扇区里的 BPB | `t113_fat32_mount_vfs()` 解析到全局 `fs` |
| 空闲块位图 | FAT 表项为 0 表示空闲 | `fat_alloc()` 从 `free_hint` 线性扫描 |
| 磁盘 inode 区 | 没有，元数据在目录项里 | 目录项的 `ent_lba/ent_off` |
| `addrs[12]` + 1 个间接块 | FAT 链表，长度不限 | `ibmap()` |
| 日志区 | 没有 | 写入顺序约定（见后文） |

`t113_fat32_mount_vfs()` 用到的 BPB 字段：

| 偏移 | 长度 | 字段 | 校验 / 用途 |
| --- | --- | --- | --- |
| 11 | 2 | BytsPerSec | 必须等于 512（`BSIZE`） |
| 13 | 1 | SecPerClus | `fs.spc`，非 0 |
| 14 | 2 | RsvdSecCnt | `fat_lba = part_lba + RsvdSecCnt` |
| 16 | 1 | NumFATs | `fs.fats`，非 0 |
| 17 | 2 | RootEntCnt | 必须为 0，这是 FAT32 的标志 |
| 32 | 4 | TotSec32 | 算数据簇数 `clusters` |
| 36 | 4 | FATSz32 | `sectors_per_fat` |
| 44 | 4 | RootClus | `root_cluster`，必须是合法簇号 |
| 48 | 2 | FSInfo | FSInfo 扇区号，0 表示没有 |
| 510 | 2 | 签名 | 55 AA |

簇数还会再被 FAT 表的容量截一次：`clusters ≤ sectors_per_fat × 128 - 2`。
有些格式化工具算出来的 FAT 偏小，截一下能防止 `fat_get()` 越过 FAT 表。

### FAT 表与簇链

FAT 表就是一个大数组，下标是簇号，值是“下一个簇号”：

```text
目录项：name = "fw_xr829.bin"  first = 5  size = 174624

FAT[]  下标:  2     3     4     5     6     7     8     9     10    11
       值:   EOC   EOC   0     6     7     9     0     10    EOC   0
                         空闲  │     │     │     空闲  │     │     空闲
                               └─→ 6 ┴─→ 7 ┴─────────→ 9 ┴─→ 10 → EOC

文件第 k 个簇 = 从 first 出发沿链走 k 步
偏移 off 所在的簇序号 = off / (spc × 512)
扇区 = cluster_lba(簇号) + (off % 簇字节) / 512
```

（簇号只是示意。）表项取值：

| 值（低 28 位） | 含义 |
| --- | --- |
| `0` | 空闲 |
| `2 … clusters+1` | 下一个簇 |
| `≥ 0x0ffffff8` | 链尾 EOC，miniOS 写 `0x0fffffff` |

`ibmap(ip, index, alloc)` 把“文件第 index 个簇”翻译成簇号，相当于 xv6 的
`bmap()`。差别在于：xv6 用下标直接查 `addrs[]`，O(1)；FAT 要从头走链，
O(n)。miniOS 在 `fat_inode` 里放了一个游标 `cur_index/cur_cluster`，顺序读写
时从上一次的位置接着走，所以整文件顺序读还是 O(n) 而不是 O(n²)：

```text
ibmap(ip, index, alloc)
├── ip->first == 0（空文件）
│   └── alloc ? first = fat_alloc(0) : 返回 0
├── 起点：cur_index ≤ index 时从游标出发，否则从 first 出发
├── while i < index:
│   ├── next = fat_get(c)               bread(FAT 扇区)，取 4 字节
│   ├── next 不是合法簇
│   │   ├── 是 EOC 且 alloc → next = fat_alloc(c)   扩链
│   │   └── 否则返回 0（越过文件末尾）
│   └── c = next, i++
└── 更新游标，返回 c

fat_alloc(prev)
├── fsinfo_invalidate()                 第一次分配时把 FSInfo 计数写成“未知”
├── 从 free_hint 起环形扫描 FAT，找值为 0 的项
├── fat_set(c, EOC)                     所有 FAT 副本
├── prev ? fat_set(prev, c)             挂到链尾
└── free_hint = c + 1
```

### 目录项

FAT32 的目录也是文件，内容是一串 32 字节目录项。一个 512 B 扇区放 16 项，
一个簇放 `spc × 16` 项。短目录项（8.3）的格式：

```text
偏移  长度  字段
 0     8   主名，空格填充      e[0] = 0x00 目录结束；0xE5 已删除；0x05 表示首字符是 0xE5
 8     3   扩展名
11     1   属性   0x01 只读 0x02 隐藏 0x04 系统 0x08 卷标 0x10 目录 0x20 归档；0x0F = LFN
12     1   NT 保留  bit3 主名全小写，bit4 扩展名全小写
13     1   创建时间（10 ms）
14     2   创建时间
16     2   创建日期              miniOS 新建文件写 2026-01-01
18     2   访问日期
20     2   首簇号高 16 位   ┐
22     2   修改时间         │
24     2   修改日期         │
26     2   首簇号低 16 位   ┘ first = (hi << 16) | lo
28     4   文件大小（目录为 0）
```

长文件名（LFN）放在短目录项前面，每项 13 个 UTF-16 字符，按逆序存放：

```text
磁盘顺序 →
┌───────────────┬───────────────┬────────────────────────┐
│ LFN  0x42     │ LFN  0x01     │ 短项 "MINIOS~1BIN"     │
│ 字符 14..17   │ 字符 1..13    │ attr 0x20 first size   │
│ attr 0x0F     │ attr 0x0F     │                        │
│ chksum = S    │ chksum = S    │ S = short_checksum(名) │
└───────────────┴───────────────┴────────────────────────┘
  0x40 标记“最后一片”（也就是磁盘上第一项）

LFN 项内 13 个字符的字节位置：lfn_pos[] = {1,3,5,7,9, 14,16,18,20,22,24, 28,30}
校验和：sum = ((sum & 1) << 7) + (sum >> 1) + name11[i]，i = 0..10
```

读目录时，`dir_next()` 是一个小状态机：

```text
dir_next(it, d)
├── 本簇的项读完 → it->cluster = fat_get(it->cluster)
├── bread(cluster_lba(c) + index / 16)，拷出 32 字节，brelse
├── e[0] == 0x00   → 目录结束，返回 0
├── e[0] == 0xE5   → 已删除，丢弃攒了一半的长名
├── attr == 0x0F   → lfn_piece()：0x40 项清空缓冲并记下 chksum，按 ord 填 13 个字符
├── attr & VOLUME  → 卷标，跳过
└── 短项
    ├── 长名完整且 chksum 匹配 → d->name = 长名
    ├── 否则 short_name()     → "FW_XR829.BIN"，按 NT 位转小写
    └── d->first / size / lba / off，返回 1
```

新建文件时，名字能精确表示成 8.3 就只写一个短项。例如 `fw_xr829.bin` 存成
`FW_XR829BIN`，NT 字节写 0x18 表示主名和扩展名都是小写。表示不了时
（太长、多个点、大小写混合等）才生成 `NAME~N.EXT` 别名并写 LFN 项：

```text
create_entry(dir_cluster, "minios-kernel.bin")
├── long_char_ok() 逐字符检查         不允许 \ / : * ? " < > |
├── fit_short() 失败（主名 13 字符 > 8）
├── make_alias()                       "MINIOS~1BIN"，~1 已存在就试 ~2 ...
├── pieces = ceil(17 / 13) = 2
├── find_slots(dir, 3)                 找 3 个连续空项；目录满了就 fat_alloc + zero_cluster 扩一簇
├── write_entry() × 2                  LFN 0x42、0x01
└── write_entry()                      短项：attr ARCHIVE，first = 0，size = 0
```

xv6 的目录项是 16 字节的 `struct dirent { ushort inum; char name[14]; }`，
`inum` 指向 inode，长度和数据都在 inode 里。FAT 的目录项本身就是 inode。

### 内存中的数据结构

```text
用户 fd / 内核指针
      │
      ▼
task->files[i] ──→ struct vfs_file              open_files[32]，vfs.c
                   ├── references / flags / offset
                   ├── ops ──→ fat32_ops
                   └── node { id = first, size, type,
                              private_data } ──┐
                                               ▼
                             fs.inode[16]：struct fat_inode      fat32.c
                             ├── ref                    同一目录项只占一个槽（iget 去重）
                             ├── dir / first / size
                             ├── ent_lba / ent_off ──→ 磁盘上短目录项的位置（根目录为 0）
                             ├── dirty                  first/size 改过，close 时 iupdate()
                             └── cur_index / cur_cluster  簇链游标
                                               │ fat_get / bread / bwrite
                                               ▼
                             bcache：struct buf[24]               bio.c
                             head <-> 最近释放 <-> ... <-> 最久未用 <-> head
                             ├── bget：正向找命中（valid && blockno 相同）
                             │         反向找 refcnt == 0 的回收
                             ├── bread：未命中时 t113_sd_read(blockno, 1)
                             ├── bwrite：立刻 t113_sd_write（直写）
                             └── brelse：refcnt 归 0 时移到 head.next
                                               │
                                               ▼
                             sunxi-sd.c：SMHC0，PF0–PF5，1-bit，12 MHz
                             CMD17 单块读 / CMD24 单块写，CPU 搬 FIFO，sd_lock 互斥
```

与 xv6 的 `bio.c` 相比：

| 方面 | xv6 `bio.c` | miniOS `bio.c` |
| --- | --- | --- |
| 块大小 | 1024 B（`BSIZE`） | 512 B，正好一个 SD 扇区 |
| 缓冲数 | `NBUF = MAXOPBLOCKS × 3 = 30` | 24 |
| 每块锁 | 每个 `buf` 一把 sleeplock，`bread` 返回时已上锁 | 没有每块锁；FAT32 层的 `fs.lock` 一把互斥锁串行所有操作 |
| 写 | `bwrite` 由日志层决定何时写，`log_write` 钉住缓冲 | 直写，`bwrite` 立刻写卡；失败时把缓冲标成无效，下次重读 |
| 大块读 | 总是经过缓存 | `fat32_read` 对齐的整扇区直接 `t113_sd_read` 进调用者缓冲，绕过缓存 |
| 设备 | virtio，中断完成，进程 sleep | SMHC0 轮询，忙等 |

绕过缓存是安全的，因为缓存是直写：卡上的内容永远不比缓存旧。

### 调用链：打开并读一个文件

XR829 驱动装固件时的路径（`fwio.c` 的 `need_image()`）：

```text
need_image("/boot/fw_xr829.bin")
├── t113_vfs_open(path, VFS_O_RDONLY)                         vfs.c
│   ├── mutex_lock(&vfs_lock)
│   ├── find_mount(path)            "/" 和 "/boot" 都匹配，取更长的 "/boot"
│   ├── fat32_lookup(path, &node)                             fat32.c
│   │   ├── mutex_lock(&fs.lock)
│   │   ├── resolve(path, &d, parent = 0)
│   │   │   ├── mount_relative()    "/boot/fw_xr829.bin" → "fw_xr829.bin"
│   │   │   ├── d = 根目录（first = root_cluster，lba = 0）
│   │   │   └── dir_find(root_cluster, "fw_xr829.bin")
│   │   │       └── while dir_next() > 0: name_equal()        不区分大小写
│   │   │           └── bread → 命中或 t113_sd_read(lba, 1)
│   │   ├── iget(dir = 0, first, size, lba, off)              按目录项位置去重
│   │   └── fill_node()             node.private_data = fat_inode
│   └── 取一个空闲 open_files[]，offset = 0
├── t113_vfs_file_size(file)        174624
├── t113_alloc_pages(43)
├── t113_vfs_read(file, data, 174624)
│   └── fat32_read(&node, 0, data, 174624)
│       └── while done < count
│           ├── c = ibmap(ip, pos / 簇字节, 0)    游标让顺序读每簇只走一步
│           ├── 扇区对齐、剩余 ≥ 512、dst 4 字节对齐
│           │   └── t113_sd_read(lba, n, dst + done)   一次读到本簇末尾
│           └── 否则 bread(lba) → copy → brelse        首尾不对齐的零头
└── t113_vfs_close(file)
    └── fat32_close()               未修改，只做 ref--
```

### 调用链：创建并写一个文件

`tftp` 把下载的文件写进 `/boot` 时（`src/net/tftp/tftp_udp.c` 的
`write_file()`）：

```text
t113_vfs_open("/boot/minios-kernel.bin", RDWR | CREATE | TRUNC)
├── find_mount → fat32_ops
├── fat32_lookup() 失败（文件还不存在）
├── fat32_create(path, &node)
│   ├── resolve(path, &d, parent = 1, &name, &len)    停在父目录
│   ├── dir_find() 再确认不存在
│   ├── create_entry()                                LFN + 短项，first = 0
│   └── iget(0, 0, 0, lba, off)
└── fat32_truncate(&node)          新文件也走一遍
    ├── first = 0, size = 0, 清游标
    ├── iupdate(ip)                先改目录项...
    └── fat_free_chain(旧 first)   ...再释放旧簇链

t113_vfs_write(f, data, 4096) × N
└── fat32_write(&node, offset, src, count)
    ├── offset > size → -1          不支持稀疏文件
    └── while done < count
        ├── c = ibmap(ip, pos / 簇字节, alloc = 1)
        │   └── 走到链尾 → fat_alloc(c)
        │       ├── fat_set(new, EOC)   FAT1、FAT2 各 bread + bwrite
        │       └── fat_set(c, new)
        ├── 整扇区覆盖 → bget_blank(lba)   不必先读
        │   部分扇区   → bread(lba)
        ├── copy → bwrite → brelse       数据扇区立刻落盘
        └── size 变大 → dirty = 1

t113_vfs_close(f)
└── fat32_close()
    ├── dirty → iupdate()            目录项写回 first 和 size
    └── ref--
```

### 没有日志时的写入顺序

xv6 的每个文件系统调用包在 `begin_op()/end_op()` 里。日志提交前，所有修改
只存在于缓存和日志区，崩溃后要么全部重放，要么全部丢弃。miniOS 的 FAT32
没有日志，靠写入顺序把崩溃的后果限制在“丢空间，不丢一致性”：

| 操作 | 顺序 | 中途断电的后果 |
| --- | --- | --- |
| 追加写 | 先 `fat_alloc` 写 FAT，再写数据扇区，`close` 时最后写目录项 | 目录项还是旧的 first/size，新簇成为没人引用的“丢失簇”；`fsck` 能回收 |
| 截断 | 先 `iupdate` 把目录项清零，再 `fat_free_chain` | 旧链没释放完，同样只是丢失簇 |
| 新建 | 先写 LFN 项，再写短项 | 只有 LFN 没有短项时，校验和对不上，读目录会忽略这几项 |
| FSInfo | 第一次分配时把空闲计数写成 `0xffffffff` | 其他系统会重新数空闲簇，不会相信过期的计数 |

FAT 的两份副本是先后写的，中途断电时两份可能不一致。Windows 和 `fsck.vfat`
默认以第一份为准。

### T113 实现上的区别

- 块设备是 SD 卡本身：`bio.c` 的块号就是整卡 LBA，和 xv6 的“文件系统内块号”
  不同。FAT32 挂载时从 MBR 找第一个类型为 0x0b/0x0c/0x1b/0x1c 的分区，所有地址
  都加上 `part_lba`。
- `sunxi-sd.c` 和 SPL 共用：SMHC0 走 PF0–PF5，1-bit 总线，12 MHz，每次一块
  （CMD17/CMD24），CPU 轮询 FIFO。内核里加了 `sd_lock` 互斥锁，根文件系统
  （`rootdev.c`）和 `/boot` 共享这一个控制器。
- 一把锁：`fs.lock` 串行 FAT32 的所有操作，外面还有 VFS 的 `vfs_lock`。没有
  xv6 那种每个 inode、每个缓冲一把 sleeplock 的细粒度并发。
- 不支持：mkdir、unlink、rename、时间戳（固定写 2026-01-01）、稀疏写。目录只能
  读和在已有目录里新建文件。
- 失败可回退：`t113_fat32_mount_vfs()` 失败时，`kernel_boot()` 改挂
  `bootfs`，用 SPL 预加载到 DDR 的固件镜像（见 [ROOTFS_DEVFS.md](ROOTFS_DEVFS.md)）。

## 一致性与限制

- **没有日志**。写直达保证每次 `write` 返回时数据已经在卡上，但目录项
  里的大小和首簇只在最后一次 `close` 时写回。如果写到一半掉电，新分配
  的簇在 FAT 里已经占用，目录项却还是旧的大小，表现为文件内容没变、
  分区里多出一些丢失的簇，fsck（`fsck.fat` 或 macOS 磁盘工具）能回收。
- **锁**：整个 fat32 一把互斥锁（类似早期 xv6 的大锁），每个 VFS 回调
  从头锁到尾。互斥锁不可重入，fat32 内部函数之间不会重复加锁。
- **inode 表 16 项**：同时打开的不同 FAT32 文件最多 16 个（VFS 的
  `open_files` 也只有 32 个槽）。
- **SD 访问**：单块 CMD17/CMD24 轮询，没有 DMA、没有多块传输，大文件
  写入速度受此限制。

## 改动前后对照

| | 改动前（bootfs） | 改动后（fat32） |
| --- | --- | --- |
| 谁解析 FAT32 | SPL | 内核（SPL 也保留自己的只读解析器） |
| 数据来源 | 启动时 DDR 快照 | SD 卡，运行期实时读写 |
| 查找 | 三个硬编码路径 | 任意路径、长文件名、子目录 |
| `ls /boot` | 空 | 列出分区内容 |
| 写入 / 创建 / 截断 | ✗ | ✓ |
| 缓存 | 无（数据本来就在内存） | bio 24 块 LRU，写直达 |
| 失败时 | PANIC | 退回 bootfs，再失败才 PANIC |
| 与 Linux 对照 | firmware loader 读 initramfs 里的文件 | vfat 驱动挂载 `/boot` |

## 测试

主机测试（`gcc -fsanitize=address,undefined`，链接内核原样的 `vfs.c`、
`bio.c`、`fat32.c`，SD 读写换成对镜像文件的读写）：

- `mkfs.fat -F 32` 生成分区（每簇扇区数作为参数，测过不同簇大小）；
- 读 mtools 写入的长文件名文件和子目录里的文件，逐字节比对；
- `O_CREAT|O_TRUNC` 新建文件，用 512 字节和 300 字节交替写入（覆盖对齐
  和不对齐、跨扇区、跨簇），读回比对；
- 截断已有的 `fw_xr829.bin` 并重写；
- 在子目录里连续创建 40 个长文件名文件，触发目录追加新簇；
- 用 `fsck.fat -n` 检查分区无错误，再用 `mcopy` 读回内核写的文件比对。

上板预期串口输出：

```text
SPL: FAT32 kernel kernel_minios.img bytes=0x... crc32=0x...   # FAT32 上有内核时
SPL: skip bootpack kernel (FAT32 kernel used)
...
fat32: /boot mounted rw, partition lba=0x00002000 clusters=0x... cluster-bytes=0x...
mmc1:0001:1: loaded /boot/boot_xr829.bin bytes 2184
...
$ ls /boot
$ tftp 192.168.0.100 test.bin
tftp: received ... bytes in ... ms, crc32 0x...
tftp: saved /boot/test.bin
```

如果看到 `fat32: mount failed, using SPL handoff images`，说明 MBR 里没有
FAT32 分区或 BPB 校验失败，此时 `/boot` 退回老的只读视图。
