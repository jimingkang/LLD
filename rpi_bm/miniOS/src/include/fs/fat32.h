#ifndef MINIOS_FS_FAT32_H
#define MINIOS_FS_FAT32_H

/* Mount the SD card's first FAT32 MBR partition read/write at /boot. */
int t113_fat32_mount_vfs(void);

#endif
