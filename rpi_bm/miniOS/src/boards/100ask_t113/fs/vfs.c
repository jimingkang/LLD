#include "fs/vfs.h"

#define VFS_OPEN_FILES 32u
#define VFS_MOUNTS     4u

struct vfs_mount {
    const char *path;
    const struct vfs_backend_ops *ops;
};

struct vfs_file {
    uint32_t used;
    uint32_t references;
    uint32_t flags;
    uint32_t offset;
    struct vfs_node node;
    const struct vfs_backend_ops *ops;
};

static struct vfs_mount mounts[VFS_MOUNTS];
static uint32_t mount_count;
static struct vfs_file open_files[VFS_OPEN_FILES];

static uint32_t path_length(const char *path)
{
    uint32_t length = 0;
    while (path[length]) ++length;
    return length;
}

static int path_prefix(const char *path, const char *prefix)
{
    while (*prefix && *path == *prefix) {
        ++path; ++prefix;
    }
    return *prefix == '\0';
}

static int mount_matches(const char *path, const char *mount_path,
                         uint32_t length)
{
    if (!path_prefix(path, mount_path))
        return 0;
    if (length == 1u && mount_path[0] == '/')
        return 1;
    return path[length] == '\0' || path[length] == '/' ||
           mount_path[length - 1u] == '/';
}

void t113_vfs_init(void)
{
    mount_count = 0;
    for (uint32_t i = 0; i < VFS_OPEN_FILES; ++i)
        open_files[i].used = 0;
}

int t113_vfs_mount(const char *path, const struct vfs_backend_ops *ops)
{
    if (!path || path[0] != '/' || !ops || !ops->lookup ||
        mount_count >= VFS_MOUNTS)
        return -1;
    mounts[mount_count].path = path;
    mounts[mount_count].ops = ops;
    ++mount_count;
    return 0;
}

struct vfs_file *t113_vfs_open(const char *path, uint32_t flags)
{
    if (!path || path[0] != '/' || flags != VFS_O_RDONLY)
        return 0;
    const struct vfs_mount *mount = 0;
    uint32_t best = 0;
    for (uint32_t i = 0; i < mount_count; ++i) {
        uint32_t length = path_length(mounts[i].path);
        if (length >= best && mount_matches(path, mounts[i].path, length)) {
            mount = &mounts[i];
            best = length;
        }
    }
    if (!mount)
        return 0;
    struct vfs_node node;
    if (mount->ops->lookup(path, &node) < 0)
        return 0;
    for (uint32_t i = 0; i < VFS_OPEN_FILES; ++i) {
        struct vfs_file *file = &open_files[i];
        if (file->used)
            continue;
        file->used = 1;
        file->references = 1;
        file->flags = flags;
        file->offset = 0;
        file->node = node;
        file->ops = mount->ops;
        return file;
    }
    return 0;
}

int t113_vfs_read(struct vfs_file *file, void *destination, uint32_t count)
{
    if (!file || !file->used || !file->ops || !file->ops->read)
        return -1;
    int result = file->ops->read(&file->node, file->offset,
                                 destination, count);
    if (result > 0)
        file->offset += (uint32_t)result;
    return result;
}

void t113_vfs_file_get(struct vfs_file *file)
{
    if (file && file->used)
        ++file->references;
}

void t113_vfs_close(struct vfs_file *file)
{
    if (!file || !file->used || file->references == 0)
        return;
    if (--file->references == 0) {
        file->used = 0;
        file->ops = 0;
    }
}

uint32_t t113_vfs_file_size(const struct vfs_file *file)
{
    return file && file->used ? file->node.size : 0;
}

uint32_t t113_vfs_file_offset(const struct vfs_file *file)
{
    return file && file->used ? file->offset : 0;
}
