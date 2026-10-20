/* Linux-style VFS object core: mount, super_block, dentry, inode and file. */
#include "fs/vfs.h"

#define VFS_OPEN_FILES 32u
#define VFS_MOUNTS      8u
#define VFS_SUPERS      8u
#define VFS_INODES    128u
#define VFS_DENTRIES  128u

static struct vfs_mount mounts[VFS_MOUNTS];
static struct super_block super_blocks[VFS_SUPERS];
static struct inode inode_cache[VFS_INODES];
static struct dentry dentry_cache[VFS_DENTRIES];
static struct file open_files[VFS_OPEN_FILES];
static struct mutex vfs_lock;

static const struct super_operations default_sops;

static uint32_t text_length(const char *text)
{
    uint32_t length = 0;
    while (text[length])
        ++length;
    return length;
}

static int text_equal(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return *a == *b;
}

static int text_copy(char *destination, uint32_t capacity,
                     const char *source)
{
    uint32_t i = 0;
    if (!capacity)
        return -1;
    while (source[i] && i + 1u < capacity) {
        destination[i] = source[i];
        ++i;
    }
    if (source[i])
        return -1;
    destination[i] = 0;
    return 0;
}

static int path_prefix(const char *path, const char *prefix)
{
    while (*prefix && *path == *prefix) { ++path; ++prefix; }
    return *prefix == 0;
}

static int mount_matches(const char *path, const char *mount_path,
                         uint32_t length)
{
    if (!path_prefix(path, mount_path))
        return 0;
    if (length == 1u && mount_path[0] == '/')
        return 1;
    return path[length] == 0 || path[length] == '/';
}

static struct vfs_mount *find_mount(const char *path)
{
    struct vfs_mount *match = 0;
    uint32_t best = 0;
    for (uint32_t i = 0; i < VFS_MOUNTS; ++i) {
        if (!mounts[i].used)
            continue;
        uint32_t length = text_length(mounts[i].path);
        if (length >= best && mount_matches(path, mounts[i].path, length)) {
            match = &mounts[i];
            best = length;
        }
    }
    return match;
}

static struct super_block *alloc_super(void)
{
    for (uint32_t i = 0; i < VFS_SUPERS; ++i) {
        if (super_blocks[i].used)
            continue;
        struct super_block *sb = &super_blocks[i];
        sb->used = 1;
        sb->references = 1;       /* reference owned by vfs_mount */
        sb->s_magic = 0;
        sb->s_op = &default_sops;
        sb->s_root = 0;
        sb->s_fs_info = 0;
        return sb;
    }
    return 0;
}

static struct inode *find_inode(struct super_block *sb, uint32_t ino)
{
    for (uint32_t i = 0; i < VFS_INODES; ++i)
        if (inode_cache[i].used && inode_cache[i].i_sb == sb &&
            inode_cache[i].i_ino == ino)
            return &inode_cache[i];
    return 0;
}

static struct inode *alloc_inode(struct super_block *sb, uint32_t ino,
                                 uint32_t size, uint32_t type, uint32_t rdev,
                                 void *private_data,
                                 const struct inode_operations *i_op,
                                 const struct file_operations *i_fop)
{
    struct inode *cached = find_inode(sb, ino);
    if (cached) {
        ++cached->references;
        /* A filesystem lookup may have acquired a temporary private inode
         * reference before discovering that the VFS inode is cached. */
        if (private_data && sb->s_op && sb->s_op->evict_inode) {
            struct inode temporary;
            temporary.i_sb = sb;
            temporary.i_ino = ino;
            temporary.i_size = size;
            temporary.i_type = type;
            temporary.i_rdev = rdev;
            temporary.i_private = private_data;
            sb->s_op->evict_inode(&temporary);
        }
        return cached;
    }
    for (uint32_t i = 0; i < VFS_INODES; ++i) {
        if (inode_cache[i].used)
            continue;
        struct inode *inode = &inode_cache[i];
        inode->used = 1;
        inode->references = 1;    /* reference owned by dentry */
        inode->i_ino = ino;
        inode->i_size = size;
        inode->i_type = type;
        inode->i_rdev = rdev;
        inode->i_sb = sb;
        inode->i_op = i_op;
        inode->i_fop = i_fop;
        inode->i_private = private_data;
        ++sb->references;
        return inode;
    }
    return 0;
}

static void iput(struct inode *inode)
{
    if (!inode || !inode->used || !inode->references)
        return;
    if (--inode->references)
        return;
    if (inode->i_sb->s_op && inode->i_sb->s_op->evict_inode)
        inode->i_sb->s_op->evict_inode(inode);
    if (inode->i_sb->references)
        --inode->i_sb->references;
    inode->used = 0;
}

static struct dentry *find_dentry(struct super_block *sb, const char *path)
{
    for (uint32_t i = 0; i < VFS_DENTRIES; ++i)
        if (dentry_cache[i].used && dentry_cache[i].d_sb == sb &&
            text_equal(dentry_cache[i].d_path, path))
            return &dentry_cache[i];
    return 0;
}

static struct dentry *alloc_dentry(struct super_block *sb,
                                   struct dentry *parent,
                                   const char *name, const char *path)
{
    struct dentry *cached = find_dentry(sb, path);
    if (cached) {
        ++cached->references;
        return cached;
    }
    for (uint32_t i = 0; i < VFS_DENTRIES; ++i) {
        if (dentry_cache[i].used)
            continue;
        struct dentry *dentry = &dentry_cache[i];
        if (text_copy(dentry->d_name, sizeof(dentry->d_name), name) < 0 ||
            text_copy(dentry->d_path, sizeof(dentry->d_path), path) < 0)
            return 0;
        dentry->used = 1;
        dentry->references = 1;
        dentry->d_parent = parent;
        dentry->d_inode = 0;
        dentry->d_sb = sb;
        if (parent)
            ++parent->references;
        return dentry;
    }
    return 0;
}

static void dput(struct dentry *dentry)
{
    if (!dentry || !dentry->used || !dentry->references)
        return;
    if (--dentry->references)
        return;
    struct dentry *parent = dentry->d_parent;
    iput(dentry->d_inode);
    dentry->used = 0;
    dentry->d_parent = 0;
    dentry->d_inode = 0;
    if (parent)
        dput(parent);
}

static int append_component(char path[VFS_PATH_MAX], const char *name,
                            uint32_t length)
{
    uint32_t used = text_length(path);
    if (used > 1u && path[used - 1u] != '/') {
        if (used + 1u >= VFS_PATH_MAX)
            return -1;
        path[used++] = '/';
    } else if (!used) {
        path[used++] = '/';
    }
    if (used + length >= VFS_PATH_MAX)
        return -1;
    for (uint32_t i = 0; i < length; ++i)
        path[used++] = name[i];
    path[used] = 0;
    return 0;
}

/* Walk one component at a time and build a dentry/inode chain.  The owning
 * filesystem resolves each child through the parent inode's i_op table. */
static struct dentry *lookup_path(const char *path)
{
    struct vfs_mount *mount = find_mount(path);
    if (!mount)
        return 0;
    struct dentry *current = mount->mnt_root;
    ++current->references;

    uint32_t mount_length = text_length(mount->path);
    const char *cursor = path + mount_length;
    while (*cursor == '/')
        ++cursor;
    char absolute[VFS_PATH_MAX];
    if (text_copy(absolute, sizeof(absolute), mount->path) < 0) {
        dput(current);
        return 0;
    }

    while (*cursor) {
        const char *name = cursor;
        uint32_t length = 0;
        while (cursor[length] && cursor[length] != '/')
            ++length;
        if (!length || length > VFS_NAME_MAX ||
            append_component(absolute, name, length) < 0) {
            dput(current);
            return 0;
        }
        char component[VFS_NAME_MAX + 1u];
        for (uint32_t i = 0; i < length; ++i)
            component[i] = name[i];
        component[length] = 0;
        struct dentry *child = alloc_dentry(mount->sb, current,
                                            component, absolute);
        if (!child) {
            dput(current);
            return 0;
        }
        if (!child->d_inode && current->d_inode->i_op->lookup(
                current->d_inode, child) < 0) {
            dput(child);
            dput(current);
            return 0;
        }
        dput(current);
        current = child;
        cursor += length;
        while (*cursor == '/')
            ++cursor;
    }
    return current;
}

static int split_parent(const char *path, char parent[VFS_PATH_MAX],
                        char name[VFS_NAME_MAX + 1u])
{
    uint32_t length = text_length(path);
    while (length > 1u && path[length - 1u] == '/')
        --length;
    uint32_t slash = length;
    while (slash && path[slash - 1u] != '/')
        --slash;
    uint32_t name_length = length - slash;
    if (!name_length || name_length > VFS_NAME_MAX)
        return -1;
    for (uint32_t i = 0; i < name_length; ++i)
        name[i] = path[slash + i];
    name[name_length] = 0;
    uint32_t parent_length = slash > 1u ? slash - 1u : 1u;
    for (uint32_t i = 0; i < parent_length; ++i)
        parent[i] = path[i];
    parent[parent_length] = 0;
    return 0;
}

static struct dentry *create_path(const char *path)
{
    char parent_path[VFS_PATH_MAX], name[VFS_NAME_MAX + 1u];
    if (split_parent(path, parent_path, name) < 0)
        return 0;
    struct dentry *parent = lookup_path(parent_path);
    if (!parent || parent->d_inode->i_type != VFS_NODE_DIR) {
        dput(parent);
        return 0;
    }
    struct dentry *child = alloc_dentry(parent->d_sb, parent, name, path);
    if (!child || !parent->d_inode->i_op->create ||
        parent->d_inode->i_op->create(parent->d_inode, child) < 0) {
        dput(child);
        dput(parent);
        return 0;
    }
    dput(parent);
    return child;
}

static const struct super_operations default_sops = {
    .put_super = 0,
    .evict_inode = 0,
};

int t113_vfs_bind_inode(struct dentry *dentry, uint32_t ino, uint32_t size,
                        uint32_t type, uint32_t rdev, void *private_data,
                        const struct inode_operations *i_op,
                        const struct file_operations *i_fop)
{
    if (!dentry || !dentry->d_sb || !i_op || !i_fop)
        return -1;
    dentry->d_inode = alloc_inode(dentry->d_sb, ino, size, type, rdev,
                                  private_data, i_op, i_fop);
    if (!dentry->d_inode && private_data && dentry->d_sb->s_op &&
        dentry->d_sb->s_op->evict_inode) {
        struct inode temporary;
        temporary.i_sb = dentry->d_sb;
        temporary.i_ino = ino;
        temporary.i_size = size;
        temporary.i_type = type;
        temporary.i_rdev = rdev;
        temporary.i_private = private_data;
        dentry->d_sb->s_op->evict_inode(&temporary);
    }
    return dentry->d_inode ? 0 : -1;
}

void t113_vfs_init(void)
{
    mutex_init(&vfs_lock);
    for (uint32_t i = 0; i < VFS_MOUNTS; ++i) mounts[i].used = 0;
    for (uint32_t i = 0; i < VFS_SUPERS; ++i) super_blocks[i].used = 0;
    for (uint32_t i = 0; i < VFS_INODES; ++i) inode_cache[i].used = 0;
    for (uint32_t i = 0; i < VFS_DENTRIES; ++i) dentry_cache[i].used = 0;
    for (uint32_t i = 0; i < VFS_OPEN_FILES; ++i) open_files[i].used = 0;
}

int t113_vfs_mount_fs(const char *path, uint32_t magic, void *fs_info,
                      const struct super_operations *s_op,
                      const struct inode_operations *root_iop,
                      const struct file_operations *root_fop)
{
    if (!path || path[0] != '/' || !root_iop || !root_iop->lookup ||
        !root_fop)
        return -1;
    mutex_lock(&vfs_lock);
    struct vfs_mount *parent_mount = path[1] ? find_mount(path) : 0;
    struct dentry *mountpoint = path[1] ? lookup_path(path) : 0;
    if (path[1] && (!parent_mount || !mountpoint ||
                    mountpoint->d_inode->i_type != VFS_NODE_DIR)) {
        dput(mountpoint);
        mutex_unlock(&vfs_lock);
        return -1;
    }
    struct vfs_mount *mount = 0;
    for (uint32_t i = 0; i < VFS_MOUNTS; ++i) {
        if (mounts[i].used && text_equal(mounts[i].path, path)) {
            dput(mountpoint);
            mutex_unlock(&vfs_lock);
            return -1;
        }
        if (!mount && !mounts[i].used)
            mount = &mounts[i];
    }
    struct super_block *sb = alloc_super();
    if (!mount || !sb || text_copy(mount->path, sizeof(mount->path), path) < 0) {
        if (sb) sb->used = 0;
        dput(mountpoint);
        mutex_unlock(&vfs_lock);
        return -1;
    }
    sb->s_op = s_op ? s_op : &default_sops;
    sb->s_magic = magic;
    sb->s_fs_info = fs_info;
    struct inode *root_inode = alloc_inode(sb, 0, 0, VFS_NODE_DIR, 0, 0,
                                           root_iop, root_fop);
    struct dentry *root = alloc_dentry(sb, 0, path[1] ? path + 1 : "/", path);
    if (!root_inode || !root) {
        iput(root_inode);
        dput(root);
        sb->used = 0;
        dput(mountpoint);
        mutex_unlock(&vfs_lock);
        return -1;
    }
    root->d_inode = root_inode;
    sb->s_root = root;
    mount->used = 1;
    mount->sb = sb;
    mount->mnt_root = root;
    mount->parent = parent_mount;
    mount->mountpoint = mountpoint;
    mutex_unlock(&vfs_lock);
    return 0;
}

struct file *t113_vfs_open(const char *path, uint32_t flags)
{
    uint32_t mode = flags & VFS_O_ACCMODE;
    if (!path || path[0] != '/' ||
        (mode != VFS_O_RDONLY && mode != VFS_O_RDWR) ||
        (flags & ~(VFS_O_ACCMODE | VFS_O_CREATE | VFS_O_TRUNC)) ||
        ((flags & VFS_O_TRUNC) && mode != VFS_O_RDWR))
        return 0;
    mutex_lock(&vfs_lock);
    struct dentry *dentry = lookup_path(path);
    if (!dentry && (flags & VFS_O_CREATE))
        dentry = create_path(path);
    if (!dentry || !dentry->d_inode || dentry->d_inode->i_type == VFS_NODE_DIR) {
        dput(dentry);
        mutex_unlock(&vfs_lock);
        return 0;
    }
    struct inode *inode = dentry->d_inode;
    if ((flags & VFS_O_TRUNC) &&
        (!inode->i_op->truncate || inode->i_op->truncate(inode) < 0)) {
        dput(dentry);
        mutex_unlock(&vfs_lock);
        return 0;
    }
    for (uint32_t i = 0; i < VFS_OPEN_FILES; ++i) {
        struct file *file = &open_files[i];
        if (file->used)
            continue;
        file->used = 1;
        file->references = 1;
        file->f_flags = mode;
        file->f_pos = 0;
        file->f_dentry = dentry;
        file->f_inode = inode;
        file->f_op = inode->i_fop;
        file->private_data = 0;
        mutex_init(&file->f_pos_lock);
        if (!file->f_op ||
            (file->f_op->open && file->f_op->open(inode, file) < 0) ||
            !file->f_op->read ||
            (mode != VFS_O_RDONLY && !file->f_op->write)) {
            if (file->f_op && file->f_op->release)
                file->f_op->release(inode, file);
            file->used = 0;
            dput(dentry);
            mutex_unlock(&vfs_lock);
            return 0;
        }
        mutex_unlock(&vfs_lock);
        return file;
    }
    dput(dentry);
    mutex_unlock(&vfs_lock);
    return 0;
}

int t113_vfs_write(struct file *file, const void *source, uint32_t count)
{
    mutex_lock(&vfs_lock);
    if (!file || !file->used || file->f_flags != VFS_O_RDWR ||
        !file->f_op || !file->f_op->write) {
        mutex_unlock(&vfs_lock);
        return -1;
    }
    ++file->references;
    int positional = file->f_inode->i_type != VFS_NODE_CHAR;
    mutex_unlock(&vfs_lock);
    if (positional) mutex_lock(&file->f_pos_lock);
    int result = file->f_op->write(file, source, count);
    if (positional && result > 0) {
        file->f_pos += (uint32_t)result;
        if (file->f_pos > file->f_inode->i_size) {
            file->f_inode->i_size = file->f_pos;
        }
    }
    if (positional) mutex_unlock(&file->f_pos_lock);
    t113_vfs_close(file);
    return result;
}

int t113_vfs_read(struct file *file, void *destination, uint32_t count)
{
    mutex_lock(&vfs_lock);
    if (!file || !file->used || !file->f_op || !file->f_op->read) {
        mutex_unlock(&vfs_lock);
        return -1;
    }
    ++file->references;
    int positional = file->f_inode->i_type != VFS_NODE_CHAR;
    mutex_unlock(&vfs_lock);
    if (positional) mutex_lock(&file->f_pos_lock);
    int result = file->f_op->read(file, destination, count);
    if (positional && result > 0) file->f_pos += (uint32_t)result;
    if (positional) mutex_unlock(&file->f_pos_lock);
    t113_vfs_close(file);
    return result;
}

void t113_vfs_file_get(struct file *file)
{
    mutex_lock(&vfs_lock);
    if (file && file->used) ++file->references;
    mutex_unlock(&vfs_lock);
}

void t113_vfs_close(struct file *file)
{
    mutex_lock(&vfs_lock);
    if (!file || !file->used || !file->references) {
        mutex_unlock(&vfs_lock);
        return;
    }
    if (--file->references == 0) {
        if (file->f_op && file->f_op->release)
            file->f_op->release(file->f_inode, file);
        dput(file->f_dentry);
        file->used = 0;
        file->f_dentry = 0;
        file->f_inode = 0;
        file->f_op = 0;
        file->private_data = 0;
    }
    mutex_unlock(&vfs_lock);
}

uint32_t t113_vfs_file_size(const struct file *file)
{
    mutex_lock(&vfs_lock);
    if (!file || !file->used || !file->f_inode) {
        mutex_unlock(&vfs_lock);
        return 0;
    }
    ++((struct file *)file)->references;
    mutex_unlock(&vfs_lock);
    mutex_lock(&((struct file *)file)->f_pos_lock);
    uint32_t size = file->f_inode->i_size;
    mutex_unlock(&((struct file *)file)->f_pos_lock);
    t113_vfs_close((struct file *)file);
    return size;
}

uint32_t t113_vfs_file_offset(const struct file *file)
{
    mutex_lock(&vfs_lock);
    if (!file || !file->used) {
        mutex_unlock(&vfs_lock);
        return 0;
    }
    ++((struct file *)file)->references;
    mutex_unlock(&vfs_lock);
    mutex_lock(&((struct file *)file)->f_pos_lock);
    uint32_t offset = file->f_pos;
    mutex_unlock(&((struct file *)file)->f_pos_lock);
    t113_vfs_close((struct file *)file);
    return offset;
}

int t113_vfs_readdir(const char *path, uint32_t index,
                     struct vfs_dirent *entry)
{
    if (!path || path[0] != '/' || !entry)
        return -1;
    mutex_lock(&vfs_lock);
    struct dentry *dentry = lookup_path(path);
    int result = (!dentry || !dentry->d_inode ||
                  dentry->d_inode->i_type != VFS_NODE_DIR ||
                  !dentry->d_inode->i_fop->readdir)
               ? -1 : dentry->d_inode->i_fop->readdir(
                    dentry->d_inode, path, index, entry);
    dput(dentry);
    mutex_unlock(&vfs_lock);
    return result;
}
