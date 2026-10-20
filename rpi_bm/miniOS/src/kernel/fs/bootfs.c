/*
 * FAT32 boot partition handoff filesystem.
 *
 * SPL reads the FAT32 cluster chains before entering the kernel and records
 * the resident DDR images in the bootpack handoff header.  This backend
 * exposes those files through the normal kernel VFS at /boot, so drivers do
 * not depend on bootloader-private names or addresses.
 */
#include "platform.h"
#include "bootpack.h"
#include "fs/vfs.h"
#include "fs/bootfs.h"

#define BOOTFS_T_FILE 2u

static int equal(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return *a == *b;
}

static const char *entry_name(const char *path)
{
    if (equal(path, "/boot/boot_xr829.bin")) return "boot_xr829";
    if (equal(path, "/boot/fw_xr829.bin")) return "fw_xr829";
    if (equal(path, "/boot/sdd_xr829.bin")) return "sdd_xr829";
    return 0;
}

static const struct inode_operations bootfs_iops;
static const struct file_operations bootfs_file_fops;
static const struct file_operations bootfs_dir_fops;

static int bootfs_lookup(struct inode *directory, struct dentry *child)
{
    (void)directory;
    const char *name = entry_name(child->d_path);
    const struct bootpack_entry *e = name ? t113_bootpack_find(name) : 0;
    if (!e || !e->size) return -1;
    return t113_vfs_bind_inode(child, e->load_addr, e->size, BOOTFS_T_FILE,
                               0, (void *)e, &bootfs_iops,
                               &bootfs_file_fops);
}

static int bootfs_read(struct file *file, void *destination, uint32_t count)
{
    struct inode *inode = file ? file->f_inode : 0;
    uint32_t offset = file ? file->f_pos : 0;
    if (!inode || !destination || offset > inode->i_size) return -1;
    if (count > inode->i_size - offset) count = inode->i_size - offset;
    uint8_t *dst = destination;
    const uint8_t *src =
        (const uint8_t *)(uintptr_t)(inode->i_ino + offset);
    for (uint32_t i = 0; i < count; ++i) dst[i] = src[i];
    return (int)count;
}

static const struct inode_operations bootfs_iops = {
    .lookup = bootfs_lookup,
};

static const struct file_operations bootfs_file_fops = {
    .read = bootfs_read,
};

static const struct file_operations bootfs_dir_fops = {
    .readdir = 0,
};

int t113_bootfs_mount_vfs(void)
{
    int ret = t113_vfs_mount_fs("/boot", 0x424f4f54u, 0, 0,
                                &bootfs_iops, &bootfs_dir_fops);
    if (!ret) t113_uart_puts("bootfs: FAT32 handoff mounted at /boot\n");
    return ret;
}
