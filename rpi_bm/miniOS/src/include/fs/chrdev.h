#ifndef MINIOS_FS_CHRDEV_H
#define MINIOS_FS_CHRDEV_H

#include <stdint.h>
#include "fs/vfs.h"

#define MINIOS_MKDEV(major, minor) \
    ((((uint32_t)(major)) << 16) | ((uint32_t)(minor) & 0xffffu))
#define MINIOS_MAJOR(dev) ((uint16_t)((uint32_t)(dev) >> 16))
#define MINIOS_MINOR(dev) ((uint16_t)((uint32_t)(dev) & 0xffffu))

void t113_chrdev_init(void);
int t113_chrdev_register(uint16_t major, uint16_t minor,
                         const struct file_operations *fops);
const struct file_operations *t113_chrdev_inode_fops(void);

#endif
