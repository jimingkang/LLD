#ifndef MINIOS_T113_BOARD_H
#define MINIOS_T113_BOARD_H

struct platform_driver;

/* Drivers for the SoC blocks the kernel already uses (see uart/gic/timer.c). */
extern struct platform_driver t113_uart_driver;
extern struct platform_driver t113_gic_driver;
extern struct platform_driver t113_timer_driver;

/* Static board description: 100ASK T113-S3 platform devices. */
int t113_board_register_devices(void);
int t113_board_register_drivers(void);

#endif
