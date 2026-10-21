#ifndef MINIBOOT_SD_H
#define MINIBOOT_SD_H

#include <stdint.h>

/* Returns 1 (SDSC) / 2 (SDHC/SDXC) on success, negative on failure. */
int t113_sd_init(void);
/* Read `count` 512-byte sectors starting at `lba` into 4-byte aligned buf. */
int t113_sd_read(uint32_t lba, uint32_t count, void *buf);
/* Write `count` 512-byte sectors. The caller must explicitly choose the LBA. */
int t113_sd_write(uint32_t lba, uint32_t count, const void *buf);

#endif
