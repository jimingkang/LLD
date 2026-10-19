#ifndef MINIOS_T113_DRIVER_MODEL_H
#define MINIOS_T113_DRIVER_MODEL_H

#include "kobject.h"

/*
 * Brings up the three top-level ksets (/devices, /bus, /drivers), the
 * platform bus and the board's platform devices + drivers, then prints the
 * resulting tree. Pure bookkeeping: no hardware is (re)initialised here.
 */
void t113_driver_core_init(void);
void t113_driver_core_dump(void);

struct kset *t113_devices_kset(void);   /* every struct device */
struct kset *t113_drivers_kset(void);   /* every struct device_driver */
struct kset *t113_buses_kset(void);     /* every struct bus_type */

#endif
