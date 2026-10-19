#ifndef MINIOS_T113_TWI_H
#define MINIOS_T113_TWI_H

#include "gpio.h"

/* Board data for an Allwinner TWI controller (platform_data of "twiN"). */
struct t113_twi_platform_data {
    uint32_t bus_hz;                /* 100000 or 400000 */
    const struct t113_pin *pins;    /* SCK/SDA pinmux */
    uint32_t num_pins;
};

#endif
