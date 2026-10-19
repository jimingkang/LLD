#ifndef MINIOS_T113_I2C_H
#define MINIOS_T113_I2C_H

#include "device.h"

/*
 * Lightweight I2C core, Linux-shaped:
 *   i2c_adapter : a bus master (registered by a controller driver's probe)
 *   i2c_client  : a chip at an address on adapter N (a struct device on the
 *                 "i2c" bus, normally declared by the board file)
 *   i2c_driver  : chip driver, matched by compatible / id_table / name
 *
 * Adapters are kept in a small numbered table rather than being devices
 * themselves, so a controller probe can register one without re-entering
 * the driver core (see the locking note in device.h).
 */

#define I2C_M_RD        0x0001u

struct i2c_msg {
    uint16_t addr;              /* 7-bit address */
    uint16_t flags;             /* I2C_M_RD for a read */
    uint16_t len;
    uint8_t *buf;
};

struct i2c_adapter;

struct i2c_algorithm {
    /* Returns number of messages transferred, or a negative error. */
    int (*master_xfer)(struct i2c_adapter *adap, struct i2c_msg *msgs,
                       int num);
    /* Optional: print controller state for bring-up debugging. */
    void (*dump)(struct i2c_adapter *adap);
};

#define I2C_MAX_ADAPTERS 4

struct i2c_adapter {
    int nr;
    const char *name;
    const struct i2c_algorithm *algo;
    void *algo_data;
    struct device *dev;         /* controller device (e.g. platform twi2) */
};

int i2c_add_numbered_adapter(struct i2c_adapter *adap);
void i2c_del_adapter(struct i2c_adapter *adap);
struct i2c_adapter *i2c_get_adapter(int nr);
int i2c_transfer(struct i2c_adapter *adap, struct i2c_msg *msgs, int num);
/* 0 if a chip ACKs `addr` (zero-length write), negative otherwise. */
int i2c_probe_address(struct i2c_adapter *adap, uint16_t addr);
/* Print every 7-bit address in 0x08..0x77 that ACKs; returns the count. */
int i2c_scan(struct i2c_adapter *adap);
void i2c_dump_adapter(struct i2c_adapter *adap);

struct i2c_device_id {
    const char *name;
    uint32_t driver_data;
};

struct i2c_client {
    const char *name;           /* chip name, e.g. "ov5640" */
    const char *compatible;     /* e.g. "ovti,ov5640" */
    uint16_t addr;              /* 7-bit */
    uint8_t adapter_nr;
    void *platform_data;
    struct device dev;

    /* set by the core */
    char dev_name[12];          /* "<bus>-<addr>", e.g. "2-003c" */
    struct i2c_adapter *adapter;            /* valid while bound */
    const struct of_device_id *of_match;
    const struct i2c_device_id *id_entry;
};

struct i2c_driver {
    int (*probe)(struct i2c_client *client);
    void (*remove)(struct i2c_client *client);
    struct device_driver driver;
    const struct of_device_id *of_match_table;
    const struct i2c_device_id *id_table;
};

#define to_i2c_client(d) container_of(d, struct i2c_client, dev)
#define to_i2c_driver(d) container_of(d, struct i2c_driver, driver)

extern struct bus_type i2c_bus_type;

int i2c_bus_init(void);
/* parent: the controller's struct device (gives /devices/.../twi2/2-003c). */
int i2c_new_client_device(struct i2c_client *client, struct device *parent);
void i2c_unregister_device(struct i2c_client *client);
int i2c_driver_register(struct i2c_driver *drv);
void i2c_driver_unregister(struct i2c_driver *drv);

static inline void i2c_set_clientdata(struct i2c_client *c, void *data)
{
    dev_set_drvdata(&c->dev, data);
}

static inline void *i2c_get_clientdata(const struct i2c_client *c)
{
    return dev_get_drvdata(&c->dev);
}

#endif
