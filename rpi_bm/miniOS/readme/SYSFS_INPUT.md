# miniOS sysfs 与 GPIO 按键驱动

本文按当前代码说明两件新加的东西：`/sys` 怎样把内存里的 driver core（kobject、
device、bus、driver）投影成目录和只读文件；100ASK T113-S3 上 RESET 旁的 USER KEY
怎样经 `gpio-keys` 驱动变成 `/dev/key0` 的按键事件，以及它在 `/sys` 里的属性。

| 文件 | 内容 |
| --- | --- |
| `src/kernel/fs/sysfs.c` | sysfs 文件系统：lookup、readdir、read |
| `src/include/fs/sysfs.h` | `t113_sysfs_init()` |
| `src/fs/Kconfig` | `CONFIG_SYSFS`，T113 板默认打开 |
| `src/include/t113/device.h` | 新增 `struct device_attribute`，`struct device` 加 `attributes/num_attributes` |
| `src/boards/100ask_t113/device.c` | 解绑或 probe 失败时清空属性表 |
| `src/drivers/input/gpio_keys.c` | 按键驱动 |
| `src/include/input/gpio_keys.h` | 平台数据和 `struct minios_input_event` |
| `src/boards/100ask_t113/board.c` | `user-key` 平台设备，PB4 |
| `src/boards/100ask_t113/gpio.c` | GPIO 外部中断寄存器操作 |
| `user-t113/keytest.c`、`user-t113/include/input.h` | 用户态测试程序和事件结构 |
| `tools/mkfs_minifs.c` | 在根文件系统里建空目录 `/sys` 作为挂载点 |

## 1. sysfs

### 1.1 挂载时机

```text
kernel_boot()                                    kernel/init/main.c
├── t113_minifs_mount_rootdev()      /
├── t113_fat32_mount_vfs()           /boot
├── t113_chrdev_init()
├── t113_devfs_init()                /dev
├── ...
├── t113_driver_core_init()          建 devices/bus/drivers 三个 kset，注册设备和驱动，扫 MMC
└── t113_sysfs_init()                /sys，失败 → PANIC "cannot mount sysfs at /sys"
    └── t113_vfs_mount_fs("/sys", 0x62656572, 0, 0, &sysfs_iops, &sysfs_dir_fops)
```

`0x62656572` 是 Linux 的 `SYSFS_MAGIC`（ASCII "beer"）。sysfs 不保存任何数据：
`super_block` 没有 `s_fs_info`，也没有 `super_operations`。每次 lookup、readdir、
read 都直接去查 driver core 当时的状态，所以先挂后挂都可以；放在
`t113_driver_core_init()` 之后只是为了让挂载时树已经完整。

mount 时 VFS 要先在 minifs 里找到 `/sys` 目录，所以 `mkfs_minifs` 新建了一个空的
`sys` 目录。旧的 `minifs.img` 没有它，必须重新 `make t113` 并烧写分区 2，否则
启动会停在上面的 PANIC。

### 1.2 目录结构

sysfs 只认两棵子树：

```text
/sys
├── devices/                         按 device.parent 展开的设备拓扑
│   └── <dev>/[<child>/...]
│       ├── name   bus   driver   path       每个设备都有的 4 个属性
│       └── <驱动提供的属性>                    device->attributes[]
└── bus/
    └── <bus>/
        ├── name
        ├── devices/<dev>/                   与 /sys/devices 下同一设备的属性相同
        └── drivers/<drv>/
            ├── name
            └── bound                        绑定到这个驱动的设备名，空格分隔
```

下面是主机侧测试的实际输出（见第 3 节；注册了 `uart3`、`timer0`、`user-key` 三个
平台设备和 `t113-uart`、`gpio-keys` 两个驱动）。板子上还会有 `gic`、`twi2`、
`sdc1`、`csi0`，以及 `i2c`、`sdio` 两条总线和它们下面的设备。

```text
/sys/
  devices/
    platform/
      uart3/
        name  = "uart3"
        bus  = "platform"
        driver  = "t113-uart"
        path  = "/devices/platform/uart3"
      timer0/
        name  = "timer0"
        bus  = "platform"
        driver  = "(none)"
        path  = "/devices/platform/timer0"
      user-key/
        name  = "user-key"
        bus  = "platform"
        driver  = "gpio-keys"
        path  = "/devices/platform/user-key"
        value  = "0"
        keycode  = "28"
        irq_count  = "0"
        pending  = "0"
        mux  = "14"
      name  = "platform"
      bus  = "(none)"
      driver  = "(none)"
      path  = "/devices/platform"
  bus/
    platform/
      devices/
        uart3/ ...  timer0/ ...  user-key/ ...      内容同上
      drivers/
        t113-uart/
          name  = "t113-uart"
          bound  = "uart3"
        gpio-keys/
          name  = "gpio-keys"
          bound  = "user-key"
      name  = "platform"
```

`/sys/devices/platform` 自己也是一个 `struct device`（`platform_bus`），所以它下面
既有子设备目录，也有 4 个属性文件。

### 1.3 路径怎样对应到 driver core

kobject 的路径由 `kobject_get_path()` 沿 `parent` 链拼出。`device_add()` 把每个设备
加进 `devices` kset；没有 parent 的 kobject 以 kset 自己的 kobject 为 parent，所以
平台设备的路径是 `/devices/platform/<name>`（`platform_device_register()` 把
`dev.parent` 设成 `platform_bus`）。

sysfs 把 `/sys/devices/a/b` 去掉 `/sys` 后得到 `/devices/a/b`，再在 `devices` kset
里找路径相同的 kobject：

```text
split_path("/sys/devices/platform/user-key/value")
  → part[] = { "devices", "platform", "user-key", "value" }，最多 8 级，每级 ≤ 30 字节
sysfs_path_type()
  ├── device_model_path(全部 4 级) = "/devices/platform/user-key/value"
  │   find_device_path() → 没有这个设备
  ├── device_model_path(前 3 级)   = "/devices/platform/user-key"
  │   find_device_path() → user-key 的 struct device（get_device 加引用）
  ├── 最后一级 "value"：不是 name/bus/driver/path，查 device->attributes[] → 找到
  └── 返回 VFS_NODE_FILE，put_device()
```

`/sys/bus/...` 则按层数解析：

| 路径 | 类型 | 查法 |
| --- | --- | --- |
| `/sys/bus` | 目录 | 固定 |
| `/sys/bus/<bus>` | 目录 | `kset_find_obj(buses, name)` |
| `/sys/bus/<bus>/name` | 文件 | `bus->name` |
| `/sys/bus/<bus>/devices`、`drivers` | 目录 | 固定 |
| `/sys/bus/<bus>/devices/<dev>` | 目录 | `bus_find_device_by_name()` |
| `/sys/bus/<bus>/devices/<dev>/<attr>` | 文件 | 同上，再查属性名 |
| `/sys/bus/<bus>/drivers/<drv>` | 目录 | `bus_for_each_drv()` 按名字找 |
| `/sys/bus/<bus>/drivers/<drv>/name`、`bound` | 文件 | 同上 |

### 1.4 三个 VFS 操作

sysfs 只有一张 `inode_operations` 和两张 `file_operations`：

```c
static const struct inode_operations sysfs_iops = { .lookup = sysfs_lookup };
static const struct file_operations sysfs_dir_fops = { .readdir = sysfs_readdir };
static const struct file_operations sysfs_file_fops = { .read = sysfs_read };
```

**lookup。** `sysfs_lookup(dir, child)` 用 `child->d_path` 跑一遍
`sysfs_path_type()`，存在就 `t113_vfs_bind_inode()`：`i_ino` 是整条路径的 32 位
FNV-1a 哈希，`i_size = 0`，目录配 `sysfs_dir_fops`，文件配 `sysfs_file_fops`。

**readdir。** `sysfs_readdir(inode, path, index, entry)` 现算第 `index` 项：

```text
/sys                         index 0 = devices，1 = bus
/sys/devices[/...]           先列 parent 等于当前设备的子设备（kset_for_each），
                             再列 4 个公共属性和 device->attributes[]
/sys/bus                     buses kset 里的第 index 个 bus
/sys/bus/<bus>               devices、drivers、name
/sys/bus/<bus>/devices       bus_for_each_dev() 的第 index 个设备
/sys/bus/<bus>/drivers       bus_for_each_drv() 的第 index 个驱动
/sys/bus/<bus>/devices/<d>   4 个公共属性 + 驱动属性
/sys/bus/<bus>/drivers/<d>   name、bound
```

**read。** `sysfs_read(file, buf, n)` 每次调用都按 `file->f_dentry->d_path` 重新生成
整个值（最多 256 字节），再从 `f_pos` 处拷贝。读到末尾返回 0，所以
`cat` 一类的循环读能正常结束。

```text
sysfs_read()
└── sysfs_generate(path)
    ├── /sys/devices/.../<attr>              show_device(device, attr)
    ├── /sys/bus/<bus>/name                  bus->name + "\n"
    ├── /sys/bus/<bus>/devices/<d>/<attr>    show_device()
    └── /sys/bus/<bus>/drivers/<d>/<attr>    show_driver()：name，或 bound 列表
show_device()
├── name / bus / driver                      字符串 + "\n"，没有时写 "(none)"
├── path                                     kobject_get_path() + "\n"
└── 其他                                     device->attributes[i].show(dev, buf, cap)
```

sysfs 没有 `write`，`t113_vfs_open()` 对 `O_RDWR` 直接拒绝，所以 `/sys` 是只读的。

### 1.5 驱动怎样加属性

`device.h` 新增：

```c
struct device_attribute {
    const char *name;
    int (*show)(struct device *dev, char *buffer, uint32_t capacity);
};

struct device {
    ...
    const struct device_attribute *attributes;   /* 驱动 probe 时设置 */
    uint32_t num_attributes;
};
```

驱动在 probe 成功前把静态数组挂到 `dev->attributes`。`show` 返回写入的字节数，
出错返回负数。driver core 在三处把它清零：`device_initialize()`、probe 失败的
`really_probe()`、解绑的 `device_release_driver_locked()`。属性的生命周期因此和
“设备绑定了这个驱动”一致，解绑后 `/sys` 里不会留下指向已释放驱动数据的文件。

### 1.6 引用和锁

- lookup 和 readdir 在 VFS 的 `vfs_lock` 里运行（由 `lookup_path()` 和
  `t113_vfs_readdir()` 调用）；`read` 不在这把锁里，`t113_vfs_read()` 调驱动前已经
  放开了它。
- 找到的 `device`、`bus_type`、`device_driver` 都先加 kobject 引用
  （`get_device`、`kset_find_obj`、`kobject_get`），用完马上放掉，不在 inode 里
  长期持有。所以设备删除后，下一次访问就会看到它不存在了。
- 遍历时持有的锁是 kset 的 spinlock 或 driver core 的 `core_lock`，回调里只拿
  kobject 自己的 `ref.lock`，没有同一把锁重入。
- 驱动的 `show` 由 `sysfs_read()` 调用，在 `vfs_lock` 之外。`readdir` 不调用
  `show`。`gpio_keys` 的属性只做单次 GPIO/计数器读取，不持有 VFS 全局锁。

### 1.7 与 Linux sysfs 的差别

| 方面 | Linux | miniOS |
| --- | --- | --- |
| 实现 | kernfs：每个 kobject、属性在注册时建 `kernfs_node` | 不建节点，按路径实时查 driver core |
| 设备属性 | `DEVICE_ATTR_RO()` + `sysfs_create_group()`，可读写 | `dev->attributes[]`，只读 |
| `driver`、`subsystem` | 符号链接 | `driver`、`bus` 是文本文件 |
| `/sys/bus/*/devices/*` | 指向 `/sys/devices/...` 的符号链接 | 同样内容的目录，`path` 属性写真实路径 |
| 驱动目录 | 每个设备一个符号链接，加 `bind`、`unbind`、`uevent` | `name` 和 `bound` 两个文本文件 |
| `/sys/class`、`/sys/module`、`uevent` | 有 | 没有 |
| inode 号 | kernfs 分配，唯一 | 路径的 32 位哈希 |

## 2. GPIO 按键驱动

按键数据从硬件到用户态只走一条链路：

```text
USER KEY（PB4，低电平有效）
  → PB4 EINT pending bit 4
  → GPIOB_NS（GIC IRQ 101）
  → IRQ 异常入口和通用 IRQ 分发表
  → gpio_keys_irq() 写入 input_event 环形队列
  → 唤醒阻塞读取 /dev/key0 的进程
  → keytest 打印 pressed/released
```

### 2.1 硬件和平台数据

USER KEY 接在 PB4，按下接地，平时靠内部上拉保持高电平。`board.c` 在
`CONFIG_INPUT_GPIO_KEYS=y` 时注册平台设备：

```c
static const struct resource user_key_resources[] = {
    DEFINE_RES_IRQ(T113_IRQ_GPIOB),             /* 101 = GIC SPI 69 */
};
static const struct gpio_keys_platform_data user_key_pdata = {
    .gpio = T113_GPIO(T113_PB, 4),              /* 1 * 32 + 4 = 36 */
    .irq = T113_IRQ_GPIOB,
    .code = MINIOS_KEY_ENTER,                   /* 28，与 Linux KEY_ENTER 相同 */
    .active_low = 1u,
    .pull = T113_PULL_UP,
    .debounce_ms = 20u,
};
static struct platform_device user_key_device = {
    .name = "user-key",
    .compatible = "gpio-keys",
    ...
};
```

`gpio_keys_driver` 用 `of_match_table = { "gpio-keys" }` 与它匹配，驱动名是
`gpio-keys`。

用到的 PIO 寄存器（`T113_PIO_BASE = 0x02000000`，每个 GPIO 端口 0x30 字节，
外部中断区从 0x200 开始，每个硬件端口号占 0x20 字节）。T113 没有实现普通 GPIO
端口 PA，但硬件仍保留 bank 0；PB 的硬件端口号是 1，所以 PB EINT 从
`0x200 + 1 * 0x20 = 0x220` 开始，不能把 PB 压缩成 bank 0。

| 寄存器 | 地址 | PB4 的位 | 写入值 |
| --- | --- | --- | --- |
| `PB_CFG0` | 0x02000030 | [19:16] | 0xE = `T113_GPIO_IRQ`（PB_EINT4） |
| `PB_DAT` | 0x02000040 | [4] | 读电平 |
| `PB_PULL0` | 0x02000054 | [9:8] | 1 = 上拉 |
| `PB_EINT_CFG0` | 0x02000220 | [19:16] | 4 = 双边沿 |
| `PB_EINT_CTL` | 0x02000230 | [4] | 1 = 使能 |
| `PB_EINT_STATUS` | 0x02000234 | [4] | 读 pending，写 1 清除 |
| `PB_EINT_DEB` | 0x02000238 | 整个端口 | 0x71（24 MHz、/128） |

这次实板调通暴露了两个互相独立的问题：最初把旧款 sunxi 常见的 EINT mux `6`
沿用到了 T113，但 T113/D1 应为 `0xE`；同时最初用 `(port - PB) * 0x20` 计算 EINT
bank，把 PB 错放进保留的 PA 槽 `0x200`。两处都修正后 PB4 才能真正置位 pending。

### 2.2 probe

```text
driver_register(gpio-keys) → platform 总线 match → really_probe()
└── gpio_keys_probe(pdev)
    ├── pdata = dev.platform_data；platform_get_irq(pdev, 0) 必须等于 pdata->irq
    ├── key0 = { head = tail = 0, last_irq_us = 0 }，初始化 spinlock 和等待队列
    ├── t113_gpio_set_pull(PB, 4, 上拉)
    ├── t113_gpio_direction_input(PB4)；读一次电平作为初始 value
    ├── t113_chrdev_register(13, 0, &gpio_keys_fops)       设备号 → 驱动 fops
    ├── t113_devfs_create_chrdev("key0", 13, 0)             /dev/key0 → 设备号
    ├── t113_request_irq(101, gpio_keys_irq, &key0)
    ├── t113_gpio_irq_config(PB4, BOTH)
    │   ├── 关 PB4 中断，写 EINT_CFG0，写 EINT_DEB = 0x71
    │   ├── PB_CFG0 切到 EINT 功能
    │   └── 清掉 pending
    ├── platform_set_drvdata(pdev, &key0)
    ├── dev.attributes = { value, keycode, irq_count, pending, mux }
    ├── t113_gpio_irq_enable(PB4)；t113_gic_enable_irq(101)
    └── "user-key: PB4 active-low key -> /dev/key0 (EINT mux=0x0e)"
```

major 13 沿用 Linux 输入子系统的主设备号（`INPUT_MAJOR`）。驱动状态是一个静态
`key0`，所以现在只支持一个按键。

### 2.3 中断路径

```text
PB4 电平变化
└── PB_EINT_STATUS[4] = 1 → GPIOB_NS → GIC SPI 69 → IRQ 101
    └── kernel_irq_entry 保存现场 → t113_irq_handler() → t113_irq_dispatch(101)
    └── gpio_keys_irq(irq, &key0)
        ├── PB_EINT_STATUS 第 4 位没置 → 返回（GPIOB 整组共用这一个中断）
        ├── 写 1 清 pending
        ├── now = t113_time_us()；读电平；active_low 取反得到 value
        ├── value 与上次相同，或距上次被接受的事件不到 20 ms → 丢弃
        ├── spin_lock_irqsave(&key0.lock)
        │   ├── last_irq_us = now；key0.value = value
        │   └── 队列没满：events[head] = { now/1000, EV_KEY, 28, value }，head++
        ├── spin_unlock_irqrestore
        └── wake_up_all(&key0.wait)
```

事件队列是 16 项的环形缓冲区，`head == tail` 为空，`head + 1 == tail` 为满，满了
新事件直接丢掉（实际能存 15 个）。

### 2.4 阻塞读

```text
read(fd, &ev, sizeof ev)                    keytest
└── sys_read → t113_vfs_read(file)
    └── file->f_op->read = gpio_keys_read  （chrdev_open 已把 f_op 换成驱动 fops）
        ├── count < 12 → -1
        └── 循环：
            ├── spin_lock_irqsave(&key0.wait.lock)；spin_lock(&key0.lock)
            ├── 队列非空 → 取出一个事件，解锁，拷给用户，返回 12
            └── 队列空   → 解开 key0.lock，wait_queue_sleep_locked()
                           （入等待队列、解开 wait.lock、t113_sched_yield()）
```

先拿等待队列的锁、关着中断检查队列，再入队睡眠，所以“检查为空”和“开始睡眠”
之间中断插不进来，不会丢唤醒。字符设备不走 `f_pos_lock`，所以一个进程阻塞在
`/dev/key0` 上不会挡住别的 fd。一次 `read` 只返回一个事件。

事件结构（内核 `struct minios_input_event` 与用户态 `struct input_event` 布局相同，
12 字节）：

```c
struct input_event {
    uint32_t time_ms;     /* t113_time_us() / 1000 */
    uint16_t type;        /* EV_KEY = 1 */
    uint16_t code;        /* KEY_ENTER = 28 */
    int32_t value;        /* 1 按下，0 松开 */
};
```

### 2.5 sysfs 属性

| 文件 | `show` | 内容 |
| --- | --- | --- |
| `/sys/devices/platform/user-key/value` | `gpio_keys_show_value()` | 直接读取 PB4 后按 active-low 转换：0 松开、1 按下 |
| `/sys/devices/platform/user-key/keycode` | `gpio_keys_show_keycode()` | 28 |
| `/sys/devices/platform/user-key/irq_count` | `gpio_keys_show_irq_count()` | 已进入 PB4 handler 的原始中断次数 |
| `/sys/devices/platform/user-key/pending` | `gpio_keys_show_pending()` | PB_EINT_STATUS[4] 当前值，handler 通常已很快清零 |
| `/sys/devices/platform/user-key/mux` | `gpio_keys_show_mux()` | PB4 当前 mux，正常为十进制 14（0xE） |

同样的五个文件也出现在 `/sys/bus/platform/devices/user-key/` 下。

```text
/sys/devices/platform/user-key   看设备、总线、绑定的驱动和当前状态
/dev/key0                        阻塞读按键事件
```

### 2.6 用户态

下面的输出是示例，时间值随实际按键变化：

```sh
$ keytest
keytest: press the USER key beside RESET
key code=28 pressed time=14811 ms
key code=28 released time=14994 ms
$ cat /sys/devices/platform/user-key/value
0
$ cat /sys/devices/platform/user-key/mux
14
$ cat /sys/devices/platform/user-key/irq_count
2
$ cat /sys/bus/platform/drivers/gpio-keys/bound
user-key
```

### 2.7 与 Linux gpio-keys 的差别

| 方面 | Linux | miniOS |
| --- | --- | --- |
| 设备描述 | 设备树 `gpio-keys` 节点，每个子节点一个键 | `board.c` 里的平台数据，只有一个键 |
| 设备文件 | 输入子系统分配 `/dev/input/eventN`（major 13） | 固定 `/dev/key0`（13:0） |
| 事件 | `struct input_event { timeval, type, code, value }`，每次变化后跟 `EV_SYN` | 12 字节，毫秒时间，没有 `EV_SYN` |
| 消抖 | `gpiod_set_debounce()`，否则延迟工作队列在消抖时间后重新采样 | 在中断里比较时间戳，窗口内的边沿直接丢 |
| 读 | 一次可读多个事件，支持 `O_NONBLOCK`、`poll` | 一次一个，只能阻塞 |
| GPIO IRQ 分发 | GPIO irqchip 将 bank 父 IRQ 解复用为每个 pin 的虚拟 IRQ | gpio-keys 直接占用 GPIOB 的父 IRQ 101 |

## 3. 测试和发现的问题

`make t113` 在 `-Wall -Wextra` 下没有警告。另外把 `vfs.c`、`sysfs.c`、
`kobject.c`、`device.c`、`platform_bus.c`、`gpio_keys.c` 用主机 gcc（ASan/UBSan）
编在一起，GPIO、IRQ、时钟用桩函数代替，按板子的顺序注册设备和驱动后：

- 递归 `readdir` + `read` 整个 `/sys`，得到 1.2 节的树，每个属性都能读；
- `/sys/nope`、`/sys/devices/platform/uart3/value` 打不开，`O_RDWR` 打开属性被拒；
- 结束时 VFS 只剩开机时的 3 个 dentry，没有遗留的 file；
- 模拟按键：拉低 PB4 并触发中断后 `value` 从 0 变成 1。
- 100ASK T113-S3 实板：PB4 按下和释放分别得到 code 28、value 1/0，时间戳正常。

发现的问题：

1. **消抖会丢掉最后一个边沿，按键可能卡在“按下”。** 中断里只要距上次被接受的
   事件不到 20 ms 就丢弃，之后没有任何东西再采样一次电平。测试中按下后 5 ms
   松开，松开的中断被丢掉，`/dev/key0` 也收不到松开事件，直到下一次按键。sysfs
   的 `value` 现在直接读 PB4，因此仍能显示真实电平。Linux gpio-keys 的做法是在
   中断里只启动一个消抖定时器，定时器到期时再读电平上报。
2. **GPIOB 父 IRQ 目前只能被一个驱动占用。** `t113_request_irq()` 的一个 IRQ 槽只
   保存一个 handler，而 PB0～PB31 共用 IRQ 101。以后增加其他 PB 中断设备时，
   应增加 GPIO irqchip/bank handler，由它读取 STATUS 并分发每个 pin 的虚拟 IRQ。
3. **硬件消抖很短。** `PB_EINT_DEB = 0x71` 表示 24 MHz HOSC、/128，采样周期约
   5.3 微秒；主要消抖仍由驱动的 20 ms 软件窗口完成。
4. probe 中途失败时，已经注册的字符设备号、devfs 名字和 IRQ 都没有撤销（现在
   也没有注销接口），重试 probe 会因为重复注册失败。
5. sysfs 的 inode 号是路径哈希。两条不同路径哈希相同时，VFS 的 inode 缓存会把
   第二条当成第一条，类型和 fops 可能用错。现在的路径只有几十条，碰撞概率很低。
