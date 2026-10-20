#ifndef MINIOS_T113_MINIBOOT_UPDATE_H
#define MINIOS_T113_MINIBOOT_UPDATE_H

#include <stdint.h>

/* Keep this synchronized with the top-level image layout. */
#define MINIBOOT_SD_START_LBA  16u  /* 8 KiB */
#define BOOTPACK_SD_START_LBA 256u  /* 128 KiB */
#define MINIBOOT_MAX_BYTES \
    ((BOOTPACK_SD_START_LBA - MINIBOOT_SD_START_LBA) * 512u)

typedef int (*miniboot_block_write_t)(uint32_t lba, const void *data,
                                      uint32_t blocks, void *opaque);

/* Validate an Allwinner eGON.BT0 image including its Boot0 checksum. */
int miniboot_image_validate(const void *image, uint32_t received_size,
                            uint32_t *image_size);

/* Validate first, then write only the reserved [LBA 16, LBA 256) range. */
int miniboot_image_commit(const void *image, uint32_t received_size,
                          miniboot_block_write_t write_blocks, void *opaque);

#endif
