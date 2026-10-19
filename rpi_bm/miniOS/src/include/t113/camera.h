#ifndef MINIOS_T113_CAMERA_H
#define MINIOS_T113_CAMERA_H

#include "gpio.h"

/* Board data for the CSIC parallel (DVP) interface ("csi0"). */
struct t113_csi_platform_data {
    uint32_t mclk_hz;               /* sensor master clock, from 24 MHz HOSC */
    const struct t113_pin *pins;    /* NCSI0 HSYNC/VSYNC/PCLK/MCLK/D0..D7 */
    uint32_t num_pins;
};

/* Non-zero once csi<id> has probed and its MCLK output is running. */
int t113_csi_mclk_running(uint32_t id);

/* Board data for an OmniVision OV5640 on DVP (i2c client "ov5640"). */
struct ov5640_platform_data {
    int pwdn_gpio;                  /* active high, T113_GPIO_NONE if hard-wired */
    int reset_gpio;                 /* active low,  T113_GPIO_NONE if hard-wired */
    uint32_t csi_id;                /* which CSI provides MCLK */
};

#define OV5640_CHIP_ID 0x5640u

struct i2c_client;
int ov5640_read_reg(struct i2c_client *client, uint16_t reg, uint8_t *val);
int ov5640_write_reg(struct i2c_client *client, uint16_t reg, uint8_t val);

#endif
