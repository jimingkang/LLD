/*
 * 100ASK T113-S3 board description: the SoC blocks the kernel currently
 * drives, expressed as platform devices (a hand-written stand-in for a
 * device tree). Addresses/IRQs follow sun8i-t113s.dtsi.
 *
 * The UART3/GIC/Timer0 drivers do NOT touch hardware: UART3 is brought up
 * by t113_uart_init() as the early console, and GIC/Timer0 are still
 * initialised explicitly from kernel_main() in their existing order.
 * The camera path (csi0, twi2, ov5640) is new and is initialised by its
 * drivers' probe functions.
 */
#include "platform.h"
#include "platform_device.h"
#include "i2c.h"
#include "gpio.h"
#include "twi.h"
#include "camera.h"
#include "mmc.h"
#include "wifi.h"
#include "board.h"
#include "input/gpio_keys.h"

static const struct resource uart3_resources[] = {
    DEFINE_RES_MEM(T113_UART3_BASE, T113_UART3_SIZE),
    DEFINE_RES_IRQ(T113_IRQ_UART3),
};

static const struct resource gic_resources[] = {
    DEFINE_RES_MEM_NAMED(T113_GIC_DIST_BASE, T113_GIC_DIST_SIZE, "dist"),
    DEFINE_RES_MEM_NAMED(T113_GIC_CPU_BASE, T113_GIC_CPU_SIZE, "cpu"),
};

static const struct resource timer0_resources[] = {
    DEFINE_RES_MEM(T113_TIMER_BASE, T113_TIMER_SIZE),
    DEFINE_RES_IRQ(T113_IRQ_TIMER0),
};

#ifdef CONFIG_INPUT_GPIO_KEYS
static const struct resource user_key_resources[] = {
    DEFINE_RES_IRQ(T113_IRQ_GPIOB),
};

/* 100ASK T113-S3 USER KEY beside RESET: PB4, active low. */
static const struct gpio_keys_platform_data user_key_pdata = {
    .gpio = T113_GPIO(T113_PB, 4),
    .irq = T113_IRQ_GPIOB,
    .code = MINIOS_KEY_ENTER,
    .active_low = 1u,
    .pull = T113_PULL_UP,
    .debounce_ms = 20u,
};
#endif

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

/*
 * DVP camera connector (100ASK T113-Pro). PE0..PE13 are shared with the
 * EMAC; the PE<->CSI jumpers must be fitted for the camera to answer.
 * Pin functions from sun20i-d1 pinctrl: ncsi0 = 2 on PE0..PE11, i2c2 = 2
 * on PE12/PE13. Sensor I2C is TWI2 (sensor0_twi_cci_id = 2 in Tina DTS).
 */
#ifdef CONFIG_VIDEO
static const struct resource csi0_resources[] = {
    DEFINE_RES_MEM_NAMED(T113_CSI_TOP_BASE, T113_CSI_TOP_SIZE, "top"),
    DEFINE_RES_MEM_NAMED(T113_CSI0_BASE, T113_CSI0_SIZE, "csi0"),
    DEFINE_RES_MEM_NAMED(T113_VINC0_BASE, T113_VINC0_SIZE, "vinc0"),
    DEFINE_RES_IRQ(T113_IRQ_CSI0),
    DEFINE_RES_IRQ(T113_IRQ_VINC0),
};

#define NCSI0_PIN(n) { T113_PE, (n), 2u, T113_PULL_NONE }
static const struct t113_pin csi0_pins[] = {
    NCSI0_PIN(0),  NCSI0_PIN(1),  NCSI0_PIN(2),  NCSI0_PIN(3),  /* HS VS PCLK MCLK */
    NCSI0_PIN(4),  NCSI0_PIN(5),  NCSI0_PIN(6),  NCSI0_PIN(7),  /* D0..D3 */
    NCSI0_PIN(8),  NCSI0_PIN(9),  NCSI0_PIN(10), NCSI0_PIN(11), /* D4..D7 */
};

static const struct t113_csi_platform_data csi0_pdata = {
    .mclk_hz = 24000000u,
    .pins = csi0_pins,
    .num_pins = ARRAY_SIZE(csi0_pins),
};
#endif

#ifdef CONFIG_I2C
static const struct resource twi2_resources[] = {
    DEFINE_RES_MEM(T113_TWI_BASE(2), T113_TWI_SIZE),
};

static const struct t113_pin twi2_pins[] = {
    { T113_PE, 12, 2u, T113_PULL_UP },      /* TWI2_SCK */
    { T113_PE, 13, 2u, T113_PULL_UP },      /* TWI2_SDA */
};

static const struct t113_twi_platform_data twi2_pdata = {
    .bus_hz = 100000u,
    .pins = twi2_pins,
    .num_pins = ARRAY_SIZE(twi2_pins),
};
#endif

/*
 * XR829 WiFi/BT module on SMHC1 (Base-SCH V1.2 p4/p9): SDIO_CLK/CMD/D0-3 =
 * PG0..PG5 (func 2, 33R on CLK), WL_REG_ON = PG12, 32.768 kHz from
 * CLK_FANOUT1 on PG11 (func 5), WL_WAKE_AP = PG10 (unused, polling).
 */
#ifdef CONFIG_MMC_SUNXI
static const struct resource sdc1_resources[] = {
    DEFINE_RES_MEM(T113_SMHC_BASE(1), T113_SMHC_SIZE),
    DEFINE_RES_IRQ(T113_IRQ_SMHC1),
};

static const struct t113_pin sdc1_pins[] = {
    { T113_PG, 0, 2u, T113_PULL_NONE },     /* SDC1-CLK */
    { T113_PG, 1, 2u, T113_PULL_UP },       /* SDC1-CMD */
    { T113_PG, 2, 2u, T113_PULL_UP },       /* SDC1-D0 */
    { T113_PG, 3, 2u, T113_PULL_UP },       /* SDC1-D1 */
    { T113_PG, 4, 2u, T113_PULL_UP },       /* SDC1-D2 */
    { T113_PG, 5, 2u, T113_PULL_UP },       /* SDC1-D3 */
};

static const struct t113_mmc_platform_data sdc1_pdata = {
    .pins = sdc1_pins,
    .num_pins = 6,
    .power_gpio = T113_GPIO(T113_PG, 12),   /* WL_REG_ON */
    .power_on_delay_ms = 100,
    .fanout = 1,
    .fanout_pin = { T113_PG, 11, 5u, T113_PULL_NONE },  /* CLK-FANOUT1 */
};
#endif

static struct platform_device uart3_device = {
    .name = "uart3",
    .compatible = "allwinner,sun20i-d1-uart",
    .num_resources = ARRAY_SIZE(uart3_resources),
    .resource = uart3_resources,
};

static struct platform_device gic_device = {
    .name = "gic",
    .compatible = "arm,cortex-a7-gic",
    .num_resources = ARRAY_SIZE(gic_resources),
    .resource = gic_resources,
};

static struct platform_device timer0_device = {
    .name = "timer0",
    .compatible = "allwinner,sun20i-d1-timer",
    .num_resources = ARRAY_SIZE(timer0_resources),
    .resource = timer0_resources,
};

#ifdef CONFIG_INPUT_GPIO_KEYS
static struct platform_device user_key_device = {
    .name = "user-key",
    .compatible = "gpio-keys",
    .num_resources = ARRAY_SIZE(user_key_resources),
    .resource = user_key_resources,
    .dev = { .platform_data = (void *)&user_key_pdata },
};
#endif

#ifdef CONFIG_VIDEO
static struct platform_device csi0_device = {
    .name = "csi0",
    .compatible = "allwinner,sun8iw20p1-csi",
    .num_resources = ARRAY_SIZE(csi0_resources),
    .resource = csi0_resources,
    .dev = { .platform_data = (void *)&csi0_pdata },
};
#endif

#ifdef CONFIG_MMC_SUNXI
static struct platform_device sdc1_device = {
    .name = "sdc1",
    .compatible = "allwinner,sun20i-d1-mmc",
    .num_resources = ARRAY_SIZE(sdc1_resources),
    .resource = sdc1_resources,
    .dev = { .platform_data = (void *)&sdc1_pdata },
};
#endif

#ifdef CONFIG_I2C
static struct platform_device twi2_device = {
    .name = "twi2",
    .compatible = "allwinner,sun20i-d1-i2c",
    .num_resources = ARRAY_SIZE(twi2_resources),
    .resource = twi2_resources,
    .dev = { .platform_data = (void *)&twi2_pdata },
};
#endif

/*
 * 100ASK_T113-Pro_Base-SCH_V1.2 p3: J17 PWDN is tied to GND and RESET goes
 * through U14 to the board's system RESET line, so neither needs a GPIO.
 * SCL/SDA/XCLK pass through TXS0108E U14/U15 whose OE and VCCA are
 * VCC_CSI (DIOVDD jumper J11/J13/J16) - no DIOVDD, no camera bus at all.
 * (T113-S3 only bonds out PE0..PE13 anyway.)
 */
#ifdef CONFIG_VIDEO_OV5640
static const struct ov5640_platform_data ov5640_pdata = {
    .pwdn_gpio = T113_GPIO_NONE,
    .reset_gpio = T113_GPIO_NONE,
    .csi_id = 0,
};

static struct i2c_client ov5640_client = {
    .name = "ov5640",
    .compatible = "ovti,ov5640",
    .addr = 0x3c,                           /* 0x78 in 8-bit notation */
    .adapter_nr = 2,
    .platform_data = (void *)&ov5640_pdata,
};
#endif

/* Interrupt controller first, like DT probing order on real Linux. */
static struct platform_device *const board_devices[] = {
    &gic_device,
    &uart3_device,
    &timer0_device,
#ifdef CONFIG_INPUT_GPIO_KEYS
    &user_key_device,
#endif
#ifdef CONFIG_VIDEO
    &csi0_device,
#endif
#ifdef CONFIG_I2C
    &twi2_device,
#endif
#ifdef CONFIG_MMC_SUNXI
    &sdc1_device,
#endif
};

/*
 * Order matters for the camera: csi (MCLK) and twi (adapter) must be bound
 * before the ov5640 driver registers, because probe runs under the core
 * lock and there is no deferred-probe retry yet.
 */
static struct platform_driver *const board_drivers[] = {
    &t113_gic_driver,
    &t113_uart_driver,
    &t113_timer_driver,
#ifdef CONFIG_INPUT_GPIO_KEYS
    &gpio_keys_driver,
#endif
#ifdef CONFIG_VIDEO
    &t113_csi_driver,
#endif
#ifdef CONFIG_I2C
    &t113_twi_driver,
#endif
#ifdef CONFIG_MMC_SUNXI
    &t113_smhc_driver,
#endif
};

#ifdef CONFIG_VIDEO_OV5640
static struct i2c_driver *const board_i2c_drivers[] = {
    &ov5640_driver,
};
#endif

int t113_board_register_devices(void)
{
    int failed = 0;
    for (uint32_t i = 0; i < ARRAY_SIZE(board_devices); ++i) {
        if (platform_device_register(board_devices[i]) < 0) {
            t113_uart_puts("board: cannot register device ");
            t113_uart_puts(board_devices[i]->name);
            t113_uart_putc('\n');
            ++failed;
        }
    }
#ifdef CONFIG_VIDEO_OV5640
    if (i2c_new_client_device(&ov5640_client, &twi2_device.dev) < 0) {
        t113_uart_puts("board: cannot register i2c client ov5640\n");
        ++failed;
    }
#endif
    return failed ? -EINVAL : 0;
}

int t113_board_register_drivers(void)
{
    int failed = 0;
    for (uint32_t i = 0; i < ARRAY_SIZE(board_drivers); ++i) {
        if (platform_driver_register(board_drivers[i]) < 0) {
            t113_uart_puts("board: cannot register driver ");
            t113_uart_puts(board_drivers[i]->driver.name);
            t113_uart_putc('\n');
            ++failed;
        }
    }
#ifdef CONFIG_WLAN_XRADIO_XR829
    if (sdio_driver_register(&xradio_sdio_driver) < 0) {
        t113_uart_puts("board: cannot register sdio driver xradio_wlan\n");
        ++failed;
    }
#endif
#ifdef CONFIG_VIDEO_OV5640
    for (uint32_t i = 0; i < ARRAY_SIZE(board_i2c_drivers); ++i) {
        if (i2c_driver_register(board_i2c_drivers[i]) < 0) {
            t113_uart_puts("board: cannot register i2c driver ");
            t113_uart_puts(board_i2c_drivers[i]->driver.name);
            t113_uart_putc('\n');
            ++failed;
        }
    }
#endif
    return failed ? -EINVAL : 0;
}
