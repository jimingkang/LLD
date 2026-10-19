#include "platform.h"
#include "driver_model.h"
#include "device.h"
#include "platform_device.h"
#include "board.h"
#include "i2c.h"
#include "mmc.h"

static struct kset devices;
static struct kset drivers;
static struct kset buses;

static const struct kobj_type static_ktype = {
    .release = 0,
};

struct kset *t113_devices_kset(void) { return &devices; }
struct kset *t113_drivers_kset(void) { return &drivers; }
struct kset *t113_buses_kset(void) { return &buses; }

static void panic(const char *what)
{
    t113_uart_puts("PANIC: driver core: ");
    t113_uart_puts(what);
    t113_uart_putc('\n');
    for (;;)
        __asm__ volatile("wfi");
}

void t113_driver_core_init(void)
{
    kset_init(&devices, &static_ktype);
    kset_init(&drivers, &static_ktype);
    kset_init(&buses, &static_ktype);
    if (kset_register(&devices, 0, "devices") < 0 ||
        kset_register(&buses, 0, "bus") < 0 ||
        kset_register(&drivers, 0, "drivers") < 0)
        panic("cannot create top-level ksets");

    if (platform_bus_init() < 0)
        panic("cannot register platform bus");
    if (i2c_bus_init() < 0)
        panic("cannot register i2c bus");
    if (sdio_bus_init() < 0)
        panic("cannot register sdio bus");

    /* Devices first, then drivers: binding happens in driver_register(). */
    t113_board_register_devices();
    t113_board_register_drivers();

    /* Card enumeration registers devices: must run outside any probe. */
    mmc_rescan_all();

    t113_driver_core_dump();
}

/* -------------------------------------------------------------- dumping */

static void put_path(const struct kobject *kobj)
{
    char path[96];
    if (kobject_get_path(kobj, path, sizeof(path)) < 0)
        t113_uart_puts(kobject_name(kobj));
    else
        t113_uart_puts(path);
}

static int dump_device(struct kobject *kobj, void *unused)
{
    (void)unused;
    struct device *dev = to_dev(kobj);
    t113_uart_puts("  ");
    put_path(kobj);
    if (dev->bus) {
        t113_uart_puts("  bus=");
        t113_uart_puts(dev->bus->name);
        t113_uart_puts(" driver=");
        t113_uart_puts(dev->driver ? dev->driver->name : "(none)");
    }
    t113_uart_putc('\n');
    return 0;
}

static int dump_bus_device(struct device *dev, void *unused)
{
    (void)unused;
    t113_uart_puts("    ");
    put_path(&dev->bus->devices_dir);
    t113_uart_putc('/');
    t113_uart_puts(dev_name(dev));
    t113_uart_puts(" -> ");
    put_path(&dev->kobj);
    t113_uart_putc('\n');
    return 0;
}

/* Runs under the driver-core lock (bus_for_each_drv), so walk directly. */
static int dump_bus_driver(struct device_driver *drv, void *unused)
{
    (void)unused;
    struct list_head *node;
    t113_uart_puts("    ");
    put_path(&drv->kobj);
    t113_uart_puts("  bound:");
    if (list_empty(&drv->devices))
        t113_uart_puts(" (none)");
    list_for_each(node, &drv->devices) {
        t113_uart_putc(' ');
        t113_uart_puts(dev_name(list_entry(node, struct device, driver_node)));
    }
    t113_uart_putc('\n');
    return 0;
}

static int dump_bus(struct kobject *kobj, void *unused)
{
    (void)unused;
    struct bus_type *bus = container_of(kobj, struct bus_type, kobj);
    t113_uart_puts("  ");
    put_path(kobj);
    t113_uart_putc('\n');
    bus_for_each_dev(bus, dump_bus_device, 0);
    bus_for_each_drv(bus, dump_bus_driver, 0);
    return 0;
}

void t113_driver_core_dump(void)
{
    t113_uart_puts("driver core: ");
    put_path(&devices.kobj);
    t113_uart_putc('\n');
    kset_for_each(&devices, dump_device, 0);
    t113_uart_puts("driver core: ");
    put_path(&buses.kobj);
    t113_uart_putc('\n');
    kset_for_each(&buses, dump_bus, 0);
}
