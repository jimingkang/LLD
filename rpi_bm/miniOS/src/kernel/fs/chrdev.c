#include "fs/chrdev.h"
#include "mutex.h"

#define CHRDEV_MAX 32u

struct chrdev_entry {
    uint32_t dev;
    const struct file_operations *fops;
    uint32_t used;
};

static struct chrdev_entry chrdev_table[CHRDEV_MAX];
static struct mutex chrdev_lock;

void t113_chrdev_init(void)
{
    mutex_init(&chrdev_lock);
    for (uint32_t i = 0; i < CHRDEV_MAX; ++i)
        chrdev_table[i].used = 0;
}

int t113_chrdev_register(uint16_t major, uint16_t minor,
                         const struct file_operations *fops)
{
    uint32_t dev = MINIOS_MKDEV(major, minor);
    if (!fops || (!fops->read && !fops->write))
        return -1;

    mutex_lock(&chrdev_lock);
    for (uint32_t i = 0; i < CHRDEV_MAX; ++i) {
        if (chrdev_table[i].used && chrdev_table[i].dev == dev) {
            mutex_unlock(&chrdev_lock);
            return -1;
        }
    }
    for (uint32_t i = 0; i < CHRDEV_MAX; ++i) {
        if (chrdev_table[i].used)
            continue;
        chrdev_table[i].dev = dev;
        chrdev_table[i].fops = fops;
        chrdev_table[i].used = 1;
        mutex_unlock(&chrdev_lock);
        return 0;
    }
    mutex_unlock(&chrdev_lock);
    return -1;
}

static const struct file_operations *chrdev_find(uint32_t dev)
{
    const struct file_operations *fops = 0;
    mutex_lock(&chrdev_lock);
    for (uint32_t i = 0; i < CHRDEV_MAX; ++i) {
        if (chrdev_table[i].used && chrdev_table[i].dev == dev) {
            fops = chrdev_table[i].fops;
            break;
        }
    }
    mutex_unlock(&chrdev_lock);
    return fops;
}

static int chrdev_open(struct inode *inode, struct file *file)
{
    const struct file_operations *fops = chrdev_find(inode->i_rdev);
    if (!fops)
        return -1;
    file->f_op = fops;
    if (fops->open && fops->open(inode, file) < 0) {
        file->f_op = t113_chrdev_inode_fops();
        return -1;
    }
    return 0;
}

static const struct file_operations def_chr_fops = {
    .open = chrdev_open,
};

const struct file_operations *t113_chrdev_inode_fops(void)
{
    return &def_chr_fops;
}
