#ifndef MINIOS_T113_VFS_H
#define MINIOS_T113_VFS_H

#include <stdint.h>

#define VFS_O_RDONLY 0u

struct vfs_node {
    uint32_t id;
    uint32_t size;
    uint32_t type;
};

struct vfs_file;

struct vfs_backend_ops {
    int (*lookup)(const char *path, struct vfs_node *node);
    int (*read)(const struct vfs_node *node, uint32_t offset,
                void *destination, uint32_t count);
};

void t113_vfs_init(void);
int t113_vfs_mount(const char *path, const struct vfs_backend_ops *ops);
struct vfs_file *t113_vfs_open(const char *path, uint32_t flags);
int t113_vfs_read(struct vfs_file *file, void *destination, uint32_t count);
void t113_vfs_file_get(struct vfs_file *file);
void t113_vfs_close(struct vfs_file *file);
uint32_t t113_vfs_file_size(const struct vfs_file *file);
uint32_t t113_vfs_file_offset(const struct vfs_file *file);

#endif
