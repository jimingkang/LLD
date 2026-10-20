#ifndef MINIOS_USER_INPUT_H
#define MINIOS_USER_INPUT_H

#include <stdint.h>

#define EV_KEY     1u
#define KEY_ENTER 28u

struct input_event {
    uint32_t time_ms;
    uint16_t type;
    uint16_t code;
    int32_t value;
};

#endif
