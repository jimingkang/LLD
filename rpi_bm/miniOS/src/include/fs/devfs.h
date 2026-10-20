#ifndef MINIOS_FS_DEVFS_H
#define MINIOS_FS_DEVFS_H

#include <stdint.h>
#include "fs/vfs.h"

#define DEVFS_T_CHAR VFS_NODE_CHAR

int t113_devfs_init(void);
int t113_devfs_create_chrdev(const char *name, uint16_t major,
                             uint16_t minor);

#endif
