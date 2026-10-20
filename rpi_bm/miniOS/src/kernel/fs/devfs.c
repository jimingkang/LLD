#include "fs/devfs.h"
#include "fs/vfs.h"
#include "mutex.h"

#define DEVFS_MAX_NODES 16u
#define DEVFS_NAME_MAX  30u

struct devfs_node {
    int used;
    char name[DEVFS_NAME_MAX + 1u];
    uint16_t major;
    uint16_t minor;
    const struct devfs_file_ops *ops;
};

static struct devfs_node nodes[DEVFS_MAX_NODES];
static struct mutex devfs_lock;

static int name_equal(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return *a == *b;
}

static int copy_name(char destination[DEVFS_NAME_MAX + 1u],
                     const char *source)
{
    uint32_t i = 0;
    while (source[i] && i < DEVFS_NAME_MAX) {
        if (source[i] == '/')
            return -1;
        destination[i] = source[i];
        ++i;
    }
    if (!i || source[i])
        return -1;
    destination[i] = 0;
    return 0;
}

static const char *devfs_basename(const char *path)
{
    if (path[0] != '/' || path[1] != 'd' || path[2] != 'e' ||
        path[3] != 'v')
        return 0;
    if (path[4] == 0)
        return path + 4;
    if (path[4] != '/' || path[5] == 0)
        return 0;
    return path + 5;
}

static int devfs_open(const struct vfs_node *node, uint32_t flags)
{
    (void)node;
    return flags == VFS_O_RDONLY || flags == VFS_O_RDWR ? 0 : -1;
}

static int devfs_lookup(const char *path, struct vfs_node *result)
{
    const char *name = devfs_basename(path);
    if (!name)
        return -1;
    if (!*name) {
        result->id = 0;
        result->size = 0;
        result->type = 1u;
        result->private_data = 0;
        return 0;
    }
    for (uint32_t i = 0; i < DEVFS_MAX_NODES; ++i) {
        if (nodes[i].used && name_equal(nodes[i].name, name)) {
            result->id = ((uint32_t)nodes[i].major << 16) | nodes[i].minor;
            result->size = 0;
            result->type = DEVFS_T_CHAR;
            result->private_data = &nodes[i];
            return 0;
        }
    }
    return -1;
}

static int devfs_read(const struct vfs_node *node, uint32_t offset,
                      void *destination, uint32_t count)
{
    (void)offset;
    struct devfs_node *device = (struct devfs_node *)node->private_data;
    return device && device->ops && device->ops->read
         ? device->ops->read(destination, count) : -1;
}

static int devfs_write(const struct vfs_node *node, uint32_t offset,
                       const void *source, uint32_t count)
{
    (void)offset;
    struct devfs_node *device = (struct devfs_node *)node->private_data;
    return device && device->ops && device->ops->write
         ? device->ops->write(source, count) : -1;
}

static int devfs_readdir(const char *path, uint32_t index,
                         struct vfs_dirent *entry)
{
    const char *name = devfs_basename(path);
    if (!name || *name)
        return -1;
    uint32_t seen = 0;
    for (uint32_t i = 0; i < DEVFS_MAX_NODES; ++i) {
        if (!nodes[i].used)
            continue;
        if (seen++ != index)
            continue;
        entry->id = ((uint32_t)nodes[i].major << 16) | nodes[i].minor;
        entry->type = DEVFS_T_CHAR;
        entry->size = 0;
        uint32_t n = 0;
        while (nodes[i].name[n]) {
            entry->name[n] = nodes[i].name[n];
            ++n;
        }
        entry->name[n] = 0;
        return 1;
    }
    return 0;
}

static const struct vfs_backend_ops devfs_ops = {
    .open = devfs_open,
    .lookup = devfs_lookup,
    .read = devfs_read,
    .write = devfs_write,
    .readdir = devfs_readdir,
};

int t113_devfs_init(void)
{
    mutex_init(&devfs_lock);
    for (uint32_t i = 0; i < DEVFS_MAX_NODES; ++i)
        nodes[i].used = 0;
    return t113_vfs_mount("/dev", &devfs_ops);
}

int t113_devfs_register_chrdev(const char *name, uint16_t major,
                               uint16_t minor,
                               const struct devfs_file_ops *ops)
{
    if (!name || !ops || (!ops->read && !ops->write))
        return -1;
    mutex_lock(&devfs_lock);
    for (uint32_t i = 0; i < DEVFS_MAX_NODES; ++i) {
        if (nodes[i].used && name_equal(nodes[i].name, name)) {
            mutex_unlock(&devfs_lock);
            return -1;
        }
    }
    for (uint32_t i = 0; i < DEVFS_MAX_NODES; ++i) {
        if (nodes[i].used)
            continue;
        if (copy_name(nodes[i].name, name) < 0) {
            mutex_unlock(&devfs_lock);
            return -1;
        }
        nodes[i].major = major;
        nodes[i].minor = minor;
        nodes[i].ops = ops;
        nodes[i].used = 1;
        mutex_unlock(&devfs_lock);
        return 0;
    }
    mutex_unlock(&devfs_lock);
    return -1;
}
