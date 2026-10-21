#ifndef MINIBOOT_FAT32_H
#define MINIBOOT_FAT32_H

#include <stdint.h>

struct fat32_fs {
    uint32_t partition_lba;
    uint32_t fat_lba;
    uint32_t data_lba;
    uint32_t sectors_per_fat;
    uint32_t root_cluster;
    uint8_t sectors_per_cluster;
    uint8_t fats;
};

/* Mount the first FAT32 MBR partition (or a FAT32 super-floppy). */
int fat32_mount(struct fat32_fs *fs);
/* Load a file from the FAT32 root directory. Long file names are supported. */
int fat32_load_root(struct fat32_fs *fs, const char *name, void *dst,
                    uint32_t capacity, uint32_t *size_out);

#endif
