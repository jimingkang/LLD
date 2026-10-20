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

static int bootfs_lookup(const char *path, struct vfs_node *node)
{
    const char *name = entry_name(path);
    const struct bootpack_entry *e = name ? t113_bootpack_find(name) : 0;
    if (!e || !e->size) return -1;
    node->id = e->load_addr;
    node->size = e->size;
    node->type = BOOTFS_T_FILE;
    return 0;
}

static int bootfs_read(const struct vfs_node *node, uint32_t offset,
                       void *destination, uint32_t count)
{
    if (!node || !destination || offset > node->size) return -1;
    if (count > node->size - offset) count = node->size - offset;
    uint8_t *dst = destination;
    const uint8_t *src = (const uint8_t *)(uintptr_t)(node->id + offset);
    for (uint32_t i = 0; i < count; ++i) dst[i] = src[i];
    return (int)count;
}

static const struct vfs_backend_ops bootfs_ops = {
    .lookup = bootfs_lookup,
    .read = bootfs_read,
    .readdir = 0,
};

int t113_bootfs_mount_vfs(void)
{
    int ret = t113_vfs_mount("/boot", &bootfs_ops);
    if (!ret) t113_uart_puts("bootfs: FAT32 handoff mounted at /boot\n");
    return ret;
}
