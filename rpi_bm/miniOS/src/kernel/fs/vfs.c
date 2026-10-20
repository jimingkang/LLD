#include "fs/vfs.h"
#include "mutex.h"

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
static struct mutex vfs_lock;

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
    mutex_init(&vfs_lock);
    mount_count = 0;
    for (uint32_t i = 0; i < VFS_OPEN_FILES; ++i)
        open_files[i].used = 0;
}

int t113_vfs_mount(const char *path, const struct vfs_backend_ops *ops)
{
    if (!path || path[0] != '/' || !ops || !ops->lookup ||
        mount_count >= VFS_MOUNTS)
        return -1;
    mutex_lock(&vfs_lock);
    if (mount_count >= VFS_MOUNTS) {
        mutex_unlock(&vfs_lock);
        return -1;
    }
    mounts[mount_count].path = path;
    mounts[mount_count].ops = ops;
    ++mount_count;
    mutex_unlock(&vfs_lock);
    return 0;
}

struct vfs_file *t113_vfs_open(const char *path, uint32_t flags)
{
    if (!path || path[0] != '/' ||
        (flags != VFS_O_RDONLY && flags != VFS_O_RDWR))
        return 0;
    mutex_lock(&vfs_lock);
    const struct vfs_mount *mount = 0;
    uint32_t best = 0;
    for (uint32_t i = 0; i < mount_count; ++i) {
        uint32_t length = path_length(mounts[i].path);
        if (length >= best && mount_matches(path, mounts[i].path, length)) {
            mount = &mounts[i];
            best = length;
        }
    }
    if (!mount) {
        mutex_unlock(&vfs_lock);
        return 0;
    }
    struct vfs_node node;
    if (mount->ops->lookup(path, &node) < 0) {
        mutex_unlock(&vfs_lock);
        return 0;
    }
    if (flags != VFS_O_RDONLY && !mount->ops->open) {
        mutex_unlock(&vfs_lock);
        return 0;
    }
    if (mount->ops->open && mount->ops->open(&node, flags) < 0) {
        mutex_unlock(&vfs_lock);
        return 0;
    }
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
        mutex_unlock(&vfs_lock);
        return file;
    }
    mutex_unlock(&vfs_lock);
    return 0;
}

int t113_vfs_write(struct vfs_file *file, const void *source, uint32_t count)
{
    mutex_lock(&vfs_lock);
    if (!file || !file->used || file->flags != VFS_O_RDWR ||
        !file->ops || !file->ops->write) {
        mutex_unlock(&vfs_lock);
        return -1;
    }
    int result = file->ops->write(&file->node, file->offset, source, count);
    if (result > 0)
        file->offset += (uint32_t)result;
    mutex_unlock(&vfs_lock);
    return result;
}

int t113_vfs_read(struct vfs_file *file, void *destination, uint32_t count)
{
    mutex_lock(&vfs_lock);
    if (!file || !file->used || !file->ops || !file->ops->read) {
        mutex_unlock(&vfs_lock);
        return -1;
    }
    int result = file->ops->read(&file->node, file->offset,
                                 destination, count);
    if (result > 0)
        file->offset += (uint32_t)result;
    mutex_unlock(&vfs_lock);
    return result;
}

void t113_vfs_file_get(struct vfs_file *file)
{
    mutex_lock(&vfs_lock);
    if (file && file->used)
        ++file->references;
    mutex_unlock(&vfs_lock);
}

void t113_vfs_close(struct vfs_file *file)
{
    mutex_lock(&vfs_lock);
    if (!file || !file->used || file->references == 0) {
        mutex_unlock(&vfs_lock);
        return;
    }
    if (--file->references == 0) {
        file->used = 0;
        file->ops = 0;
    }
    mutex_unlock(&vfs_lock);
}

uint32_t t113_vfs_file_size(const struct vfs_file *file)
{
    mutex_lock(&vfs_lock);
    uint32_t size = file && file->used ? file->node.size : 0;
    mutex_unlock(&vfs_lock);
    return size;
}

uint32_t t113_vfs_file_offset(const struct vfs_file *file)
{
    mutex_lock(&vfs_lock);
    uint32_t offset = file && file->used ? file->offset : 0;
    mutex_unlock(&vfs_lock);
    return offset;
}

int t113_vfs_readdir(const char *path, uint32_t index,
                     struct vfs_dirent *entry)
{
    if (!path || path[0] != '/' || !entry)
        return -1;
    mutex_lock(&vfs_lock);
    const struct vfs_mount *mount = 0;
    uint32_t best = 0;
    for (uint32_t i = 0; i < mount_count; ++i) {
        uint32_t length = path_length(mounts[i].path);
        if (length >= best && mount_matches(path, mounts[i].path, length)) {
            mount = &mounts[i];
            best = length;
        }
    }
    int result = (!mount || !mount->ops->readdir)
               ? -1 : mount->ops->readdir(path, index, entry);
    mutex_unlock(&vfs_lock);
    return result;
}
