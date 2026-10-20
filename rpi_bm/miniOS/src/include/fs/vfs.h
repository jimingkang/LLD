#ifndef MINIOS_FS_VFS_H
#define MINIOS_FS_VFS_H

#include <stdint.h>
#include "mutex.h"

#define VFS_O_RDONLY 0u
#define VFS_O_RDWR   2u
#define VFS_O_ACCMODE 3u
#define VFS_O_CREATE 0x200u      /* xv6 fcntl.h values */
#define VFS_O_TRUNC  0x400u

#define VFS_NODE_DIR  1u
#define VFS_NODE_FILE 2u
#define VFS_NODE_CHAR 3u

#define VFS_NAME_MAX 30u
#define VFS_PATH_MAX 128u

struct super_block;
struct inode;
struct dentry;
struct file;
struct vfs_mount;

struct vfs_dirent {
    uint32_t id;
    uint32_t type;
    uint32_t size;
    char name[VFS_NAME_MAX + 1u];
};

struct super_operations {
    void (*put_super)(struct super_block *sb);
    void (*evict_inode)(struct inode *inode);
};

struct inode_operations {
    int (*lookup)(struct inode *directory, struct dentry *child);
    int (*create)(struct inode *directory, struct dentry *child);
    int (*truncate)(struct inode *inode);
};

struct file_operations {
    int (*open)(struct inode *inode, struct file *file);
    int (*read)(struct file *file, void *destination, uint32_t count);
    int (*write)(struct file *file, const void *source, uint32_t count);
    int (*readdir)(struct inode *inode, const char *path, uint32_t index,
                   struct vfs_dirent *entry);
    void (*release)(struct inode *inode, struct file *file);
};

struct super_block {
    uint32_t used;
    uint32_t references;
    uint32_t s_magic;
    const struct super_operations *s_op;
    struct dentry *s_root;
    void *s_fs_info;
};

struct inode {
    uint32_t used;
    uint32_t references;
    uint32_t i_ino;
    uint32_t i_size;
    uint32_t i_type;
    uint32_t i_rdev;
    struct super_block *i_sb;
    const struct inode_operations *i_op;
    const struct file_operations *i_fop;
    void *i_private;
};

struct dentry {
    uint32_t used;
    uint32_t references;
    char d_name[VFS_NAME_MAX + 1u];
    char d_path[VFS_PATH_MAX];
    struct dentry *d_parent;
    struct inode *d_inode;
    struct super_block *d_sb;
};

struct file {
    uint32_t used;
    uint32_t references;
    uint32_t f_flags;
    uint32_t f_pos;
    struct dentry *f_dentry;
    struct inode *f_inode;
    const struct file_operations *f_op;
    void *private_data;
    struct mutex f_pos_lock;
};

struct vfs_mount {
    uint32_t used;
    char path[VFS_PATH_MAX];
    struct super_block *sb;
    struct dentry *mnt_root;
    struct vfs_mount *parent;
    struct dentry *mountpoint;
};

void t113_vfs_init(void);
int t113_vfs_mount_fs(const char *path, uint32_t magic, void *fs_info,
                      const struct super_operations *s_op,
                      const struct inode_operations *root_iop,
                      const struct file_operations *root_fop);
int t113_vfs_bind_inode(struct dentry *dentry, uint32_t ino, uint32_t size,
                        uint32_t type, uint32_t rdev, void *private_data,
                        const struct inode_operations *i_op,
                        const struct file_operations *i_fop);
struct file *t113_vfs_open(const char *path, uint32_t flags);
int t113_vfs_read(struct file *file, void *destination, uint32_t count);
int t113_vfs_write(struct file *file, const void *source, uint32_t count);
void t113_vfs_file_get(struct file *file);
void t113_vfs_close(struct file *file);
uint32_t t113_vfs_file_size(const struct file *file);
uint32_t t113_vfs_file_offset(const struct file *file);
int t113_vfs_readdir(const char *path, uint32_t index,
                     struct vfs_dirent *entry);

#endif
