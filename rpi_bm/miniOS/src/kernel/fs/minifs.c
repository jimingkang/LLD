#include "platform.h"
#include "fs/vfs.h"
#include "fs/minifs.h"
#include "fs/rootdev.h"

static const uint8_t *minifs_image;
static uint32_t fs_bytes;
static struct minifs_superblock fs_sb;
static int block_backed;
static uint8_t block_cache[MINIFS_BSIZE] __attribute__((aligned(4)));
static uint32_t cached_block;
static int cache_valid;
static const struct vfs_backend_ops minifs_vfs_ops;

static void copy_bytes(void *destination, const void *source, uint32_t bytes)
{
    uint8_t *dst = (uint8_t *)destination;
    const uint8_t *src = (const uint8_t *)source;
    for (uint32_t i = 0; i < bytes; ++i)
        dst[i] = src[i];
}

static int names_equal(const char disk_name[MINIFS_DIRSIZ],
                       const char *component, uint32_t length)
{
    if (length > MINIFS_DIRSIZ)
        return 0;
    for (uint32_t i = 0; i < length; ++i)
        if (disk_name[i] != component[i])
            return 0;
    return length == MINIFS_DIRSIZ || disk_name[length] == 0;
}

static const uint8_t *block_address(uint32_t block)
{
    uint32_t offset = block * MINIFS_BSIZE;
    if (block >= fs_sb.size)
        return 0;
    if (block_backed) {
        if (cache_valid && cached_block == block)
            return block_cache;
        if (t113_rootdev_read(block * 2u, 2u, block_cache) < 0)
            return 0;
        cached_block = block;
        cache_valid = 1;
        return block_cache;
    }
    if (offset > fs_bytes - MINIFS_BSIZE)
        return 0;
    return minifs_image + offset;
}

static int read_inode(uint32_t inum, struct minifs_dinode *inode)
{
    uint32_t per_block = MINIFS_BSIZE / sizeof(struct minifs_dinode);
    if (inum == 0 || inum >= fs_sb.ninodes)
        return -1;
    const uint8_t *block = block_address(fs_sb.inodestart + inum / per_block);
    if (!block)
        return -1;
    *inode = ((const struct minifs_dinode *)block)[inum % per_block];
    return 0;
}

static uint32_t inode_block(const struct minifs_dinode *inode, uint32_t index)
{
    if (index < MINIFS_NDIRECT)
        return inode->addrs[index];
    index -= MINIFS_NDIRECT;
    if (index >= MINIFS_NINDIRECT || !inode->addrs[MINIFS_NDIRECT])
        return 0;
    const uint32_t *indirect =
        (const uint32_t *)block_address(inode->addrs[MINIFS_NDIRECT]);
    return indirect ? indirect[index] : 0;
}

static int inode_read(const struct minifs_dinode *inode, uint32_t offset,
                      void *destination, uint32_t count)
{
    if (offset > inode->size || count > inode->size - offset)
        return -1;
    uint8_t *dst = (uint8_t *)destination;
    while (count) {
        uint32_t block_index = offset / MINIFS_BSIZE;
        uint32_t block_offset = offset % MINIFS_BSIZE;
        uint32_t chunk = MINIFS_BSIZE - block_offset;
        if (chunk > count)
            chunk = count;
        const uint8_t *block = block_address(inode_block(inode, block_index));
        if (!block)
            return -1;
        copy_bytes(dst, block + block_offset, chunk);
        dst += chunk;
        offset += chunk;
        count -= chunk;
    }
    return 0;
}

static int directory_lookup(uint32_t directory_inum, const char *name,
                            uint32_t length, uint32_t *result)
{
    struct minifs_dinode directory;
    struct minifs_dirent entry;
    if (read_inode(directory_inum, &directory) < 0 ||
        directory.type != MINIFS_T_DIR)
        return -1;
    for (uint32_t offset = 0;
         offset + sizeof(entry) <= directory.size;
         offset += sizeof(entry)) {
        if (inode_read(&directory, offset, &entry, sizeof(entry)) < 0)
            return -1;
        if (entry.inum && names_equal(entry.name, name, length)) {
            *result = entry.inum;
            return 0;
        }
    }
    return -1;
}

static int namei(const char *path, uint32_t *inum)
{
    uint32_t current = MINIFS_ROOTINO;
    while (*path == '/')
        ++path;
    while (*path) {
        const char *begin = path;
        while (*path && *path != '/')
            ++path;
        if (directory_lookup(current, begin, (uint32_t)(path - begin),
                             &current) < 0)
            return -1;
        while (*path == '/')
            ++path;
    }
    *inum = current;
    return 0;
}

int t113_minifs_mount(const void *image, uint32_t bytes)
{
    if (!image || bytes < 2u * MINIFS_BSIZE)
        return -1;
    minifs_image = (const uint8_t *)image;
    fs_bytes = bytes;
    block_backed = 0;
    cache_valid = 0;
    copy_bytes(&fs_sb, minifs_image + MINIFS_BSIZE, sizeof(fs_sb));
    if (fs_sb.magic != MINIFS_MAGIC ||
        fs_sb.size > fs_bytes / MINIFS_BSIZE)
        return -1;
    t113_uart_puts("minifs: mounted embedded image blocks=");
    t113_uart_puthex(fs_sb.size);
    t113_uart_puts(" inodes=");
    t113_uart_puthex(fs_sb.ninodes);
    t113_uart_putc('\n');
    return 0;
}

int t113_minifs_mount_rootdev(void)
{
    if (t113_rootdev_init() < 0 ||
        t113_rootdev_read(2u, 2u, block_cache) < 0)
        return -1;
    copy_bytes(&fs_sb, block_cache, sizeof(fs_sb));
    if (fs_sb.magic != MINIFS_MAGIC ||
        fs_sb.size * 2u > t113_rootdev_sectors())
        return -1;
    minifs_image = 0;
    fs_bytes = fs_sb.size * MINIFS_BSIZE;
    block_backed = 1;
    cached_block = 1u;
    cache_valid = 1;
    t113_uart_puts("minifs: mounted block rootfs blocks=");
    t113_uart_puthex(fs_sb.size);
    t113_uart_puts(" inodes="); t113_uart_puthex(fs_sb.ninodes);
    t113_uart_putc('\n');
    return t113_vfs_mount("/", &minifs_vfs_ops);
}

int t113_minifs_read_file(const char *path, void *destination,
                         uint32_t capacity)
{
    uint32_t inum;
    struct minifs_dinode inode;
    if (namei(path, &inum) < 0 || read_inode(inum, &inode) < 0 ||
        inode.type != MINIFS_T_FILE || inode.size > capacity)
        return -1;
    if (inode_read(&inode, 0, destination, inode.size) < 0)
        return -1;
    t113_uart_puts("minifs: loaded ");
    t113_uart_puts(path);
    t113_uart_puts(" bytes=");
    t113_uart_puthex(inode.size);
    t113_uart_putc('\n');
    return (int)inode.size;
}

int t113_minifs_open(const char *path, uint32_t *inum, uint32_t *size)
{
    struct minifs_dinode inode;
    uint32_t number;
    if (!path || !inum || !size || namei(path, &number) < 0 ||
        read_inode(number, &inode) < 0 || inode.type != MINIFS_T_FILE)
        return -1;
    *inum = number;
    *size = inode.size;
    return 0;
}

int t113_minifs_read(uint32_t inum, uint32_t offset, void *destination,
                    uint32_t count)
{
    struct minifs_dinode inode;
    if (read_inode(inum, &inode) < 0 || inode.type != MINIFS_T_FILE ||
        offset > inode.size)
        return -1;
    if (count > inode.size - offset)
        count = inode.size - offset;
    if (inode_read(&inode, offset, destination, count) < 0)
        return -1;
    return (int)count;
}

int t113_minifs_list(const char *path, t113_minifs_emit_fn emit,
                     void *argument)
{
    uint32_t inum;
    struct minifs_dinode directory;
    struct minifs_dirent entry;
    if (!path || !emit || namei(path, &inum) < 0 ||
        read_inode(inum, &directory) < 0 ||
        directory.type != MINIFS_T_DIR)
        return -1;

    for (uint32_t offset = 0;
         offset + sizeof(entry) <= directory.size;
         offset += sizeof(entry)) {
        struct minifs_dinode child;
        uint32_t length = 0;
        if (inode_read(&directory, offset, &entry, sizeof(entry)) < 0)
            return -1;
        if (!entry.inum)
            continue;
        while (length < MINIFS_DIRSIZ && entry.name[length])
            ++length;
        if (read_inode(entry.inum, &child) < 0)
            return -1;
        emit(entry.name, length, entry.inum, (uint32_t)child.type,
             child.size, argument);
    }
    return 0;
}

int t113_minifs_readdir(const char *path, uint32_t index,
                        struct t113_minifs_user_dirent *result)
{
    uint32_t inum, seen = 0;
    struct minifs_dinode directory;
    struct minifs_dirent entry;
    if (!path || !result || namei(path, &inum) < 0 ||
        read_inode(inum, &directory) < 0 ||
        directory.type != MINIFS_T_DIR)
        return -1;
    for (uint32_t offset = 0;
         offset + sizeof(entry) <= directory.size;
         offset += sizeof(entry)) {
        struct minifs_dinode child;
        if (inode_read(&directory, offset, &entry, sizeof(entry)) < 0)
            return -1;
        if (!entry.inum)
            continue;
        if (seen++ != index)
            continue;
        if (read_inode(entry.inum, &child) < 0)
            return -1;
        result->inum = entry.inum;
        result->type = (uint32_t)child.type;
        result->size = child.size;
        uint32_t i = 0;
        while (i < MINIFS_DIRSIZ && entry.name[i]) {
            result->name[i] = entry.name[i];
            ++i;
        }
        result->name[i] = 0;
        return 1;
    }
    return 0;
}

static int minifs_vfs_lookup(const char *path, struct vfs_node *node)
{
    uint32_t inum, size;
    if (t113_minifs_open(path, &inum, &size) < 0)
        return -1;
    node->id = inum;
    node->size = size;
    node->type = MINIFS_T_FILE;
    return 0;
}

static int minifs_vfs_read(const struct vfs_node *node, uint32_t offset,
                        void *destination, uint32_t count)
{
    return t113_minifs_read(node->id, offset, destination, count);
}

static int minifs_vfs_readdir(const char *path, uint32_t index,
                              struct vfs_dirent *entry)
{
    struct t113_minifs_user_dirent minifs_entry;
    int result = t113_minifs_readdir(path, index, &minifs_entry);
    if (result > 0) {
        entry->id = minifs_entry.inum;
        entry->type = minifs_entry.type;
        entry->size = minifs_entry.size;
        for (uint32_t i = 0; i < sizeof(entry->name); ++i)
            entry->name[i] = minifs_entry.name[i];
    }
    return result;
}

static const struct vfs_backend_ops minifs_vfs_ops = {
    .lookup = minifs_vfs_lookup,
    .read = minifs_vfs_read,
    .readdir = minifs_vfs_readdir,
};

int t113_minifs_mount_vfs(const void *image, uint32_t bytes)
{
    if (t113_minifs_mount(image, bytes) < 0)
        return -1;
    return t113_vfs_mount("/", &minifs_vfs_ops);
}
