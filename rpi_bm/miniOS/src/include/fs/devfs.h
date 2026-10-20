#ifndef MINIOS_FS_DEVFS_H
#define MINIOS_FS_DEVFS_H

#include <stdint.h>

#define DEVFS_T_CHAR 3u

struct devfs_file_ops {
    int (*read)(void *buffer, uint32_t count);
    int (*write)(const void *buffer, uint32_t count);
};

int t113_devfs_init(void);
int t113_devfs_register_chrdev(const char *name, uint16_t major,
                               uint16_t minor,
                               const struct devfs_file_ops *ops);

#endif
