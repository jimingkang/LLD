# miniOS 根文件系统（minifs）加载与 devfs

本文对应当前 miniOS 的实现，说明内核如何从 SD 卡找到并挂载根文件
系统（xv6 血统的 minifs）、VFS 挂载表的形状、`/boot` 的 FAT32 交接
（bootfs）、`/dev` 设备文件（devfs），以及用户态 `/init`、`/bin/sh`
是如何从根文件系统里跑起来的。

当前已打通的链路：

- SPL 读 SD 128 KiB 的 bootpack 装内核，再读 FAT32 分区把 XR829
  固件装进 DDR 并补写 bootpack 头（交接）；
- 内核 `kernel_main()` 依次挂载 `/boot`（bootfs）、`/`（minifs，
  MBR 第 2 分区按需读）、`/dev`（devfs），任一失败即 PANIC；
- XR829 驱动从 `/boot/*.bin` 经 VFS 读固件（不再打进 bootpack）；
- 内核从 `/` 读出 `/init` 创建第一个用户进程；`init` fork+exec
  `/bin/sh`，shell 及 `ls/cat/echo/...` 都从 minifs 经 VFS 加载。

尚未实现：文件写入（minifs 只读）、minifs 日志区、devfs 作为用户态
stdio 后端、`mount`/`umount` 系统调用、多个块设备。

## SD 卡布局

| 区域 | 位置 | 内容 |
| --- | --- | --- |
| Boot0（SPL） | 8 KiB 偏移，512 B | miniBoot，SRAM 里跑，负责 DDR init + 装内核 |
| bootpack | 128 KiB 偏移 | 512 B header + kernel 镜像（见 `bootpack.h`） |
| MBR 分区 1 | FAT32 | `boot_xr829.bin` / `fw_xr829.bin` / `sdd_xr829.bin`（macOS 挂载于 `/Volumes/bootfs`） |
| MBR 分区 2 | minifs 根文件系统 | `build-t113/minifs.img` 整镜像 dd 进去，≥ 32 MiB |

分区 2 没有文件系统以外的含义：`rootdev.c` 只是取 MBR 第二个分区
表项的 LBA/长度当块设备用。分区本身用任何分区工具建（类型 0x83 即
可），FAT32 分区 1 是给 SPL 固件加载和人工换固件用的。

```text
SD 8 KiB    ┌────────────┐
            │ Boot0 SPL  │  读 128 KiB bootpack → 装内核
SD 128 KiB  ├────────────┤
            │ bootpack   │  header + kernel @0x40200000
分区 1      ├────────────┤
            │ FAT32      │  SPL 读固件 → DDR 0x40100000/0x40110000/0x40140000
分区 2      ├────────────┤
            │ minifs     │  内核 rootdev 按需读（块设备，非预载）
            └────────────┘
```

## 总调用链

```text
miniBoot SPL
└── spl_main()
    └── load_bootpack()
        ├── t113_sd_init()                    SMHC0 识别卡
        ├── 读 SD 128 KiB bootpack header     CRC32 校验
        ├── 逐条目读镜像到 load_addr + CRC32  kernel → 0x40200000
        ├── header 拷到 0x401ff000            内核侧查找入口
        └── load_fat32_firmware()             FAT32 交接
            ├── fat32_mount()                 MBR 找 FAT32 分区, BPB 解析
            ├── fat32_load_root() × 3         boot/fw/sdd_xr829.bin → DDR
            └── bootpack_slot()               补 3 个条目(offset=0 常驻), 重算 header CRC
        └── 跳 0x40200000

miniOS kernel_main()                          boards/100ask_t113/kernel.c
├── t113_uart_init() / t113_mmu_init()
├── t113_page_alloc_init()                    页分配器
├── t113_bootpack_dump()                      打印全部条目（含 FAT32 交接的固件）
├── t113_vfs_init()                           挂载表 + 文件表清零
├── t113_bootfs_mount_vfs()                   → /boot   失败 PANIC
├── t113_minifs_mount_rootdev()               → /       失败 PANIC
│   ├── t113_rootdev_init()                   MBR 分区 2 解析
│   │   ├── t113_sd_init()                    SMHC0, CMD17, 1-bit, 轮询
│   │   └── 读 LBA0, 验 0x55AA, 取表项 2      type/lba/sectors
│   ├── 读 root_lba+2 扇区                    块 1 = superblock
│   └── 验 magic 0x10203040, size×2 ≤ 分区扇区数 → t113_vfs_mount("/")
├── t113_devfs_init()                         → /dev    失败 PANIC
├── t113_driver_core_init()                   平台/sdio 驱动绑定
│   └── uart probe → t113_devfs_register_chrdev("console"/"ttyS0")
│   └── xr829 probe → need_image("/boot/*.bin")  经 VFS 读 FAT32 交接固件
├── t113_vfs_open("/init") → t113_alloc_pages() → t113_vfs_read()
│   └── t113_create_init_user_process()       第一个用户进程
└── GIC + sched + Timer0, cpsie i             之后 idle: wfi

用户态
└── /init (init.c)
    ├── fork() + exec("/bin/sh")              sys_exec: VFS 打开 → ELF → 新地址空间
    └── wait() 孤儿回收, shell 退出后重启
```

三个挂载点都是硬依赖：任何一个失败，`kernel_main()` 打印 PANIC 并
`wfi` 死循环——没有根文件系统就没有用户态，无处可退。这对应 Linux
"unable to mount root fs" 的 panic，只是 miniOS 连 initramfs 兜底
都没有，也不需要：内核本身在 bootpack 里，卡上就是它的全部世界。

## VFS：挂载表 + 文件表

`src/kernel/fs/vfs.c` 是一个约 200 行的最小 VFS，形状对齐 Linux：

| miniOS | Linux |
| --- | --- |
| `mounts[4]` + 最长前缀匹配 | 挂载树（`mount --bind` 语义近似） |
| `struct vfs_backend_ops` | `struct file_operations` / `super_operations` |
| `open_files[32]` 静态表 + `references` | 动态 `struct file` + `f_count` |
| 全局 `vfs_lock` 一把互斥 | per-inode 锁 + RCU |

后端接口（`include/fs/vfs.h`）：

```c
struct vfs_backend_ops {
    int (*open)(const struct vfs_node *node, uint32_t flags);
    int (*lookup)(const char *path, struct vfs_node *node);
    int (*read)(const struct vfs_node *node, uint32_t offset,
                void *destination, uint32_t count);
    int (*write)(const struct vfs_node *node, uint32_t offset,
                 const void *source, uint32_t count);
    int (*readdir)(const char *path, uint32_t index,
                   struct vfs_dirent *entry);
};
```

关键行为：

- **最长前缀匹配**：`t113_vfs_open("/boot/fw_xr829.bin")` 同时命中
  `/` 和 `/boot`，取前缀更长的 `/boot`。`mount_matches()` 还做边界
  检查（`/bootx` 不会误匹配 `/boot`，除非挂载路径以 `/` 结尾）。
- `lookup()` 由后端把路径解析成 `vfs_node {id, size, type,
  private_data}`：minifs 填 inode 号，bootfs 填 DDR 物理地址，devfs
  填 `(major<<16)|minor` 并用 `private_data` 直接指向注册的设备。
- 读写带 offset 语义（`file->offset` 前进），但 **没有 lseek**；标志
  只支持 `VFS_O_RDONLY` / `VFS_O_RDWR`。
- 当前三个后端只有 devfs 实现了 `write`——根文件系统整体只读。

## rootdev：MBR 分区 2 块设备

`src/kernel/fs/rootdev.c` + `src/drivers/mmc/sunxi-sd.c`：

- `sunxi-sd.c` 是 **SPL 和内核共用的一份源码**（`MINIOS_KERNEL` 宏
  区分是否加 mutex）：SMHC0（`0x04020000`，PF0..PF5，1-bit 总线），
  CMD17 单块读、轮询、CPU 搬 FIFO。SPL 用它读 bootpack/FAT32，内核
  用它读根文件系统——同一张卡的同一个控制器。
- `t113_rootdev_init()`：读 LBA 0，验证 `0x55 0xAA` 签名，取 MBR
  偏移 `446+16` 的第二个分区表项：type（偏移 4）、起始 LBA（+8）、
  扇区数（+12），type 非零、LBA 非零、≥ 4 扇区才接受。
- `t113_rootdev_read(sector, count, dst)` 做范围检查后转
  `t113_sd_read(root_lba + sector, ...)`。

## minifs：xv6 磁盘 ABI 的只读实现

`tools/mkfs_minifs.c`（主机侧）明确保留 xv6 mkfs 的磁盘格式，内核侧
`src/kernel/fs/minifs.c` 是只读遍历实现。常量与 xv6 一致：

| 常量 | 值 | 说明 |
| --- | --- | --- |
| `MINIFS_BSIZE` | 1024 | 块大小（= 2 个 SD 扇区） |
| `MINIFS_MAGIC` | 0x10203040 | xv6 `FSMAGIC` |
| `MINIFS_ROOTINO` | 1 | 根目录 inode 号 |
| `MINIFS_NDIRECT` | 12 | 直接块 |
| `MINIFS_DIRSIZ` | 30 | 文件名上限 |
| `dinode` | 64 B | type/major/minor/nlink/size/addrs[13] |
| `dirent` | 32 B | u16 inum + name[30] |

镜像布局（`FSSIZE=32768` 块 = 32 MiB，`NINODES=200`）：

```text
块 0            空（xv6 惯例留空）
块 1            superblock
块 2..31        log 区（30 块，只读实现不使用，格式保留）
块 32..44       inode 区（200/16+1 = 13 块，每块 16 个 dinode）
块 45..49       位图（32768/8192+1 = 5 块）
块 50..         数据区（含目录内容）
```

mkfs 产出的目录树（`miniOS/Makefile` 打包 `_init _sh _ls _echo
_pwd _cat _sleep _uptime`）：

```text
/                ino 1
├── bin/         sh, ls, echo, pwd, cat, sleep, uptime
├── dev/         空目录（minifs 里的占位；真设备在 devfs）
└── init         与 /bin/init 同一 inode（nlink=2，硬链接）
```

单文件上限 = 12 直接块 + 256 间接块 = 268 块 = 268 KiB；xv6 风格
目录 inode 的 `size` 被取整到完整块（`round_directory()`）。

### 两种挂载方式

| 函数 | 数据来源 | 用途 |
| --- | --- | --- |
| `t113_minifs_mount_vfs(image, bytes)` | DDR 里的镜像（`minifs_image.o` 可 objcopy 进内核） | 备用路径；T113 当前未链接 |
| `t113_minifs_mount_rootdev()` | MBR 分区 2，按需读块 | **当前使用** |

块设备模式的关键是**单块缓存**：`block_cache[1024]` + `cached_block`
只缓存最近一块。`block_address(block)` 命中缓存直接返回指针，未命中
则 `t113_rootdev_read(block*2, 2, cache)` 读两个扇区。这等于一个
只有一项的 page cache——读 `/init` 这种顺序小文件足够，遍历目录时
superblock（块 1）和 inode 区会反复换入换出，每读一个 dirent 的
inode 都可能多一次 SD 读。xv6 的 buffer cache 是 30 块 LRU，这里
刻意省掉了。

读路径（无 dcache、无 icache，每次 lookup 全程走磁盘）：

```text
namei("/bin/sh")
└── 逐分量 directory_lookup()
    ├── read_inode(dir_inum)                 块 = inodestart + inum/16
    ├── inode_read() 逐 dirent              inode_block(): 前 12 块直接, 之后查间接块
    └── names_equal(disk_name, component)   名字 ≤30 字节, NUL/长度双判
```

## bootfs：`/boot` 的 FAT32 交接

背景：XR829 三个固件文件现在放在 FAT32 分区里（方便换固件不用重烧
bootpack），但内核的 minifs 是只读小文件系统、rootdev 只认分区 2。
解法是分工：**SPL 读 FAT32（fat32.c，MBR + BPB + 簇链，支持长文件
名），内核只认 DDR 里已经就位的镜像**。

SPL 把固件装到 DDR 固定地址后，向 bootpack 头补写三个条目（`offset=0`
表示"常驻镜像，非 pack 内偏移"），重算头 CRC：

| 文件 | bootpack 条目 | DDR 地址 | 容量上限 |
| --- | --- | --- | --- |
| boot_xr829.bin | `boot_xr829` | 0x40100000 | 64 KiB |
| fw_xr829.bin | `fw_xr829` | 0x40110000 | 192 KiB |
| sdd_xr829.bin | `sdd_xr829` | 0x40140000 | 64 KiB |

内核侧 `bootfs.c` 把这三条暴露成普通文件：

- `lookup("/boot/fw_xr829.bin")` → `t113_bootpack_find("fw_xr829")`，
  `node.id = load_addr`（物理地址当文件 id）；
- `read()` 就是 `memcpy`——数据已在 DDR，零拷贝语义。

XR829 驱动的 `need_image()` 因此从硬编码 bootpack 查询改成了标准
VFS 调用（`t113_vfs_open("/boot/fw_xr829.bin")` → 读到页分配的
缓冲），驱动不再依赖 bootloader 私有的地址常量。若 FAT32 分区缺失，
SPL 回退使用 bootpack 内打包的固件（老路径仍保留）。

## devfs：`/dev` 设备文件

`src/kernel/fs/devfs.c` 对应 Linux 早期的 devfs（现代等价物是
devtmpfs）：

- `t113_devfs_init()`：挂到 `/dev`，16 个节点槽，设备名 ≤ 30 字节
  且不含 `/`；
- `t113_devfs_register_chrdev(name, major, minor, ops)`：驱动 probe
  时注册，名字去重，`ops` 至少要有 read 或 write；
- `lookup("/dev/console")`：`node.id = (major<<16)|minor`、
  `type = DEVFS_T_CHAR`、`private_data` 指向节点；`/dev` 本身作为
  目录节点（type 1）返回，`readdir("/dev", i)` 枚举已注册设备；
- `read`/`write` 直接转发 `ops`，**忽略 offset**——字符设备没有
  seek 语义，这和 Linux `struct file_operations` 里 `.llseek =
  no_llseek` 的约定一致。

当前唯一注册者是 UART 平台驱动（`uart.c` probe）：`console`（major
1, minor 0）和 `ttyS0`（major 3, minor 0），major 取值沿 Linux 惯例
（1 = 内存/终端类，3 = 第一个 8250 串口）。注册时序有要求：devfs
挂载（`kernel_main` 第 49 行）必须早于驱动绑定（第 56 行
`t113_driver_core_init()`），否则 probe 里的注册会失败。

**与用户态 stdio 的现状**：`syscall.c` 里 fd 0/1/2 仍特判直连 UART
（read 轮询 + `sched_yield`，write 逐字节 `putc`），`/dev/console`
还没接成 stdio 后端；minifs 镜像里的 `/dev` 目录只是占位。也就是说
devfs 目前是"设备文件存在、可 open/read/write"，但 shell 的
stdin/stdout 还没走它。这与 Linux 的差异：Linux 由 initramfs 里的
init 先 `mknod`/打开 `/dev/console` 再 exec 各服务，devfs 一步到位
省掉 mknod。

## 用户态视角：从 `/init` 到 shell

系统调用到 VFS 的映射（`boards/100ask_t113/syscall.c`，fd 从 3 起，
每进程 `files[T113_MAX_FDS=4]`）：

| 系统调用 | 内核路径 | 备注 |
| --- | --- | --- |
| `open(path, flags)` | `sys_open` → `t113_vfs_open` | 用户指针逐字节经 `user_vm_range_mapped` 校验拷入 |
| `read(fd, buf, n)` | fd=0 特判 UART；否则 `t113_vfs_read` | |
| `write(fd, buf, n)` | fd=1/2 特判 UART；否则 `t113_vfs_write` | 单次 ≤ 256 B |
| `close(fd)` | `t113_vfs_close` | 引用计数归零才释放槽位 |
| `readdir(path, i)` | `t113_vfs_readdir` | `ls` 的实现基础 |
| `exec(path, argv)` | `sys_exec` → `t113_vfs_open` + ELF 加载 | 镜像 ≤ 16 页（64 KiB） |
| `getcwd` | 常量 `"/"` | 尚无每进程 cwd，pwd 是假的 |

内核加载 `/init` 本身（`kernel_main` 尾部）就是一次普通 VFS 读：
open → 按文件大小 `alloc_pages` → read → `create_init_user_process`
→ 释放临时页。`/init` 再 `fork()` + `exec("/bin/sh")`，shell 的
每次命令执行又是一次 `exec` → VFS → minifs 读块。整条用户态生命线
都吊在 rootdev 的 CMD17 上。

## 与 Linux / xv6 的对照

| miniOS | xv6 | Linux |
| --- | --- | --- |
| `mounts[4]` + 前缀匹配 | 无（只有一个 fs） | 挂载树 + namespace |
| `vfs_backend_ops` | `struct inode` ops | `file_operations` + `super_operations` |
| `rootdev`（MBR 分区） | `ide` 驱动 | 块设备层 + 分区扫描（`read_partition`） |
| minifs 只读 | xv6 fs（含 log 写入） | ext4 等 |
| 单块缓存 | 30 块 buffer cache | page cache |
| `/boot` bootfs | — | initramfs 早期文件 / firmware loader |
| devfs + `register_chrdev` | mknod + `console` 特例 | devtmpfs + `device_create`（+ udev 用户态改名） |
| `kernel_main` 读 `/init` | 第一个进程硬编码在 initcode.S | initramfs 的 `/init` → exec `/sbin/init` |
| PANIC + `wfi` | `panic()` | `panic()` |

## 构建与烧写

```sh
make t113                    # 内核 + minifs.img（mkfs_minifs 打包 init/sh/ls/...）
make install T113_DISK=/dev/diskX
# 内部依次：
#   dd minios-t113.bin  @ 8 KiB    (Boot0)
#   dd bootpack.bin     @ 128 KiB  (kernel)
#   cp firmware/xr829/*.bin → /Volumes/bootfs   (FAT32, install-firmware)
#   dd minifs.img → /dev/diskXs2                (install-rootfs)
```

换固件只动 FAT32 分区；改用户程序（`user-t113/*.c`）只需重跑
`install-rootfs`，内核和 bootpack 不用重烧。

## 预期串口输出

（LBA/大小以实际卡为准，下面是格式示例）

```text
SPL: SDHC card ready
SPL: load kernel -> 0x40200000 bytes=0x?????? ok
SPL: FAT32 partition LBA=0x00002000
SPL: FAT32 load boot_xr829.bin bytes=0x888
SPL: FAT32 load fw_xr829.bin bytes=0x2aa20
SPL: FAT32 load sdd_xr829.bin bytes=0x2e8
...
bootpack: kernel @0x40200000 bytes=0x????????
bootpack: boot_xr829 @0x40100000 bytes=0x00000888
bootpack: fw_xr829 @0x40110000 bytes=0x0002aa20
bootpack: sdd_xr829 @0x40140000 bytes=0x000002e8
rootdev: MBR partition 2 type=0x83 lba=0x?????? sectors=0x??????
minifs: mounted block rootfs blocks=0x8000 inodes=0xc8
bootfs: FAT32 handoff mounted at /boot
mmc1:0001:1: loaded /boot/boot_xr829.bin bytes 2184
...
init: starting shell on console
```

注意 `bootfs:` 的打印早于 `rootdev:`——`kernel_main` 先挂 `/boot`
再挂 `/`，两者互不依赖；devfs 挂载没有打印，驱动绑定后
`platform_dev_info` 会打印 uart 绑定信息。
