#include "fs/devfs.h"
#include "fs/chrdev.h"
#include "fs/vfs.h"
#include "mutex.h"

#define DEVFS_MAX_NODES 16u
#define DEVFS_NAME_MAX  30u

struct devfs_node {
    int used;
    char name[DEVFS_NAME_MAX + 1u];
    uint16_t major;
    uint16_t minor;
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

static const struct inode_operations devfs_iops;
static const struct file_operations devfs_dir_fops;

static int devfs_lookup(struct inode *directory, struct dentry *child)
{
    (void)directory;
    int result = -1;
    mutex_lock(&devfs_lock);
    for (uint32_t i = 0; i < DEVFS_MAX_NODES; ++i) {
        if (nodes[i].used && name_equal(nodes[i].name, child->d_name)) {
            uint32_t dev = MINIOS_MKDEV(nodes[i].major, nodes[i].minor);
            result = t113_vfs_bind_inode(child, dev, 0, DEVFS_T_CHAR, dev,
                                          &nodes[i], &devfs_iops,
                                          t113_chrdev_inode_fops());
            break;
        }
    }
    mutex_unlock(&devfs_lock);
    return result;
}

static int devfs_readdir(struct inode *inode, const char *path, uint32_t index,
                         struct vfs_dirent *entry)
{
    (void)inode;
    (void)path;
    mutex_lock(&devfs_lock);
    uint32_t seen = 0;
    for (uint32_t i = 0; i < DEVFS_MAX_NODES; ++i) {
        if (!nodes[i].used)
            continue;
        if (seen++ != index)
            continue;
        entry->id = MINIOS_MKDEV(nodes[i].major, nodes[i].minor);
        entry->type = DEVFS_T_CHAR;
        entry->size = 0;
        uint32_t n = 0;
        while (nodes[i].name[n]) {
            entry->name[n] = nodes[i].name[n];
            ++n;
        }
        entry->name[n] = 0;
        mutex_unlock(&devfs_lock);
        return 1;
    }
    mutex_unlock(&devfs_lock);
    return 0;
}

static const struct inode_operations devfs_iops = {
    .lookup = devfs_lookup,
};

static const struct file_operations devfs_dir_fops = {
    .readdir = devfs_readdir,
};

int t113_devfs_init(void)
{
    mutex_init(&devfs_lock);
    for (uint32_t i = 0; i < DEVFS_MAX_NODES; ++i)
        nodes[i].used = 0;
    return t113_vfs_mount_fs("/dev", 0x1373u, nodes, 0,
                             &devfs_iops, &devfs_dir_fops);
}

int t113_devfs_create_chrdev(const char *name, uint16_t major,
                             uint16_t minor)
{
    if (!name)
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
        nodes[i].used = 1;
        mutex_unlock(&devfs_lock);
        return 0;
    }
    mutex_unlock(&devfs_lock);
    return -1;
}
