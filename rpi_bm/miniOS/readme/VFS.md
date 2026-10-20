# miniOS VFS：原生 inode/file 操作分派

miniOS 的 T113 VFS 使用 `super_block`、`dentry`、`inode`、`file` 和
`vfs_mount` 组织挂载与打开文件。当前版本已经删除旧的
`vfs_backend_ops` 和通用适配器 `backend_fops`：每个文件系统直接提供
自己的 `inode_operations` 与 `file_operations`，字符设备在打开时把
`file->f_op` 切换成驱动的操作表。

## 核心对象

```c
struct super_block {
    uint32_t s_magic;
    const struct super_operations *s_op;
    struct dentry *s_root;
    void *s_fs_info;
};

struct inode {
    uint32_t i_ino;
    uint32_t i_size;
    uint32_t i_type;
    uint32_t i_rdev;
    struct super_block *i_sb;
    const struct inode_operations *i_op;
    const struct file_operations *i_fop;
    void *i_private;
};

struct file {
    uint32_t f_flags;
    uint32_t f_pos;
    struct dentry *f_dentry;
    struct inode *f_inode;
    const struct file_operations *f_op;
    void *private_data;
    struct mutex f_pos_lock;
};
```

- `super_block` 表示一次文件系统挂载。
- `dentry` 表示路径中的名字，并指向 inode。
- `inode` 表示文件、目录或设备节点本身。
- `file` 表示一次 `open()`；`dup()` 和 `fork()` 可以共享它。
- `i_rdev` 仅对字符设备有意义，保存 major/minor 合成的设备号。
- `private_data` 给设备驱动保存每次打开的私有状态。

## 三张操作表

```c
struct super_operations {
    void (*put_super)(struct super_block *sb);
    void (*evict_inode)(struct inode *inode);
};

struct inode_operations {
    int (*lookup)(struct inode *dir, struct dentry *child);
    int (*create)(struct inode *dir, struct dentry *child);
    int (*truncate)(struct inode *inode);
};

struct file_operations {
    int (*open)(struct inode *inode, struct file *file);
    int (*read)(struct file *file, void *buf, uint32_t count);
    int (*write)(struct file *file, const void *buf, uint32_t count);
    int (*readdir)(struct inode *inode, const char *path,
                   uint32_t index, struct vfs_dirent *entry);
    void (*release)(struct inode *inode, struct file *file);
};
```

职责划分：

```text
inode->i_op   路径和元数据：lookup/create/truncate
inode->i_fop  此 inode 默认的打开后操作
file->f_op    本次 open 实际使用的操作，可在 open 中替换
```

## 普通文件

minifs、FAT32 和 bootfs 都直接提供自己的操作表：

```text
minifs inode
├── i_op  = minifs_iops
└── i_fop = minifs_file_fops 或 minifs_dir_fops

FAT32 inode
├── i_op  = fat32_iops
└── i_fop = fat32_file_fops 或 fat32_dir_fops
```

读取 `/bin/ls`：

```text
sys_read(fd)
  → current->files[fd]
  → file->f_op->read(file, ...)
  → minifs_vfs_read()
  → 根据 file->f_inode->i_ino 读取 SD 卡 minifs 数据块
```

读取 `/boot/kernel_minios.img`：

```text
sys_read(fd)
  → file->f_op->read
  → fat32_read()
  → file->f_inode->i_private（fat_inode）
  → FAT 簇链与 SD 块设备
```

不再经过 `backend_read()` 或 `super_block->s_backend`。

## 字符设备

devfs 只维护“名字到设备号”的关系：

```text
"console" → inode(type=CHAR, i_rdev=1:0)
"ttyS0"   → inode(type=CHAR, i_rdev=3:0)
"key0"    → inode(type=CHAR, i_rdev=13:0)
```

字符设备 inode 的默认操作是 `def_chr_fops`：

```text
inode->i_fop = def_chr_fops
                   │
                   └── open = chrdev_open
```

`chrdev_open()` 根据 `inode->i_rdev` 查询全局字符设备表，然后替换本次
打开文件的操作表：

```c
file->f_op = driver_fops;
```

因此 `/dev/console` 的完整路径是：

```text
open("/dev/console")
  → devfs_iops.lookup
  → inode(i_rdev=1:0, i_fop=def_chr_fops)
  → file->f_op = inode->i_fop
  → def_chr_fops.open
  → chrdev_find(1:0)
  → file->f_op = console_fops

read(fd)
  → file->f_op->read
  → console_read
  → t113_uart_read
```

GPIO 按键同样执行：

```text
/dev/key0 → 13:0 → gpio_keys_fops → gpio_keys_read
```

devfs 不再提供 `devfs_read()` 或 `devfs_write()`，也不接触 UART/GPIO
寄存器。

## 路径查找

`lookup_path()` 先以最长前缀选择挂载，再从该挂载的根 dentry 开始逐分量
查找：

```text
/bin/ls
  → minifs root inode
  → i_op->lookup(parent inode, child dentry "bin")
  → bin inode
  → i_op->lookup(bin inode, child dentry "ls")
  → ls inode
```

文件系统的 `lookup()` 调用 `t113_vfs_bind_inode()`，把查找结果绑定到
dentry，并设置该 inode 的 `i_op/i_fop/i_private`。inode cache 使用
`(super_block, i_ino)` 作为键。

目前 devfs 直接使用 `child->d_name`；minifs 和 FAT32 虽然已经原生实现
`i_op->lookup`，内部仍利用 `child->d_path` 复用现有的完整路径解析器。后续
可以把这两个解析器继续收窄为“父 inode + 单个分量”。

## 挂载

```c
int t113_vfs_mount_fs(const char *path,
                      uint32_t magic,
                      void *fs_info,
                      const struct super_operations *s_op,
                      const struct inode_operations *root_iop,
                      const struct file_operations *root_fop);
```

当前挂载：

```text
/       minifs，SD 第二分区，只读
/boot   FAT32，SD 第一分区，读写；失败时可退回 bootfs
/dev    devfs，动态字符设备节点
```

挂载根 inode 直接使用文件系统传入的 `root_iop/root_fop`。FAT32 通过
`super_operations.evict_inode` 在最后一个 VFS inode 引用释放时写回目录项
并释放 `fat_inode` 引用。

## 与 Linux 的关系

当前主要派发方式已经与 Linux 一致：

```text
路径操作       inode->i_op
普通文件 I/O   file->f_op → 文件系统 fops
字符设备 I/O   file->f_op → 驱动 fops
设备选择       inode->i_rdev → chrdev table
```

miniOS 仍然比 Linux 简化：对象来自静态池，没有 RCU、页缓存、完整权限模型、
负 dentry、umount 和并发 rename；挂载切换仍先用最长字符串前缀选挂载，而不
是在逐级 path walk 中穿越 mountpoint。

## `vfs.h` 当前保留的重要结构体

`vfs.h` 是文件系统、devfs 和设备驱动共同依赖的公开接口。当前重要结构体可以
分成“操作表”“VFS 对象”和“目录项输出”三组。

### 操作表

```text
super_operations
├── put_super(sb)       卸载或释放文件系统实例（目前尚未实现 umount）
└── evict_inode(inode)  VFS inode 最后一个引用消失时释放文件系统私有对象

inode_operations
├── lookup(dir, child)  在目录中查找一个名字，并给 child 绑定 inode
├── create(dir, child)  创建普通文件并绑定 inode
└── truncate(inode)     截断文件

file_operations
├── open(inode, file)   初始化本次打开；也可以替换 file->f_op
├── read(file, ...)
├── write(file, ...)
├── readdir(inode, path, index, entry)
└── release(inode, file)
```

`inode_operations` 操作的是文件系统名字空间和文件元数据；
`file_operations` 操作的是一次已经打开的文件。当前 `readdir()` 仍以 inode
而不是打开的目录 file 为参数，这是 miniOS 的简化，并非完整 Linux 接口。

### VFS 对象

```text
vfs_mount
├── path                 挂载路径，例如 /、/boot、/dev
├── sb ───────────────────────────────┐
├── mnt_root ────────────────┐        │
├── parent                   │        │
└── mountpoint               │        │
                             ▼        ▼
                         dentry    super_block
                         ├── d_name   ├── s_magic
                         ├── d_path   ├── s_op
                         ├── d_parent ├── s_root ──> 根 dentry
                         ├── d_sb ────┤
                         └── d_inode  └── s_fs_info
                                │
                                ▼
                              inode
                              ├── i_ino / i_size / i_type
                              ├── i_rdev
                              ├── i_sb
                              ├── i_op
                              ├── i_fop
                              └── i_private

进程 fd 表 ──> file
               ├── f_dentry ──> dentry
               ├── f_inode  ──> inode
               ├── f_op
               ├── f_pos / f_pos_lock
               └── private_data
```

各对象分别回答不同问题：

| 对象 | 表示什么 | 关键关系 |
|---|---|---|
| `super_block` | 一次文件系统实例 | `s_root` 指向根 dentry；`s_fs_info` 保存 minifs/FAT32/devfs 的实例数据 |
| `dentry` | 路径中的一个名字 | `d_parent` 构成目录层次，`d_inode` 指向名字对应的 inode |
| `inode` | 文件、目录或设备节点本身 | `i_op` 管路径/元数据，`i_fop` 是默认打开操作 |
| `file` | 一次 `open()` 形成的打开文件描述 | `f_op` 是本次打开最终使用的操作表；`f_pos` 是共享偏移 |
| `vfs_mount` | 把一个 super block 接到路径树上 | 保存挂载路径、父挂载和挂载点 |
| `vfs_dirent` | `readdir()` 返回给调用者的一项 | 只是结果结构，不参与缓存和引用关系 |

三个私有指针不要混淆：

```text
super_block.s_fs_info  每次挂载/文件系统实例的私有数据
inode.i_private       某个 inode 的文件系统私有数据，例如 FAT inode
file.private_data     某次 open 的私有数据，例如设备会话状态
```

### 引用和共享关系

当前对象来自 `vfs.c` 的固定大小静态池：8 个 mount、8 个 super block、128 个
inode、128 个 dentry 和 32 个 file。它们不是动态分配的。

```text
mount 持有 super_block 和根 dentry
dentry 持有 inode，并持有父 dentry
file 持有 dentry；通过 dentry 间接保持 inode 有效
进程 files[fd] 持有 file
dup()/fork() 增加同一个 file->references
```

因此 `dup()` 或 `fork()` 后多个 fd/进程共享同一个 `struct file`，也共享
`f_pos`；普通文件用 `f_pos_lock` 串行化 I/O 和偏移更新。字符设备不使用文件
位置，所以 `t113_vfs_read/write()` 不为字符设备获取 `f_pos_lock`。

`vfs_lock` 只保护对象池、引用计数和 file 有效性检查。读写时 VFS 先在锁内临时
增加 `file->references`，随后释放全局锁，再调用 `file->f_op->read/write()`；
这样 UART 阻塞读取时不会长期占用全局 VFS 锁。

## `chrdev.h` 当前保留的内容

`chrdev.h` 刻意保持很薄，目前没有公开 `struct cdev` 或
`struct chrdev_entry`。它只包含：

```c
MINIOS_MKDEV(major, minor)  /* 组合 16 位 major 和 16 位 minor */
MINIOS_MAJOR(dev)
MINIOS_MINOR(dev)

void t113_chrdev_init(void);
int t113_chrdev_register(uint16_t major, uint16_t minor,
                         const struct file_operations *fops);
const struct file_operations *t113_chrdev_inode_fops(void);
```

真正的注册表结构是 `chrdev.c` 的私有实现：

```c
struct chrdev_entry {
    uint32_t dev;                         /* 完整 major:minor */
    const struct file_operations *fops;  /* 具体设备驱动操作 */
    uint32_t used;
};

static struct chrdev_entry chrdev_table[32];
```

这种封装意味着 VFS、devfs 和驱动都不能直接遍历或修改全局字符设备表，只能调用
注册接口。`chrdev_lock` 保护注册和查找。当前没有注销接口、设备号范围、动态
major、`struct cdev`、引用计数或驱动卸载，因此它更接近 Linux 2.4 的简单注册
表，而不是 Linux 2.6 以后的 `cdev_map`。

## `vfs.h` 与 `chrdev.h` 的关系

`chrdev.h` 依赖 `vfs.h`，因为字符设备最终注册的是 VFS 定义的
`struct file_operations`：

```text
具体驱动
  └── console_fops / gpio_keys_fops
          │
          │ t113_chrdev_register(major, minor, fops)
          ▼
chrdev_table：dev_t -> driver fops

devfs
  └── 名字 -> dev_t
      例如 "console" -> 1:0

VFS inode
  ├── i_type = VFS_NODE_CHAR
  ├── i_rdev = 1:0
  └── i_fop = def_chr_fops
                    │ open
                    ▼
              chrdev_open()
                    │ 根据 i_rdev 查 chrdev_table
                    ▼
              file->f_op = console_fops
```

这里实际存在两张彼此独立的表：

| 表 | 保存的映射 | 负责什么 |
|---|---|---|
| devfs `nodes[]` | `"console" -> (1,0)` | 路径名字和设备号的关系 |
| chrdev `chrdev_table[]` | `(1,0) -> console_fops` | 设备号和驱动操作的关系 |

`t113_devfs_create_chrdev("console", 1, 0)` 只创建第一种映射；
`t113_chrdev_register(1, 0, &console_fops)` 只创建第二种映射。两步都成功后，
`/dev/console` 才能正常打开并到达 UART 驱动。

## 从系统调用到对象的完整关系

以 `read(fd, buffer, count)` 为例：

```text
用户 fd（整数）
  -> current->files[fd]             struct file *
  -> t113_vfs_read(file, ...)
       ├── 临时增加 file 引用
       ├── 普通文件：锁住 file->f_pos_lock
       └── file->f_op->read(file, ...)
              ├── 普通文件：minifs/FAT32 fops
              │      -> file->f_inode
              │      -> inode->i_private / inode->i_sb->s_fs_info
              │      -> SD 块设备
              └── 字符设备：console_fops
                     -> UART RX 缓冲区/寄存器
```

用户态的 fd 只是当前进程 fd 表的数组下标；内核 `struct file` 才是打开文件
对象。它既不是磁盘上的文件，也不是 inode。多个 fd 可以指向同一个 file，一个
inode 也可以同时对应多个相互独立、偏移不同的 file。
