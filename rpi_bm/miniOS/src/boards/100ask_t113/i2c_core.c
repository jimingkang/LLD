#include "platform.h"
#include "i2c.h"

static spinlock_t adapters_lock = SPINLOCK_INIT;
static struct i2c_adapter *adapters[I2C_MAX_ADAPTERS];

/* --------------------------------------------------------------- adapters */

int i2c_add_numbered_adapter(struct i2c_adapter *adap)
{
    if (!adap || !adap->algo || !adap->algo->master_xfer ||
        adap->nr < 0 || adap->nr >= I2C_MAX_ADAPTERS)
        return -EINVAL;
    uint32_t flags = spin_lock_irqsave(&adapters_lock);
    int ret = adapters[adap->nr] ? -EBUSY : 0;
    if (!ret)
        adapters[adap->nr] = adap;
    spin_unlock_irqrestore(&adapters_lock, flags);
    return ret;
}

void i2c_del_adapter(struct i2c_adapter *adap)
{
    if (!adap || adap->nr < 0 || adap->nr >= I2C_MAX_ADAPTERS)
        return;
    uint32_t flags = spin_lock_irqsave(&adapters_lock);
    if (adapters[adap->nr] == adap)
        adapters[adap->nr] = 0;
    spin_unlock_irqrestore(&adapters_lock, flags);
}

struct i2c_adapter *i2c_get_adapter(int nr)
{
    if (nr < 0 || nr >= I2C_MAX_ADAPTERS)
        return 0;
    uint32_t flags = spin_lock_irqsave(&adapters_lock);
    struct i2c_adapter *adap = adapters[nr];
    spin_unlock_irqrestore(&adapters_lock, flags);
    return adap;
}

int i2c_transfer(struct i2c_adapter *adap, struct i2c_msg *msgs, int num)
{
    if (!adap || !msgs || num <= 0)
        return -EINVAL;
    return adap->algo->master_xfer(adap, msgs, num);
}

int i2c_probe_address(struct i2c_adapter *adap, uint16_t addr)
{
    struct i2c_msg msg = { .addr = addr, .flags = 0, .len = 0, .buf = 0 };
    int ret = i2c_transfer(adap, &msg, 1);
    return ret == 1 ? 0 : (ret < 0 ? ret : -EIO);
}

int i2c_scan(struct i2c_adapter *adap)
{
    int found = 0;
    if (!adap)
        return -EINVAL;
    t113_uart_puts(adap->name);
    t113_uart_puts(": scan 0x08-0x77:");
    for (uint16_t addr = 0x08; addr <= 0x77; ++addr) {
        if (i2c_probe_address(adap, addr) == 0) {
            t113_uart_putc(' ');
            t113_uart_puthex(addr);
            ++found;
        }
    }
    t113_uart_puts(found ? "\n" : " no device answered\n");
    return found;
}

void i2c_dump_adapter(struct i2c_adapter *adap)
{
    if (adap && adap->algo && adap->algo->dump)
        adap->algo->dump(adap);
}

/* -------------------------------------------------------------------- bus */

static const struct i2c_device_id *
i2c_match_id(const struct i2c_device_id *id, const struct i2c_client *client)
{
    if (!id)
        return 0;
    for (; id->name; ++id)
        if (dev_str_eq(id->name, client->name))
            return id;
    return 0;
}

/* compatible, then id_table, then driver name — same order as platform. */
static int i2c_device_match(struct device *dev, struct device_driver *drv)
{
    struct i2c_client *client = to_i2c_client(dev);
    struct i2c_driver *idrv = to_i2c_driver(drv);

    if (of_match_compatible(idrv->of_match_table, client->compatible))
        return 1;
    if (idrv->id_table)
        return i2c_match_id(idrv->id_table, client) != 0;
    return dev_str_eq(client->name, drv->name);
}

/*
 * Bus-level probe: besides the type conversion, this is where the I2C core
 * resolves the client's adapter. A chip driver's probe can therefore always
 * use client->adapter; if the controller has not probed yet the bind fails
 * with -ENODEV and can be retried later with device_attach().
 */
static int i2c_device_probe(struct device *dev)
{
    struct i2c_client *client = to_i2c_client(dev);
    struct i2c_driver *idrv = to_i2c_driver(dev->driver);

    client->adapter = i2c_get_adapter(client->adapter_nr);
    if (!client->adapter) {
        t113_uart_puts(dev_name(dev));
        t113_uart_puts(": i2c adapter not registered yet\n");
        return -ENODEV;
    }
    client->of_match = of_match_compatible(idrv->of_match_table,
                                           client->compatible);
    client->id_entry = i2c_match_id(idrv->id_table, client);

    int ret = idrv->probe ? idrv->probe(client) : 0;
    if (ret < 0) {
        client->adapter = 0;
        client->of_match = 0;
        client->id_entry = 0;
    }
    return ret;
}

static void i2c_device_remove(struct device *dev)
{
    struct i2c_client *client = to_i2c_client(dev);
    struct i2c_driver *idrv = to_i2c_driver(dev->driver);

    if (idrv->remove)
        idrv->remove(client);
    client->adapter = 0;
    client->of_match = 0;
    client->id_entry = 0;
}

struct bus_type i2c_bus_type = {
    .name = "i2c",
    .match = i2c_device_match,
    .probe = i2c_device_probe,
    .remove = i2c_device_remove,
};

int i2c_bus_init(void)
{
    return bus_register(&i2c_bus_type);
}

static void format_client_name(struct i2c_client *client)
{
    static const char hex[] = "0123456789abcdef";
    char *p = client->dev_name;
    *p++ = (char)('0' + client->adapter_nr % 10u);
    *p++ = '-';
    for (int shift = 12; shift >= 0; shift -= 4)
        *p++ = hex[(client->addr >> shift) & 0xfu];
    *p = '\0';
}

int i2c_new_client_device(struct i2c_client *client, struct device *parent)
{
    if (!client || !client->name || client->addr > 0x7fu ||
        client->adapter_nr >= I2C_MAX_ADAPTERS)
        return -EINVAL;
    format_client_name(client);
    client->dev.name = client->dev_name;
    client->dev.parent = parent;
    client->dev.bus = &i2c_bus_type;
    client->dev.platform_data = client->platform_data;
    client->adapter = 0;
    client->of_match = 0;
    client->id_entry = 0;
    return device_register(&client->dev);
}

void i2c_unregister_device(struct i2c_client *client)
{
    if (client)
        device_unregister(&client->dev);
}

int i2c_driver_register(struct i2c_driver *drv)
{
    if (!drv || !drv->driver.name)
        return -EINVAL;
    drv->driver.bus = &i2c_bus_type;
    return driver_register(&drv->driver);
}

void i2c_driver_unregister(struct i2c_driver *drv)
{
    if (drv)
        driver_unregister(&drv->driver);
}
