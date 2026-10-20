#ifndef MINIOS_T113_SD_H
#define MINIOS_T113_SD_H

#include <stdint.h>

/* Polling block access to the boot/root SD card on SMHC0. */
int t113_sd_init(void);
int t113_sd_read(uint32_t lba, uint32_t count, void *buffer);
int t113_sd_write(uint32_t lba, uint32_t count, const void *buffer);

#endif
