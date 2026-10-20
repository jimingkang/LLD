#ifndef MINIOS_FS_BOOTFS_H
#define MINIOS_FS_BOOTFS_H

/* Mount the FAT32 files preloaded by SPL at /boot. */
int t113_bootfs_mount_vfs(void);

#endif
