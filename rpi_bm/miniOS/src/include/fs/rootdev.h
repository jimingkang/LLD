#ifndef MINIOS_FS_ROOTDEV_H
#define MINIOS_FS_ROOTDEV_H

#include <stdint.h>

/* Initialise SD0 and select MBR partition 2 as the root block device. */
int t113_rootdev_init(void);
int t113_rootdev_read(uint32_t sector, uint32_t count, void *destination);
uint32_t t113_rootdev_sectors(void);

#endif
