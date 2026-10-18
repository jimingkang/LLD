#include "platform.h"
#include "fs/vfs.h"
#include "fs/minifs.h"

static const uint8_t *minifs_image;
static uint32_t fs_bytes;
static struct minifs_superblock fs_sb;

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
    if (block >= fs_sb.size || offset > fs_bytes - MINIFS_BSIZE)
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

static const struct vfs_backend_ops minifs_vfs_ops = {
    .lookup = minifs_vfs_lookup,
    .read = minifs_vfs_read,
};

int t113_minifs_mount_vfs(const void *image, uint32_t bytes)
{
    if (t113_minifs_mount(image, bytes) < 0)
        return -1;
    return t113_vfs_mount("/", &minifs_vfs_ops);
}
