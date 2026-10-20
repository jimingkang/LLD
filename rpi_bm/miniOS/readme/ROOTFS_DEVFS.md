# miniOS 根文件系统（minifs）加载与 devfs

本文对应当前 miniOS 的实现，说明内核如何从 SD 卡找到并挂载根文件
系统（xv6 血统的 minifs）、VFS 挂载表的形状、`/boot` 的 FAT32 交接
（bootfs）、`/dev` 设备文件（devfs），以及用户态 `/init`、`/bin/sh`
是如何从根文件系统里跑起来的。

> **更新**：`/boot` 已改为内核直接读写的 FAT32 文件系统（bio + fat32），
> 挂载顺序也改成先 `/` 再 `/boot`，详见 [BOOT_FAT32.md](BOOT_FAT32.md)。
> 本文的 bootfs 小节现在描述的是 FAT32 挂载失败时的后备路径。

当前已打通的链路：

- SPL 读 SD 128 KiB 的 bootpack 装内核，再读 FAT32 分区把 XR829
  固件装进 DDR 并补写 bootpack 头（交接）；
- 内核 `kernel_boot()` 依次挂载 `/`（minifs，MBR 第 2 分区按需读）、`/boot`（FAT32，失败时退回 bootfs）、`/dev`（devfs），任一最终失败即 PANIC；
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

miniOS kernel_main()                          boards/100ask_t113/platform_kernel.c
├── t113_uart_init() / t113_mmu_init()
├── t113_bootpack_dump()                      打印全部条目（含 SPL 交接的固件）
└── kernel_boot()                             kernel/init/main.c
    ├── t113_page_alloc_init()                页分配器
    ├── t113_vfs_init()                       mount/super_block/inode/dentry/file 池清零
    ├── t113_minifs_mount_rootdev()           → /       失败 PANIC
    │   ├── t113_rootdev_init()               MBR 分区 2 解析
    │   │   ├── t113_sd_init()                SMHC0, 1-bit, 轮询
    │   │   └── 读 LBA0, 验 0x55AA, 取表项 2  type/lba/sectors
    │   ├── 读 root_lba+2 扇区                块 1 = superblock
    │   └── 验 magic 0x10203040, size×2 ≤ 分区扇区数 → t113_vfs_mount_fs("/")
    ├── t113_fat32_mount_vfs()                → /boot   读写 FAT32
    │   └── 失败 → t113_bootfs_mount_vfs()    → /boot   SPL 交接视图，再失败 PANIC
    ├── t113_devfs_init()                     → /dev    失败 PANIC
    ├── net_init()                            CONFIG_NET
    ├── t113_driver_core_init()               平台/sdio 驱动绑定
    │   ├── uart probe → t113_chrdev_register(1/3, 0) + t113_devfs_create_chrdev("console"/"ttyS0")
    │   └── xradio probe → need_image("/boot/*.bin")  经 VFS 读 FAT32 上的固件
    ├── t113_sched_init()
    ├── start_init_process()
    │   └── t113_vfs_open("/init") → t113_vfs_read() → t113_create_init_user_process()
    └── Timer0 + 开中断                       之后 idle: wfi

用户态
└── /init (init.c)
    ├── fork() + exec("/bin/sh")              sys_exec: VFS 打开 → ELF → 新地址空间
    └── wait() 孤儿回收, shell 退出后重启
```

`/` 和 `/dev` 是硬依赖；`/boot` 先试 FAT32、再退回 bootfs，两者都失败才算失败。任何一个最终失败，`kernel_boot()` 都打印 PANIC 并 `wfi` 死循环——没有根文件系统就没有用户态，无处可退。这对应 Linux “unable to mount root fs” 的 panic，只是 miniOS 连 initramfs 兜底都没有，也不需要：内核本身在 bootpack 里，卡上就是它的全部世界。挂载过程的图解见下一节。

## 图解：内核怎样把根文件系统挂到 `/`

### 挂载结果

先纠正一个容易混的点：devfs 挂在 `/dev`，不是 `/boot`。`/boot` 挂的是 SD 卡
第一个分区上的 FAT32；只有 FAT32 挂载失败时，才退回到 bootfs（SPL 预加载
镜像的只读视图）。启动完成后，整个命名空间是这样的：

```text
SD 卡                                  VFS 挂载表 mounts[8]          命名空间
┌──────────────┐
│ MBR          │                       [0] "/"     → minifs_vfs_ops   /
│ Boot0 / pack │                       [1] "/boot" → fat32_ops        ├── init
├──────────────┤  第 1 个 FAT32 分区     (失败时  → bootfs_ops)        ├── bin/ sh ls cat ...
│ 分区 1 FAT32 │ ──────────────────────────────────────────────────→  ├── boot/                FAT32
├──────────────┤  MBR 表项 2                                          │   ├── boot_xr829.bin
│ 分区 2 minifs│ ──────────────────────────────────────────────────→  │   ├── fw_xr829.bin
└──────────────┘                       [2] "/dev"  → devfs_ops        │   ├── sdd_xr829.bin
                                                                      │   └── wifi.txt
内存：devfs nodes[16] ───────────────────────────────────────────────→ └── dev/                 devfs
       （uart 驱动 probe 时注册）                                          ├── console
                                                                          └── ttyS0
```

`find_mount()` 按最长前缀选后端。路径分隔符要求完整匹配，所以 `/bootx` 不会
落到 `/boot`：

| 路径 | 匹配的挂载点 | 后端 |
| --- | --- | --- |
| `/init` | `/` | minifs |
| `/bin/sh` | `/` | minifs |
| `/boot` | `/`、`/boot`，取 `/boot` | fat32（根目录） |
| `/boot/fw_xr829.bin` | `/boot` | fat32 |
| `/bootx` | `/` | minifs（找不到就返回失败） |
| `/dev/console` | `/dev` | devfs |

### 启动时的挂载顺序

```text
SPL 跳到 0x40200000
└── kernel_entry.S
    └── kernel_main(dram_size)                     boards/100ask_t113/platform_kernel.c
        ├── t113_uart_init()                       早期串口
        ├── t113_mmu_init()                        内核 L1 表，打开 MMU
        ├── t113_bootpack_dump()
        └── kernel_boot(pool_base, dram_end)        kernel/init/main.c，与板子无关的部分
            ├── t113_page_alloc_init()
            ├── t113_vfs_init()                    清空 mount/super_block/inode/dentry/file 五个池
            ├── t113_minifs_mount_rootdev()        (1) "/"   失败 → PANIC
            │   ├── t113_rootdev_init()
            │   │   ├── t113_sd_init()             SMHC0：CMD0/8/ACMD41/2/3/7，切到 12 MHz
            │   │   ├── t113_sd_read(0, 1, mbr)    验 55 AA
            │   │   └── 表项 2：root_lba、root_sectors_count
            │   ├── t113_rootdev_read(2, 2, block_cache)     minifs 块 1 = 超级块
            │   ├── 验 magic 0x10203040，size × 2 ≤ 分区扇区数
            │   └── t113_vfs_mount_fs("/", MINIFS_MAGIC, &fs_sb, &minifs_vfs_ops)
            ├── t113_fat32_mount_vfs()             (2) "/boot"
            │   ├── binit()                        建 bcache
            │   ├── bread(0)：MBR，找第一个 FAT32 类型的分区
            │   ├── bread(part_lba)：BPB 校验并算出布局
            │   └── t113_vfs_mount_fs("/boot", 0x4d44, &fs, &fat32_ops)
            │       （先 lookup_path("/boot") 取 minifs 里的挂载点目录）
            │   失败 → t113_bootfs_mount_vfs()     (2') 退回 bootfs，再失败 → PANIC
            ├── t113_devfs_init()                  (3) "/dev"  失败 → PANIC
            ├── net_init()                         CONFIG_NET
            ├── t113_driver_core_init()            设备、驱动绑定
            │   ├── uart probe → t113_chrdev_register(1, 0, &console_fops)
            │   │                t113_chrdev_register(3, 0, &console_fops)
            │   │                t113_devfs_create_chrdev("console", 1, 0)
            │   │                t113_devfs_create_chrdev("ttyS0", 3, 0)
            │   └── mmc_rescan_all() → xradio probe → need_image("/boot/*.bin")
            ├── t113_sched_init()
            ├── start_init_process()
            │   ├── t113_vfs_open("/init") → minifs
            │   ├── t113_vfs_read() 整个 ELF 读进临时页
            │   └── t113_create_init_user_process()
            └── 打开定时器和中断，进入 wfi 循环
```

先挂 `/` 有一个具体原因：`t113_rootdev_init()` 负责 `t113_sd_init()`，也就是
初始化 SMHC0 和 SD 卡；FAT32 和它共用这个控制器。驱动必须在
`/boot`、`/dev` 都挂好之后才初始化，因为 XR829 的 probe 要从 `/boot` 读固件，
UART 的 probe 要往 `/dev` 里注册节点。

### rootdev：分区到块设备

minifs 的块是 1 KiB，SD 扇区是 512 B，`rootdev.c` 只做一次线性换算：

```text
minifs 块号 b  ──→  分区内扇区 2b, 2b+1  ──→  整卡 LBA root_lba + 2b

t113_rootdev_read(sector, count, dst)
├── 越界检查：sector + count ≤ root_sectors_count
└── t113_sd_read(root_lba + sector, count, dst)
```

它相当于 Linux 的分区块设备（`/dev/mmcblk0p2`），或 xv6 的 `ROOTDEV`
加上 `virtio_disk_rw()`。区别是它不经过任何缓存，缓存放在 minifs 里（只缓存
一块）。

### minifs 的磁盘布局和查找

minifs 沿用 xv6 `mkfs` 的格式（`MINIFS_MAGIC` 就是 xv6 的 `FSMAGIC`
0x10203040），布局和 xv6 一样：

```text
块:  0       1        2 ... logstart+nlog-1   inodestart ...     bmapstart ...   数据块 ...
    ┌──────┬────────┬──────────────────────┬────────────────┬─────────────┬─────────────┐
    │ boot │ super  │ log（minifs 不用）    │ inode 块        │ 空闲位图     │ 文件/目录内容 │
    └──────┴────────┴──────────────────────┴────────────────┴─────────────┴─────────────┘
           magic size nblocks ninodes nlog logstart inodestart bmapstart

struct minifs_dinode（64 B，每块 16 个）
├── type  1 = 目录，2 = 文件
├── major minor nlink
├── size
└── addrs[12] 直接块 + addrs[12] 一个间接块（256 项）  → 最大 268 KiB

struct minifs_dirent（32 B）
├── inum（u16）
└── name[30]
```

`exec("/bin/sh")` 在 minifs 里的查找：

```text
t113_vfs_open("/bin/sh")
└── minifs_vfs_lookup()
    └── t113_minifs_open() → namei("/bin/sh")
        ├── current = ROOTINO (1)
        ├── "bin": directory_lookup(1, "bin")
        │   ├── read_inode(1)          块 inodestart + 1/16，取第 1 项
        │   └── 逐个 32 B 目录项 inode_read() → 找到 inum = N
        ├── "sh":  directory_lookup(N, "sh") → inum = M
        └── *inum = M；read_inode(M) 得到 size
sys_exec → t113_vfs_read(file, image, size)
└── minifs_vfs_read() → t113_minifs_read(M, off, dst, n)
    └── inode_read()
        └── 每块：inode_block(inode, off / 1024)       直接块或间接块
                  block_address(b)                     命中 1 块缓存就直接用
                  └── t113_rootdev_read(2b, 2, block_cache)
```

和 xv6 的 `namex()` 相比，minifs 只读，所以不需要写日志；VFS 层仍然提供
inode/dentry 缓存与引用计数。minifs 内部现有解析器仍从根目录解析累计路径，
因为 T113 还没有每进程的当前目录 inode（`getcwd` 返回固定的 `/`）。

### devfs：`/dev` 下的字符设备

```text
驱动 probe 时                           用户或内核 open("/dev/console")
t113_chrdev_register(1, 0,              t113_vfs_open("/dev/console", RDWR)
                     &console_fops)     ├── lookup_path：find_mount → "/dev" 挂载根 dentry
└── chrdev_table[i] = { dev, fops }     │   └── 分量 "console" → devfs_iops.lookup(dir, child)
t113_devfs_create_chrdev(               │       └── inode: i_rdev=MINIOS_MKDEV(1,0)
   "console", 1, 0)                     │           i_fop=def_chr_fops
└── nodes[i] = { name, major, minor }   ├── file->f_op = inode->i_fop
                                        └── chrdev_open()：按 i_rdev 找 console_fops
                                            └── file->f_op = console_fops
                                        t113_vfs_write(f, "hi", 2)
                                        └── file->f_op->write() → console_write()
                                            └── UART3 发送
```

devfs 的节点不在任何磁盘上，是驱动在内存里登记的表。这和 Linux 的 devtmpfs
同一个思路：驱动注册设备时，内核自动在 `/dev` 下建节点。xv6 的做法不同：
设备节点是磁盘上的 inode（`T_DEVICE`，`mknod("console", CONSOLE, 0)` 由
`init` 创建），`read/write` 时按 `ip->major` 查 `devsw[]` 分派。

用户态 `/init` 打开 `/dev/console`，再用 `dup()` 建立 fd 0/1/2；所有控制台
I/O 都走 VFS → devfs → chrdev → UART，不再在系统调用层特判标准 fd。

### 与 xv6、Linux 的挂载方式对照

| 方面 | xv6 | Linux | T113 miniOS |
| --- | --- | --- | --- |
| 根文件系统从哪来 | 固定 `ROOTDEV`（virtio 盘，整盘是一个 fs） | `root=` 参数，`prepare_namespace()` → `mount_root()`，常先经 initramfs | MBR 第 2 分区，`t113_minifs_mount_rootdev()` |
| 何时挂载 | 第一个进程的 `forkret()` 里 `fsinit(ROOTDEV)`，因为读盘要 sleep | `kernel_init` 线程里，在 exec `/sbin/init` 之前 | `kernel_boot()` 里，在创建 init 之前；读盘是轮询，不用 sleep |
| 有没有挂载表 | 没有，只有一个文件系统 | `struct mount` 树，`vfsmount` 挂在 dentry 上 | `vfs_mount` 父子关系、mountpoint dentry，路径选择暂兼容最长前缀 |
| 第二个文件系统 | 不支持 | 任意 | `/boot` FAT32、`/dev` devfs |
| 设备文件 | 磁盘上的 `T_DEVICE` inode + `devsw[major]` | devtmpfs，驱动注册时建节点 | devfs，驱动注册时登记 |
| 挂载失败 | `panic("invalid file system")` | `VFS: Unable to mount root fs` panic | `kernel_platform_panic("cannot mount root filesystem")` |
| 用户态 mount | 无 | `mount(2)` | 无 |

### T113 实现上的区别

- 两个文件系统共用一个 SD 控制器（SMHC0）和一张卡。`rootdev.c` 不经
  `bio.c`；`fat32.c` 经 `bio.c`。两条路径都在 `t113_sd_read/write` 里的
  `sd_lock` 汇合。
- VFS 已建立 `super_block → dentry → inode → file` 对象链、引用计数和 inode/
  dentry 缓存，并让子 mount 保存父 mount 与 mountpoint。minifs/FAT32/devfs
  已直接提供各自的 `inode_operations/file_operations`；普通文件和设备文件
  最终都由 `file->f_op` 分派。
- 卡上的 SPL、bootpack、两个分区由同一个 `make install` 写入；分区 2 必须足够
  放下 `minifs.img`（≥ 32 MiB）。

## VFS：super_block、inode、dentry

VFS 已改成 Linux 式的对象模型，完整说明见 [VFS.md](VFS.md)。这里只列和
挂载、根文件系统直接相关的几点：

| miniOS | Linux |
| --- | --- |
| `vfs_mount` + `parent/mountpoint/mnt_root` | `struct mount` / `vfsmount` |
| `super_block` + `super_operations` | `struct super_block` |
| `dentry_cache[128]`、`inode_cache[128]` 与引用计数 | dcache / icache |
| `file` + `file_operations` + `f_pos_lock` | `struct file` + `f_count` |
| 全局 `vfs_lock` 一把互斥 | per-inode 锁 + RCU |

- **挂载**：`t113_vfs_mount_fs(path, magic, fs_info, s_op, root_iop, root_fop)` 为每个文件系统建一个
  `super_block`、一个根 inode 和一个根 dentry；不是 `/` 时还要先在父文件系统
  里 `lookup_path(path)` 找到挂载点目录，所以 minifs 镜像里必须有 `/boot`、
  `/dev` 两个空目录（`mkfs_minifs` 已经建好）。
- **选文件系统**：仍按最长前缀匹配（`/bootx` 不会落到 `/boot`），然后从那个
  挂载的根 dentry 开始逐级建 dentry。
- **原生操作表**：路径和元数据操作走 `inode->i_op`；打开后先从
  `inode->i_fop` 初始化 `file->f_op`。字符设备的 `chrdev_open()` 再把
  `file->f_op` 换成 UART、GPIO key 等驱动的操作表。
- **身份**：minifs 的 inode 号、FAT32 的 `fat_inode` 槽位地址、bootfs 的 DDR
  地址、devfs 的设备号成为 `inode->i_ino`；同一文件多次打开共享一个 inode。
- 读写带 `f_pos` 语义，但**没有 lseek**；标志支持 `VFS_O_RDONLY` /
  `VFS_O_RDWR`，外加 FAT32 用的 `VFS_O_CREATE` / `VFS_O_TRUNC`（值取自 xv6
  `fcntl.h`）。`write` 由 devfs 和 FAT32 实现；minifs 和 bootfs 只读。
- `minifs_vfs_lookup()` 同时返回目录和普通文件，因此 `/boot`、`/dev`、
  `/bin` 可以参与逐级查找和挂载点验证。

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

> 现在只是后备路径：正常情况下 `/boot` 由 `fat32.c` 挂载，见
> [BOOT_FAT32.md](BOOT_FAT32.md)。

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
- 驱动 probe 时做两件事：`t113_chrdev_register(major, minor, ops)` 把
  设备号和驱动操作登记进 `chrdev.c` 的 `chrdev_table[32]`（`ops` 至少要有
  read 或 write，设备号去重）；`t113_devfs_create_chrdev(name, major, minor)`
  在 `/dev` 下建名字（名字去重）。这和 Linux 的 `register_chrdev_region` +
  `cdev_add`、再由 devtmpfs 建节点是同一个分工；
- `lookup("/dev/console")` 建立字符设备 inode：`i_rdev =
  (major<<16)|minor`，`i_fop = def_chr_fops`；`readdir("/dev", i)` 枚举
  已注册设备；
- `def_chr_fops.open()` 按 `i_rdev` 查 `chrdev_table`，把本次打开的
  `file->f_op` 换成驱动 `file_operations`。之后 read/write 直接进入驱动，
  VFS 对字符设备不推进 `f_pos`。

当前唯一注册者是 UART 平台驱动（`uart.c` probe）：`console`（major 1, minor 0）和 `ttyS0`（major 3, minor 0），major 取值沿 Linux 惯例（1 = 内存/终端类，3 = 第一个 8250 串口）。注册时序有要求：`kernel_boot()` 里的 `t113_devfs_init()` 必须早于驱动绑定 `t113_driver_core_init()`，否则 probe 里的注册会失败。

**用户态 stdio**：`/init` 第一件事是 `open("/dev/console", O_RDWR)` 得到
fd 0，再 `dup(0)` 两次得到 fd 1、2；`syscall.c` 不再特判这三个 fd。shell
继承的 stdin/stdout 就是这个 devfs 文件，三个 fd 共享同一个 `struct file`。
另一个注册者是 `drivers/input/gpio_keys.c` 的 `/dev/key0`。

## 用户态视角：从 `/init` 到 shell

系统调用到 VFS 的映射（`src/kernel/syscall.c`，每进程
`files[T113_MAX_FDS=16]`，fd 0/1/2 由 `/init` 打开 `/dev/console` 建立）：

| 系统调用 | 内核路径 | 备注 |
| --- | --- | --- |
| `open(path, flags)` | `sys_open` → `t113_vfs_open` | 用户指针逐字节经 `user_vm_range_mapped` 校验拷入 |
| `read(fd, buf, n)` | `t113_vfs_read` | 控制台经 devfs → chrdev → UART |
| `write(fd, buf, n)` | `t113_vfs_write` | 单次 ≤ 256 B |
| `dup(fd)` | `t113_vfs_file_get` | 新 fd 共享同一个 `struct file` |
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
| `vfs_mount` 树 + 前缀匹配 | 无（只有一个 fs） | 挂载树 + namespace |
| `super_block` / `inode` / `dentry` 对象池 | `itable` inode 缓存，无 dentry | super_block、icache、dcache |
| 原生 `inode_operations` / `file_operations` | 无，直接调 fs 函数 | `inode_operations` + `file_operations` + `super_operations` |
| `rootdev`（MBR 分区） | `ide` 驱动 | 块设备层 + 分区扫描（`read_partition`） |
| minifs 只读 | xv6 fs（含 log 写入） | ext4 等 |
| 单块缓存 | 30 块 buffer cache | page cache |
| `/boot` FAT32（失败时退回 bootfs） | — | `/boot` 分区 + firmware loader |
| devfs + `chrdev_register` | mknod + `devsw[]` | devtmpfs + `device_create`（+ udev 用户态改名） |
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
fat32: /boot mounted rw, partition lba=0x???????? clusters=0x???????? cluster-bytes=0x????????
...
init: starting shell on console
```

`rootdev:`、`minifs:` 先出现，然后才是 `fat32:`：`kernel_boot()` 先挂 `/`（它顺带初始化 SD 卡），再挂 `/boot`。FAT32 挂载失败时会多一行 `fat32: mount failed, using SPL handoff images`，接着是 `bootfs: FAT32 handoff mounted at /boot`。devfs 挂载没有打印，驱动绑定后 `platform_dev_info` 会打印 uart 绑定信息。
