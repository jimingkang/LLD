#include "platform.h"
#include "platform_device.h"

static int str_eq(const char *a, const char *b)
{
    if (!a || !b)
        return 0;
    while (*a && *a == *b) {
        ++a;
        ++b;
    }
    return *a == *b;
}

static const struct of_device_id *
platform_match_of(const struct of_device_id *table,
                  const struct platform_device *pdev)
{
    if (!table || !pdev->compatible)
        return 0;
    for (; table->compatible; ++table)
        if (str_eq(table->compatible, pdev->compatible))
            return table;
    return 0;
}

static const struct platform_device_id *
platform_match_id(const struct platform_device_id *id,
                  const struct platform_device *pdev)
{
    if (!id)
        return 0;
    for (; id->name; ++id)
        if (str_eq(id->name, pdev->name))
            return id;
    return 0;
}

/* Same priority as Linux: compatible string, then id_table, then name. */
static int platform_match(struct device *dev, struct device_driver *drv)
{
    struct platform_device *pdev = to_platform_device(dev);
    struct platform_driver *pdrv = to_platform_driver(drv);

    if (platform_match_of(pdrv->of_match_table, pdev))
        return 1;
    if (pdrv->id_table)
        return platform_match_id(pdrv->id_table, pdev) != 0;
    return str_eq(pdev->name, drv->name);
}

static int platform_probe(struct device *dev)
{
    struct platform_device *pdev = to_platform_device(dev);
    struct platform_driver *pdrv = to_platform_driver(dev->driver);

    pdev->of_match = platform_match_of(pdrv->of_match_table, pdev);
    pdev->id_entry = platform_match_id(pdrv->id_table, pdev);
    int ret = pdrv->probe ? pdrv->probe(pdev) : 0;
    if (ret < 0) {
        pdev->of_match = 0;
        pdev->id_entry = 0;
    }
    return ret;
}

static void platform_remove(struct device *dev)
{
    struct platform_device *pdev = to_platform_device(dev);
    struct platform_driver *pdrv = to_platform_driver(dev->driver);

    if (pdrv->remove)
        pdrv->remove(pdev);
    pdev->of_match = 0;
    pdev->id_entry = 0;
}

struct bus_type platform_bus_type = {
    .name = "platform",
    .match = platform_match,
    .probe = platform_probe,
    .remove = platform_remove,
};

/* Root of all platform devices: /devices/platform (not on any bus). */
struct device platform_bus = {
    .name = "platform",
};

int platform_bus_init(void)
{
    int ret = device_register(&platform_bus);
    if (ret < 0)
        return ret;
    ret = bus_register(&platform_bus_type);
    if (ret < 0)
        device_unregister(&platform_bus);
    return ret;
}

int platform_device_register(struct platform_device *pdev)
{
    if (!pdev || !pdev->name)
        return -EINVAL;
    pdev->dev.name = pdev->name;
    if (!pdev->dev.parent)
        pdev->dev.parent = &platform_bus;
    pdev->dev.bus = &platform_bus_type;
    pdev->of_match = 0;
    pdev->id_entry = 0;
    return device_register(&pdev->dev);
}

void platform_device_unregister(struct platform_device *pdev)
{
    if (pdev)
        device_unregister(&pdev->dev);
}

int platform_driver_register(struct platform_driver *pdrv)
{
    if (!pdrv || !pdrv->driver.name)
        return -EINVAL;
    pdrv->driver.bus = &platform_bus_type;
    return driver_register(&pdrv->driver);
}

void platform_driver_unregister(struct platform_driver *pdrv)
{
    if (pdrv)
        driver_unregister(&pdrv->driver);
}

const struct resource *platform_get_resource(struct platform_device *pdev,
                                             uint32_t type, uint32_t num)
{
    for (uint32_t i = 0; pdev && i < pdev->num_resources; ++i) {
        const struct resource *res = &pdev->resource[i];
        if ((res->flags & type) && num-- == 0)
            return res;
    }
    return 0;
}

const struct resource *platform_get_resource_byname(
    struct platform_device *pdev, uint32_t type, const char *name)
{
    for (uint32_t i = 0; pdev && i < pdev->num_resources; ++i) {
        const struct resource *res = &pdev->resource[i];
        if ((res->flags & type) && str_eq(res->name, name))
            return res;
    }
    return 0;
}

int platform_get_irq(struct platform_device *pdev, uint32_t num)
{
    const struct resource *res =
        platform_get_resource(pdev, IORESOURCE_IRQ, num);
    return res ? (int)res->start : -ENODEV;
}

void platform_dev_info(struct platform_device *pdev, const char *msg)
{
    t113_uart_puts(dev_name(&pdev->dev));
    t113_uart_puts(": ");
    t113_uart_puts(msg);
    for (uint32_t i = 0; i < pdev->num_resources; ++i) {
        const struct resource *res = &pdev->resource[i];
        if (res->flags & IORESOURCE_MEM) {
            t113_uart_puts(" mem");
            if (res->name) {
                t113_uart_putc('(');
                t113_uart_puts(res->name);
                t113_uart_putc(')');
            }
            t113_uart_putc(' ');
            t113_uart_puthex(res->start);
            t113_uart_putc('-');
            t113_uart_puthex(res->end);
        } else if (res->flags & IORESOURCE_IRQ) {
            t113_uart_puts(" irq ");
            t113_uart_puthex(res->start);
        }
    }
    t113_uart_putc('\n');
}
