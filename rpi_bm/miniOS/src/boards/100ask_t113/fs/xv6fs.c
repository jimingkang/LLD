#include "platform.h"
#include "xv6fs.h"

static const uint8_t *fs_image;
static uint32_t fs_bytes;
static struct xv6fs_superblock fs_sb;

static void copy_bytes(void *destination, const void *source, uint32_t bytes)
{
    uint8_t *dst = (uint8_t *)destination;
    const uint8_t *src = (const uint8_t *)source;
    for (uint32_t i = 0; i < bytes; ++i)
        dst[i] = src[i];
}

static int names_equal(const char disk_name[XV6FS_DIRSIZ],
                       const char *component, uint32_t length)
{
    if (length > XV6FS_DIRSIZ)
        return 0;
    for (uint32_t i = 0; i < length; ++i)
        if (disk_name[i] != component[i])
            return 0;
    return length == XV6FS_DIRSIZ || disk_name[length] == 0;
}

static const uint8_t *block_address(uint32_t block)
{
    uint32_t offset = block * XV6FS_BSIZE;
    if (block >= fs_sb.size || offset > fs_bytes - XV6FS_BSIZE)
        return 0;
    return fs_image + offset;
}

static int read_inode(uint32_t inum, struct xv6fs_dinode *inode)
{
    uint32_t per_block = XV6FS_BSIZE / sizeof(struct xv6fs_dinode);
    if (inum == 0 || inum >= fs_sb.ninodes)
        return -1;
    const uint8_t *block = block_address(fs_sb.inodestart + inum / per_block);
    if (!block)
        return -1;
    *inode = ((const struct xv6fs_dinode *)block)[inum % per_block];
    return 0;
}

static uint32_t inode_block(const struct xv6fs_dinode *inode, uint32_t index)
{
    if (index < XV6FS_NDIRECT)
        return inode->addrs[index];
    index -= XV6FS_NDIRECT;
    if (index >= XV6FS_NINDIRECT || !inode->addrs[XV6FS_NDIRECT])
        return 0;
    const uint32_t *indirect =
        (const uint32_t *)block_address(inode->addrs[XV6FS_NDIRECT]);
    return indirect ? indirect[index] : 0;
}

static int inode_read(const struct xv6fs_dinode *inode, uint32_t offset,
                      void *destination, uint32_t count)
{
    if (offset > inode->size || count > inode->size - offset)
        return -1;
    uint8_t *dst = (uint8_t *)destination;
    while (count) {
        uint32_t block_index = offset / XV6FS_BSIZE;
        uint32_t block_offset = offset % XV6FS_BSIZE;
        uint32_t chunk = XV6FS_BSIZE - block_offset;
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
    struct xv6fs_dinode directory;
    struct xv6fs_dirent entry;
    if (read_inode(directory_inum, &directory) < 0 ||
        directory.type != XV6FS_T_DIR)
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
    uint32_t current = XV6FS_ROOTINO;
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

int t113_xv6fs_mount(const void *image, uint32_t bytes)
{
    if (!image || bytes < 2u * XV6FS_BSIZE)
        return -1;
    fs_image = (const uint8_t *)image;
    fs_bytes = bytes;
    copy_bytes(&fs_sb, fs_image + XV6FS_BSIZE, sizeof(fs_sb));
    if (fs_sb.magic != XV6FS_MAGIC ||
        fs_sb.size > fs_bytes / XV6FS_BSIZE)
        return -1;
    t113_uart_puts("xv6fs: mounted embedded image blocks=");
    t113_uart_puthex(fs_sb.size);
    t113_uart_puts(" inodes=");
    t113_uart_puthex(fs_sb.ninodes);
    t113_uart_putc('\n');
    return 0;
}

int t113_xv6fs_read_file(const char *path, void *destination,
                         uint32_t capacity)
{
    uint32_t inum;
    struct xv6fs_dinode inode;
    if (namei(path, &inum) < 0 || read_inode(inum, &inode) < 0 ||
        inode.type != XV6FS_T_FILE || inode.size > capacity)
        return -1;
    if (inode_read(&inode, 0, destination, inode.size) < 0)
        return -1;
    t113_uart_puts("xv6fs: loaded ");
    t113_uart_puts(path);
    t113_uart_puts(" bytes=");
    t113_uart_puthex(inode.size);
    t113_uart_putc('\n');
    return (int)inode.size;
}
