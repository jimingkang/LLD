#ifndef MINIOS_T113_PLATFORM_DEVICE_H
#define MINIOS_T113_PLATFORM_DEVICE_H

#include "device.h"

#define IORESOURCE_MEM 0x00000200u
#define IORESOURCE_IRQ 0x00000400u

struct resource {
    const char *name;
    uint32_t start;
    uint32_t end;               /* inclusive; for IRQs end == start */
    uint32_t flags;
};

#define DEFINE_RES_MEM_NAMED(_start, _size, _name) \
    { .name = (_name), .start = (_start), \
      .end = (_start) + (_size) - 1u, .flags = IORESOURCE_MEM }
#define DEFINE_RES_MEM(_start, _size) DEFINE_RES_MEM_NAMED(_start, _size, 0)
#define DEFINE_RES_IRQ(_irq) \
    { .name = 0, .start = (_irq), .end = (_irq), .flags = IORESOURCE_IRQ }

static inline uint32_t resource_size(const struct resource *res)
{
    return res->end - res->start + 1u;
}

/* Device-tree style match entry (no real DT yet: string compare only). */
struct of_device_id {
    const char *compatible;
    const void *data;
};

struct platform_device_id {
    const char *name;
    uint32_t driver_data;
};

struct platform_device {
    const char *name;
    const char *compatible;     /* optional, matched against of_match_table */
    uint32_t num_resources;
    const struct resource *resource;
    struct device dev;

    /* set by the bus when a driver binds */
    const struct of_device_id *of_match;
    const struct platform_device_id *id_entry;
};

struct platform_driver {
    int (*probe)(struct platform_device *pdev);
    void (*remove)(struct platform_device *pdev);
    struct device_driver driver;
    const struct of_device_id *of_match_table;   /* {0} terminated */
    const struct platform_device_id *id_table;   /* {0} terminated */
};

#define to_platform_device(d) container_of(d, struct platform_device, dev)
#define to_platform_driver(d) container_of(d, struct platform_driver, driver)

extern struct bus_type platform_bus_type;
extern struct device platform_bus;          /* /devices/platform */

int platform_bus_init(void);
int platform_device_register(struct platform_device *pdev);
void platform_device_unregister(struct platform_device *pdev);
int platform_driver_register(struct platform_driver *pdrv);
void platform_driver_unregister(struct platform_driver *pdrv);

const struct resource *platform_get_resource(struct platform_device *pdev,
                                             uint32_t type, uint32_t num);
const struct resource *platform_get_resource_byname(
    struct platform_device *pdev, uint32_t type, const char *name);
int platform_get_irq(struct platform_device *pdev, uint32_t num);

/* "<name>: <msg> mem a-b ... irq n\n" on the console. */
void platform_dev_info(struct platform_device *pdev, const char *msg);

static inline void platform_set_drvdata(struct platform_device *pdev,
                                        void *data)
{
    dev_set_drvdata(&pdev->dev, data);
}

static inline void *platform_get_drvdata(const struct platform_device *pdev)
{
    return dev_get_drvdata(&pdev->dev);
}

#endif
