/*
 * OmniVision OV5640 (DVP) sensor — framework stage.
 *
 * SCCB = I2C with 16-bit register addresses and 8-bit data, 7-bit address
 * 0x3c (0x78 in Allwinner's 8-bit notation). Probe runs the power-up
 * sequence (if PWDN/RESET are wired to GPIOs), checks that the CSI master
 * clock is running and reads the chip ID (0x300a/0x300b = 0x56 0x40).
 * No streaming register tables are written yet.
 */
#include "platform.h"
#include "i2c.h"
#include "gpio.h"
#include "camera.h"
#include "board.h"

#define OV5640_REG_CHIP_ID_HIGH 0x300au
#define OV5640_REG_CHIP_ID_LOW  0x300bu
#define OV5640_REG_REVISION     0x302au

struct ov5640 {
    struct i2c_client *client;
    uint32_t chip_id;
    uint8_t revision;
};

static struct ov5640 ov5640_sensor;

int ov5640_read_reg(struct i2c_client *client, uint16_t reg, uint8_t *val)
{
    uint8_t addr[2] = { (uint8_t)(reg >> 8), (uint8_t)reg };
    struct i2c_msg msgs[2] = {
        { .addr = client->addr, .flags = 0, .len = 2, .buf = addr },
        { .addr = client->addr, .flags = I2C_M_RD, .len = 1, .buf = val },
    };
    int ret = i2c_transfer(client->adapter, msgs, 2);
    return ret == 2 ? 0 : (ret < 0 ? ret : -EIO);
}

int ov5640_write_reg(struct i2c_client *client, uint16_t reg, uint8_t val)
{
    uint8_t buf[3] = { (uint8_t)(reg >> 8), (uint8_t)reg, val };
    struct i2c_msg msg = {
        .addr = client->addr, .flags = 0, .len = 3, .buf = buf,
    };
    int ret = i2c_transfer(client->adapter, &msg, 1);
    return ret == 1 ? 0 : (ret < 0 ? ret : -EIO);
}

static void dump_reg(const char *name, uint32_t addr)
{
    t113_uart_puts("  ");
    t113_uart_puts(name);
    t113_uart_puts(" [");
    t113_uart_puthex(addr);
    t113_uart_puts("] = ");
    t113_uart_puthex(mmio_read32(addr));
    t113_uart_putc('\n');
}

/* Everything needed to tell "no wiring" from "no clock" from "wrong chip". */
static void ov5640_diagnose(struct i2c_client *client)
{
    t113_uart_puts(dev_name(&client->dev));
    t113_uart_puts(": diagnostics\n");
    i2c_dump_adapter(client->adapter);
    dump_reg("CCU TWI_BGR   (want bit2|bit18)", T113_CCU_TWI_BGR);
    dump_reg("CCU CSI_BGR   (want bit0|bit16)", T113_CCU_CSI_BGR);
    dump_reg("CCU CSI_MCLK0 (want 0x80000000)", T113_CCU_CSI_MCLK0);
    dump_reg("PE_CFG0 PE0-7  (want 0x22222222)", T113_PIO_BASE + 4u * 0x30u + 0x00u);
    dump_reg("PE_CFG1 PE8-15 (want 0x..222222)", T113_PIO_BASE + 4u * 0x30u + 0x04u);
    dump_reg("PE_DAT", T113_PIO_BASE + 4u * 0x30u + 0x10u);
    dump_reg("PE_PULL0", T113_PIO_BASE + 4u * 0x30u + 0x24u);
    i2c_scan(client->adapter);
}

/* Datasheet power-up: PWDN high/RESET low -> MCLK -> PWDN low -> RESET high. */
/*
 * pwdn_on is the PWDN level that powers the sensor DOWN: 1 for a bare
 * OV5640 (PWDN active high), 0 if the module inverts it.
 */
static void ov5640_power_on(const struct ov5640_platform_data *pdata,
                            uint32_t pwdn_on)
{
    if (pdata->pwdn_gpio < 0 && pdata->reset_gpio < 0) {
        t113_mdelay(20);            /* hard-wired: just let it settle */
        return;
    }
    t113_gpio_direction_output(pdata->pwdn_gpio, pwdn_on);
    t113_gpio_direction_output(pdata->reset_gpio, 0);
    t113_mdelay(5);
    t113_gpio_direction_output(pdata->pwdn_gpio, !pwdn_on);
    t113_mdelay(1);
    t113_gpio_direction_output(pdata->reset_gpio, 1);
    t113_mdelay(20);
}

static void ov5640_power_off(const struct ov5640_platform_data *pdata,
                             uint32_t pwdn_on)
{
    t113_gpio_direction_output(pdata->reset_gpio, 0);
    t113_gpio_direction_output(pdata->pwdn_gpio, pwdn_on);
}

static int ov5640_read_id(struct i2c_client *client, uint8_t *hi, uint8_t *lo)
{
    int ret = ov5640_read_reg(client, OV5640_REG_CHIP_ID_HIGH, hi);
    if (!ret)
        ret = ov5640_read_reg(client, OV5640_REG_CHIP_ID_LOW, lo);
    return ret;
}

static int ov5640_probe(struct i2c_client *client)
{
    const struct ov5640_platform_data *pdata = client->platform_data;
    uint8_t hi = 0, lo = 0, rev = 0;
    int ret;

    if (!pdata)
        return -EINVAL;
    if (!t113_csi_mclk_running(pdata->csi_id)) {
        t113_uart_puts(dev_name(&client->dev));
        t113_uart_puts(": csi MCLK not running (csi driver not bound?)\n");
        return -ENODEV;
    }

    /* Try PWDN active-high (datasheet) first, then an inverted module. */
    uint32_t pwdn_on = 1;
    ov5640_power_on(pdata, pwdn_on);
    ret = ov5640_read_id(client, &hi, &lo);
    if (ret < 0 && pdata->pwdn_gpio >= 0) {
        t113_uart_puts(dev_name(&client->dev));
        t113_uart_puts(": no answer with PWDN active-high, trying inverted\n");
        pwdn_on = 0;
        ov5640_power_on(pdata, pwdn_on);
        ret = ov5640_read_id(client, &hi, &lo);
    }
    if (ret < 0) {
        t113_uart_puts(dev_name(&client->dev));
        t113_uart_puts(ret == -ENXIO ? ": no ACK at 0x3c (check PE jumpers"
                                       " CSI vs EMAC, sensor power)\n"
                                     : ": SCCB transfer failed\n");
        ov5640_diagnose(client);
        ov5640_power_off(pdata, 1);
        return ret;
    }
    if (pdata->pwdn_gpio >= 0) {
        t113_uart_puts(dev_name(&client->dev));
        t113_uart_puts(pwdn_on ? ": PWDN is active-high\n"
                               : ": PWDN is active-low (inverted on module)\n");
    }

    uint32_t id = ((uint32_t)hi << 8) | lo;
    if (id != OV5640_CHIP_ID) {
        t113_uart_puts(dev_name(&client->dev));
        t113_uart_puts(": unexpected chip id ");
        t113_uart_puthex(id);
        t113_uart_putc('\n');
        ov5640_power_off(pdata, pwdn_on);
        return -ENODEV;
    }
    ov5640_read_reg(client, OV5640_REG_REVISION, &rev);

    ov5640_sensor.client = client;
    ov5640_sensor.chip_id = id;
    ov5640_sensor.revision = rev;
    i2c_set_clientdata(client, &ov5640_sensor);

    t113_uart_puts(dev_name(&client->dev));
    t113_uart_puts(": OV5640 detected on ");
    t113_uart_puts(client->adapter->name);
    t113_uart_puts(", chip id ");
    t113_uart_puthex(id);
    t113_uart_puts(" rev ");
    t113_uart_puthex(rev);
    t113_uart_putc('\n');
    return 0;
}

static void ov5640_remove(struct i2c_client *client)
{
    ov5640_power_off(client->platform_data, 1);
    ov5640_sensor.client = 0;
}

static const struct of_device_id ov5640_of_match[] = {
    { .compatible = "ovti,ov5640" },
    { 0 },
};

static const struct i2c_device_id ov5640_id[] = {
    { "ov5640", 0 },
    { 0, 0 },
};

struct i2c_driver ov5640_driver = {
    .probe = ov5640_probe,
    .remove = ov5640_remove,
    .driver = { .name = "ov5640" },
    .of_match_table = ov5640_of_match,
    .id_table = ov5640_id,
};
