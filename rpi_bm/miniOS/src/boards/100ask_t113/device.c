#include "device.h"
#include "driver_model.h"
#include "platform.h"

/*
 * One coarse lock for the whole driver core. It is taken with IRQs off so a
 * timer tick can never preempt a half-done bind on the uniprocessor T113
 * kernel; probe/remove run under it and must stay short and non-sleeping.
 */
static spinlock_t core_lock = SPINLOCK_INIT;

static void device_ktype_release(struct kobject *kobj)
{
    struct device *dev = to_dev(kobj);
    if (dev->release)
        dev->release(dev);
}

static const struct kobj_type bus_ktype = { .release = 0 };
static const struct kobj_type dir_ktype = { .release = 0 };
static const struct kobj_type device_ktype = {
    .release = device_ktype_release,
};
static const struct kobj_type driver_ktype = { .release = 0 };

static int names_match(const char *a, const char *b)
{
    if (!a || !b)
        return 0;
    while (*a && *a == *b) {
        ++a;
        ++b;
    }
    return *a == *b;
}

int dev_str_eq(const char *a, const char *b)
{
    return names_match(a, b);
}

const struct of_device_id *of_match_compatible(const struct of_device_id *table,
                                               const char *compatible)
{
    if (!table || !compatible)
        return 0;
    for (; table->compatible; ++table)
        if (names_match(table->compatible, compatible))
            return table;
    return 0;
}

/* ---------------------------------------------------------------- binding */

static int driver_match_device(struct device_driver *drv, struct device *dev)
{
    struct bus_type *bus = drv->bus;
    return bus->match ? bus->match(dev, drv)
                      : names_match(dev->name, drv->name);
}

static int really_probe(struct device *dev, struct device_driver *drv)
{
    int ret = 0;

    dev->driver = drv;
    if (dev->bus->probe)
        ret = dev->bus->probe(dev);
    else if (drv->probe)
        ret = drv->probe(dev);
    if (ret < 0) {
        dev->driver = 0;
        dev->driver_data = 0;
        t113_uart_puts("driver core: probe of ");
        t113_uart_puts(dev_name(dev));
        t113_uart_puts(" by ");
        t113_uart_puts(drv->name);
        t113_uart_puts(" failed ");
        t113_uart_puthex((uint32_t)-ret);
        t113_uart_putc('\n');
        return ret;
    }
    list_add_tail(&dev->driver_node, &drv->devices);
    return 1;
}

/* First matching driver whose probe succeeds wins. */
static int device_attach_locked(struct device *dev)
{
    struct list_head *node;

    if (dev->driver)
        return 1;
    if (!dev->bus)
        return 0;
    list_for_each(node, &dev->bus->drivers) {
        struct device_driver *drv =
            list_entry(node, struct device_driver, bus_node);
        if (!driver_match_device(drv, dev))
            continue;
        if (really_probe(dev, drv) > 0)
            return 1;
    }
    return 0;
}

static void driver_attach_locked(struct device_driver *drv)
{
    struct list_head *node;

    list_for_each(node, &drv->bus->devices) {
        struct device *dev = list_entry(node, struct device, bus_node);
        if (dev->driver || !driver_match_device(drv, dev))
            continue;
        really_probe(dev, drv);
    }
}

static void device_release_driver_locked(struct device *dev)
{
    struct device_driver *drv = dev->driver;

    if (!drv)
        return;
    if (dev->bus && dev->bus->remove)
        dev->bus->remove(dev);
    else if (drv->remove)
        drv->remove(dev);
    list_del_init(&dev->driver_node);
    dev->driver = 0;
    dev->driver_data = 0;
}

/* -------------------------------------------------------------------- bus */

int bus_register(struct bus_type *bus)
{
    if (!bus || !bus->name)
        return -EINVAL;

    kobject_init(&bus->kobj, &bus_ktype);
    kobject_init(&bus->devices_dir, &dir_ktype);
    kobject_init(&bus->drivers_dir, &dir_ktype);
    INIT_LIST_HEAD(&bus->devices);
    INIT_LIST_HEAD(&bus->drivers);

    if (kobject_add(&bus->kobj, t113_buses_kset(), 0, bus->name) < 0)
        return -EEXIST;
    if (kobject_add(&bus->devices_dir, 0, &bus->kobj, "devices") < 0 ||
        kobject_add(&bus->drivers_dir, 0, &bus->kobj, "drivers") < 0) {
        kobject_put(&bus->devices_dir);
        kobject_put(&bus->kobj);
        return -EINVAL;
    }
    return 0;
}

void bus_unregister(struct bus_type *bus)
{
    if (!bus)
        return;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    int busy = !list_empty(&bus->devices) || !list_empty(&bus->drivers);
    spin_unlock_irqrestore(&core_lock, flags);
    if (busy) {
        t113_uart_puts("driver core: bus_unregister on busy bus ");
        t113_uart_puts(bus->name);
        t113_uart_putc('\n');
        return;
    }
    kobject_put(&bus->drivers_dir);
    kobject_put(&bus->devices_dir);
    kobject_put(&bus->kobj);
}

int bus_for_each_dev(struct bus_type *bus,
                     int (*fn)(struct device *dev, void *data), void *data)
{
    struct list_head *node;
    int ret = 0;

    if (!bus || !fn)
        return -EINVAL;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    list_for_each(node, &bus->devices) {
        ret = fn(list_entry(node, struct device, bus_node), data);
        if (ret)
            break;
    }
    spin_unlock_irqrestore(&core_lock, flags);
    return ret;
}

int bus_for_each_drv(struct bus_type *bus,
                     int (*fn)(struct device_driver *drv, void *data),
                     void *data)
{
    struct list_head *node;
    int ret = 0;

    if (!bus || !fn)
        return -EINVAL;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    list_for_each(node, &bus->drivers) {
        ret = fn(list_entry(node, struct device_driver, bus_node), data);
        if (ret)
            break;
    }
    spin_unlock_irqrestore(&core_lock, flags);
    return ret;
}

struct device *bus_find_device_by_name(struct bus_type *bus,
                                       const char *name)
{
    struct list_head *node;
    struct device *found = 0;

    if (!bus || !name)
        return 0;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    list_for_each(node, &bus->devices) {
        struct device *dev = list_entry(node, struct device, bus_node);
        if (names_match(dev_name(dev), name)) {
            found = get_device(dev);
            break;
        }
    }
    spin_unlock_irqrestore(&core_lock, flags);
    return found;
}

int driver_for_each_device(struct device_driver *drv,
                           int (*fn)(struct device *dev, void *data),
                           void *data)
{
    struct list_head *node;
    int ret = 0;

    if (!drv || !fn)
        return -EINVAL;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    list_for_each(node, &drv->devices) {
        ret = fn(list_entry(node, struct device, driver_node), data);
        if (ret)
            break;
    }
    spin_unlock_irqrestore(&core_lock, flags);
    return ret;
}

/* ----------------------------------------------------------------- device */

void device_initialize(struct device *dev)
{
    kobject_init(&dev->kobj, &device_ktype);
    INIT_LIST_HEAD(&dev->bus_node);
    INIT_LIST_HEAD(&dev->driver_node);
    dev->driver = 0;
    dev->driver_data = 0;
}

struct device *get_device(struct device *dev)
{
    return dev && kobject_get(&dev->kobj) ? dev : 0;
}

void put_device(struct device *dev)
{
    if (dev)
        kobject_put(&dev->kobj);
}

int device_add(struct device *dev)
{
    if (!dev || !dev->name)
        return -EINVAL;

    uint32_t flags = spin_lock_irqsave(&core_lock);
    struct kobject *parent = dev->parent ? &dev->parent->kobj : 0;
    if (kobject_add(&dev->kobj, t113_devices_kset(), parent, dev->name) < 0) {
        spin_unlock_irqrestore(&core_lock, flags);
        return -EEXIST;
    }
    if (dev->bus) {
        list_add_tail(&dev->bus_node, &dev->bus->devices);
        device_attach_locked(dev);
    }
    spin_unlock_irqrestore(&core_lock, flags);
    return 0;
}

int device_register(struct device *dev)
{
    if (!dev)
        return -EINVAL;
    device_initialize(dev);
    int ret = device_add(dev);
    if (ret < 0)
        put_device(dev);
    return ret;
}

void device_del(struct device *dev)
{
    if (!dev)
        return;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    device_release_driver_locked(dev);
    if (dev->bus)
        list_del_init(&dev->bus_node);
    spin_unlock_irqrestore(&core_lock, flags);
    kobject_del(&dev->kobj);
}

void device_unregister(struct device *dev)
{
    device_del(dev);
    put_device(dev);
}

int device_attach(struct device *dev)
{
    if (!dev || !dev->bus)
        return -EINVAL;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    int ret = device_attach_locked(dev);
    spin_unlock_irqrestore(&core_lock, flags);
    return ret;
}

void device_release_driver(struct device *dev)
{
    if (!dev)
        return;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    device_release_driver_locked(dev);
    spin_unlock_irqrestore(&core_lock, flags);
}

/* ----------------------------------------------------------------- driver */

int driver_register(struct device_driver *drv)
{
    if (!drv || !drv->name || !drv->bus)
        return -EINVAL;

    kobject_init(&drv->kobj, &driver_ktype);
    INIT_LIST_HEAD(&drv->bus_node);
    INIT_LIST_HEAD(&drv->devices);

    uint32_t flags = spin_lock_irqsave(&core_lock);
    if (kobject_add(&drv->kobj, t113_drivers_kset(),
                    &drv->bus->drivers_dir, drv->name) < 0) {
        spin_unlock_irqrestore(&core_lock, flags);
        return -EEXIST;
    }
    list_add_tail(&drv->bus_node, &drv->bus->drivers);
    driver_attach_locked(drv);
    spin_unlock_irqrestore(&core_lock, flags);
    return 0;
}

void driver_unregister(struct device_driver *drv)
{
    struct list_head *node, *next;

    if (!drv)
        return;
    uint32_t flags = spin_lock_irqsave(&core_lock);
    list_for_each_safe(node, next, &drv->devices)
        device_release_driver_locked(
            list_entry(node, struct device, driver_node));
    list_del_init(&drv->bus_node);
    spin_unlock_irqrestore(&core_lock, flags);
    kobject_put(&drv->kobj);
}
