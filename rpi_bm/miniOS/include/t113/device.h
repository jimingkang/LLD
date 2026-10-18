#ifndef MINIOS_T113_DEVICE_H
#define MINIOS_T113_DEVICE_H

#include "kobject.h"

/*
 * Lightweight Linux-style driver model.
 *
 * Virtual tree (no sysfs, just kobject parents):
 *   /devices/<parent...>/<dev>          dev->kobj    in kset "devices"
 *   /bus/<bus>                          bus->kobj    in kset "bus"
 *   /bus/<bus>/devices                  bus->devices_dir   (dir, list in bus)
 *   /bus/<bus>/drivers/<drv>            drv->kobj    in kset "drivers"
 *
 * Locking: every register/unregister/bind/unbind is serialized by one
 * driver-core lock that is also held across ->probe()/->remove(). Probe and
 * remove therefore must not sleep and must not call back into the
 * register/unregister API.
 */

#define ENODEV  19
#define EINVAL  22
#define EBUSY   16
#define EEXIST  17

struct device;
struct device_driver;

struct bus_type {
    const char *name;
    int (*match)(struct device *dev, struct device_driver *drv);
    /* Optional bus-level wrappers; default is drv->probe / drv->remove. */
    int (*probe)(struct device *dev);
    void (*remove)(struct device *dev);

    /* private */
    struct kobject kobj;
    struct kobject devices_dir;
    struct kobject drivers_dir;
    struct list_head devices;       /* dev->bus_node */
    struct list_head drivers;       /* drv->bus_node */
};

struct device {
    const char *name;
    struct device *parent;
    struct bus_type *bus;
    void *platform_data;
    void (*release)(struct device *dev);

    /* private */
    struct kobject kobj;
    struct device_driver *driver;
    void *driver_data;
    struct list_head bus_node;      /* in bus->devices */
    struct list_head driver_node;   /* in driver->devices once bound */
};

struct device_driver {
    const char *name;
    struct bus_type *bus;
    int (*probe)(struct device *dev);
    void (*remove)(struct device *dev);

    /* private */
    struct kobject kobj;
    struct list_head bus_node;      /* in bus->drivers */
    struct list_head devices;       /* bound devices (dev->driver_node) */
};

#define to_dev(k) container_of(k, struct device, kobj)
#define to_drv(k) container_of(k, struct device_driver, kobj)

static inline const char *dev_name(const struct device *dev)
{
    return dev->kobj.name ? dev->kobj.name : dev->name;
}

int bus_register(struct bus_type *bus);
void bus_unregister(struct bus_type *bus);
int bus_for_each_dev(struct bus_type *bus,
                     int (*fn)(struct device *dev, void *data), void *data);
int bus_for_each_drv(struct bus_type *bus,
                     int (*fn)(struct device_driver *drv, void *data),
                     void *data);
/* Returns a referenced device (put_device() it) or 0. */
struct device *bus_find_device_by_name(struct bus_type *bus,
                                       const char *name);
int driver_for_each_device(struct device_driver *drv,
                           int (*fn)(struct device *dev, void *data),
                           void *data);

void device_initialize(struct device *dev);
int device_add(struct device *dev);
void device_del(struct device *dev);
int device_register(struct device *dev);
void device_unregister(struct device *dev);
struct device *get_device(struct device *dev);
void put_device(struct device *dev);
/* Try to bind an unbound device again (e.g. after a probe failure). */
int device_attach(struct device *dev);
void device_release_driver(struct device *dev);

int driver_register(struct device_driver *drv);
void driver_unregister(struct device_driver *drv);

static inline void dev_set_drvdata(struct device *dev, void *data)
{
    dev->driver_data = data;
}

static inline void *dev_get_drvdata(const struct device *dev)
{
    return dev->driver_data;
}

#endif
