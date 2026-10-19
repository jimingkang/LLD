#ifndef MINIOS_T113_WIFI_H
#define MINIOS_T113_WIFI_H

#include "gpio.h"

/*
 * Board data for an SMHC host with an SDIO module behind it (platform_data
 * of "sdcN"): bus pins plus the module's power sequence.
 */
struct t113_mmc_platform_data {
    const struct t113_pin *pins;    /* CLK, CMD, D0..D3 */
    uint32_t num_pins;
    int power_gpio;                 /* module enable (WL_REG_ON), active high */
    uint32_t power_on_delay_ms;     /* after enable, before CMD5 */
    int fanout;                     /* CLK_FANOUT channel for 32k, -1 = none */
    struct t113_pin fanout_pin;     /* pin + function of that fanout */
};

#endif
