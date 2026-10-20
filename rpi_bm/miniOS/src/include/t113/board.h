#ifndef MINIOS_T113_BOARD_H
#define MINIOS_T113_BOARD_H

struct platform_driver;
struct i2c_driver;

/* Drivers for the SoC blocks the kernel already uses (see uart/gic/timer.c). */
extern struct platform_driver t113_uart_driver;
extern struct platform_driver t113_gic_driver;
extern struct platform_driver t113_timer_driver;
#ifdef CONFIG_INPUT_GPIO_KEYS
extern struct platform_driver gpio_keys_driver;
#endif

/* Camera path: CSIC DVP interface, TWI controller, OV5640 sensor. */
#ifdef CONFIG_VIDEO
extern struct platform_driver t113_csi_driver;
#endif
#ifdef CONFIG_I2C
extern struct platform_driver t113_twi_driver;
#endif
#ifdef CONFIG_VIDEO_OV5640
extern struct i2c_driver ov5640_driver;
#endif

/* WiFi path: SMHC1 SDIO host, XRadio function driver (XR829). */
struct sdio_driver;
#ifdef CONFIG_MMC_SUNXI
extern struct platform_driver t113_smhc_driver;
#endif
#ifdef CONFIG_WLAN_XRADIO_XR829
extern struct sdio_driver xradio_sdio_driver;
#endif

/* Static board description: 100ASK T113-S3 platform devices. */
int t113_board_register_devices(void);
int t113_board_register_drivers(void);

#endif
