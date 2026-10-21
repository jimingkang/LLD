#include "platform.h"
#include "platform_device.h"
#include "gpio.h"
#include "irq.h"
#include "spinlock.h"
#include "wait.h"
#include "fs/chrdev.h"
#include "fs/devfs.h"
#include "input/gpio_keys.h"

#define GPIO_KEYS_MAJOR 13u
#define KEY_EVENT_COUNT 16u

struct gpio_keys_state {
    const struct gpio_keys_platform_data *pdata;
    struct minios_input_event events[KEY_EVENT_COUNT];
    uint32_t head;
    uint32_t tail;
    uint32_t last_irq_us;
    volatile uint32_t irq_count;
    int value;
    spinlock_t lock;
    struct wait_queue_head wait;
};

static struct gpio_keys_state key0;

static void gpio_keys_irq(uint32_t irq, void *data)
{
    struct gpio_keys_state *key = (struct gpio_keys_state *)data;
    const struct gpio_keys_platform_data *pdata = key->pdata;
    (void)irq;

    if (!t113_gpio_irq_pending(pdata->gpio))
        return;
    t113_gpio_irq_ack(pdata->gpio);
    key->irq_count++;

    uint32_t now = (uint32_t)t113_time_us();
    int raw = t113_gpio_get(pdata->gpio);
    int value = pdata->active_low ? !raw : raw;
    if (value == key->value ||
        now - key->last_irq_us < pdata->debounce_ms * 1000u)
        return;

    uint32_t flags = spin_lock_irqsave(&key->lock);
    key->last_irq_us = now;
    key->value = value;
    uint32_t next = (key->head + 1u) % KEY_EVENT_COUNT;
    if (next != key->tail) {
        struct minios_input_event *event = &key->events[key->head];
        event->time_ms = now / 1000u;
        event->type = MINIOS_EV_KEY;
        event->code = pdata->code;
        event->value = value;
        key->head = next;
    }
    spin_unlock_irqrestore(&key->lock, flags);
    wake_up_all(&key->wait);
}

static int gpio_keys_read(struct file *file, void *buffer, uint32_t count)
{
    (void)file;
    if (!buffer || count < sizeof(struct minios_input_event))
        return -1;

    for (;;) {
        uint32_t flags = spin_lock_irqsave(&key0.wait.lock);
        spin_lock(&key0.lock);
        if (key0.head != key0.tail) {
            struct minios_input_event event = key0.events[key0.tail];
            key0.tail = (key0.tail + 1u) % KEY_EVENT_COUNT;
            spin_unlock(&key0.lock);
            spin_unlock_irqrestore(&key0.wait.lock, flags);
            *(struct minios_input_event *)buffer = event;
            return (int)sizeof(event);
        }
        spin_unlock(&key0.lock);
        wait_queue_sleep_locked(&key0.wait, flags);
    }
}

static const struct file_operations gpio_keys_fops = {
    .read = gpio_keys_read,
    .write = 0,
};

static int write_decimal(char *buffer, uint32_t capacity, uint32_t value)
{
    char reverse[10];
    uint32_t digits = 0;
    do {
        reverse[digits++] = (char)('0' + value % 10u);
        value /= 10u;
    } while (value && digits < sizeof(reverse));
    if (digits + 2u > capacity)
        return -1;
    for (uint32_t i = 0; i < digits; ++i)
        buffer[i] = reverse[digits - i - 1u];
    buffer[digits] = '\n';
    buffer[digits + 1u] = 0;
    return (int)(digits + 1u);
}

static int gpio_keys_show_value(struct device *device, char *buffer,
                                uint32_t capacity)
{
    struct gpio_keys_state *key = dev_get_drvdata(device);
    if (!key)
        return -1;
    int raw = t113_gpio_get(key->pdata->gpio);
    uint32_t value = (uint32_t)(key->pdata->active_low ? !raw : raw);
    return write_decimal(buffer, capacity, value);
}

static int gpio_keys_show_keycode(struct device *device, char *buffer,
                                  uint32_t capacity)
{
    struct gpio_keys_state *key = dev_get_drvdata(device);
    return key ? write_decimal(buffer, capacity, key->pdata->code) : -1;
}

static int gpio_keys_show_irq_count(struct device *device, char *buffer,
                                    uint32_t capacity)
{
    struct gpio_keys_state *key = dev_get_drvdata(device);
    return key ? write_decimal(buffer, capacity, key->irq_count) : -1;
}

static int gpio_keys_show_pending(struct device *device, char *buffer,
                                  uint32_t capacity)
{
    struct gpio_keys_state *key = dev_get_drvdata(device);
    return key ? write_decimal(buffer, capacity,
                               (uint32_t)t113_gpio_irq_pending(key->pdata->gpio))
               : -1;
}

static int gpio_keys_show_mux(struct device *device, char *buffer,
                              uint32_t capacity)
{
    struct gpio_keys_state *key = dev_get_drvdata(device);
    if (!key)
        return -1;
    uint32_t gpio = (uint32_t)key->pdata->gpio;
    return write_decimal(buffer, capacity,
                         t113_gpio_get_function(gpio / 32u, gpio % 32u));
}

static const struct device_attribute gpio_keys_attributes[] = {
    { .name = "value", .show = gpio_keys_show_value },
    { .name = "keycode", .show = gpio_keys_show_keycode },
    { .name = "irq_count", .show = gpio_keys_show_irq_count },
    { .name = "pending", .show = gpio_keys_show_pending },
    { .name = "mux", .show = gpio_keys_show_mux },
};

static int gpio_keys_probe(struct platform_device *pdev)
{
    const struct gpio_keys_platform_data *pdata =
        (const struct gpio_keys_platform_data *)pdev->dev.platform_data;
    int irq = platform_get_irq(pdev, 0);
    if (!pdata || irq < 0 || (uint32_t)irq != pdata->irq)
        return -ENODEV;

    key0.pdata = pdata;
    key0.head = key0.tail = 0;
    key0.last_irq_us = 0;
    key0.irq_count = 0;
    spin_lock_init(&key0.lock);
    init_waitqueue_head(&key0.wait);
    t113_gpio_set_pull((uint32_t)pdata->gpio / 32u,
                       (uint32_t)pdata->gpio % 32u, pdata->pull);
    t113_gpio_direction_input(pdata->gpio);
    key0.value = pdata->active_low ? !t113_gpio_get(pdata->gpio)
                                  : t113_gpio_get(pdata->gpio);

    if (t113_chrdev_register(GPIO_KEYS_MAJOR, 0u, &gpio_keys_fops) < 0 ||
        t113_devfs_create_chrdev("key0", GPIO_KEYS_MAJOR, 0u) < 0 ||
        t113_request_irq(pdata->irq, gpio_keys_irq, &key0) < 0 ||
        t113_gpio_irq_config(pdata->gpio, T113_GPIO_IRQ_BOTH) < 0)
        return -ENOSPC;

    platform_set_drvdata(pdev, &key0);
    pdev->dev.attributes = gpio_keys_attributes;
    pdev->dev.num_attributes =
        sizeof(gpio_keys_attributes) / sizeof(gpio_keys_attributes[0]);
    t113_gpio_irq_enable(pdata->gpio);
    t113_gic_enable_irq(pdata->irq);
    platform_dev_info(pdev, "PB4 active-low key -> /dev/key0 (EINT mux=0x0e)");
    return 0;
}

static const struct of_device_id gpio_keys_of_match[] = {
    { .compatible = "gpio-keys" },
    { 0 },
};

struct platform_driver gpio_keys_driver = {
    .probe = gpio_keys_probe,
    .driver = { .name = "gpio-keys" },
    .of_match_table = gpio_keys_of_match,
};
