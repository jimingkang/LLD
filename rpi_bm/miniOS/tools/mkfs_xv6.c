/*
 * Minimal read-only-image builder derived from xv6 mkfs.  It deliberately
 * keeps xv6's on-disk superblock, inode and directory-entry ABI, while
 * producing a small 64 KiB image suitable for the T113 SRAM Boot0 payload.
 * xv6's MIT license is retained in user-t113/LICENSE.xv6.
 */
#include <assert.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BSIZE 1024u
#define FSSIZE 64u
#define NINODES 32u
#define ROOTINO 1u
#define FSMAGIC 0x10203040u
#define NDIRECT 12u
#define DIRSIZ 30u
#define T_DIR 1u
#define T_FILE 2u

struct superblock {
    uint32_t magic, size, nblocks, ninodes;
    uint32_t nlog, logstart, inodestart, bmapstart;
};
struct dinode {
    int16_t type, major, minor, nlink;
    uint32_t size;
    uint32_t addrs[NDIRECT + 1u];
};
struct dirent { uint16_t inum; char name[DIRSIZ]; };

#define IPB (BSIZE / sizeof(struct dinode))

static int image_fd;
static struct superblock sb;
static uint32_t next_inode = ROOTINO;
static uint32_t next_block;

static void fail(const char *message)
{
    perror(message);
    exit(1);
}

static void write_block(uint32_t block, const void *data)
{
    if (lseek(image_fd, (off_t)block * BSIZE, SEEK_SET) < 0 ||
        write(image_fd, data, BSIZE) != (ssize_t)BSIZE)
        fail("write fs block");
}

static void read_block(uint32_t block, void *data)
{
    if (lseek(image_fd, (off_t)block * BSIZE, SEEK_SET) < 0 ||
        read(image_fd, data, BSIZE) != (ssize_t)BSIZE)
        fail("read fs block");
}

static void write_inode(uint32_t inum, const struct dinode *inode)
{
    uint8_t block[BSIZE];
    uint32_t bno = sb.inodestart + inum / IPB;
    read_block(bno, block);
    ((struct dinode *)block)[inum % IPB] = *inode;
    write_block(bno, block);
}

static void read_inode(uint32_t inum, struct dinode *inode)
{
    uint8_t block[BSIZE];
    read_block(sb.inodestart + inum / IPB, block);
    *inode = ((struct dinode *)block)[inum % IPB];
}

static uint32_t allocate_inode(uint16_t type)
{
    struct dinode inode;
    memset(&inode, 0, sizeof(inode));
    uint32_t inum = next_inode++;
    inode.type = (int16_t)type;
    inode.nlink = 1;
    write_inode(inum, &inode);
    return inum;
}

static void append_inode(uint32_t inum, const void *source, uint32_t bytes)
{
    const uint8_t *src = source;
    struct dinode inode;
    uint8_t block[BSIZE];
    read_inode(inum, &inode);
    uint32_t offset = inode.size;
    while (bytes) {
        uint32_t index = offset / BSIZE;
        assert(index < NDIRECT);
        if (!inode.addrs[index])
            inode.addrs[index] = next_block++;
        read_block(inode.addrs[index], block);
        uint32_t in_block = offset % BSIZE;
        uint32_t chunk = BSIZE - in_block;
        if (chunk > bytes)
            chunk = bytes;
        memcpy(block + in_block, src, chunk);
        write_block(inode.addrs[index], block);
        src += chunk;
        offset += chunk;
        bytes -= chunk;
    }
    inode.size = offset;
    write_inode(inum, &inode);
}

static void append_dirent(uint32_t directory, uint16_t inum, const char *name)
{
    struct dirent entry;
    memset(&entry, 0, sizeof(entry));
    entry.inum = inum;
    strncpy(entry.name, name, DIRSIZ);
    append_inode(directory, &entry, sizeof(entry));
}

static void append_host_file(uint32_t inum, const char *path)
{
    int input = open(path, O_RDONLY);
    if (input < 0)
        fail(path);
    uint8_t buffer[BSIZE];
    ssize_t count;
    while ((count = read(input, buffer, sizeof(buffer))) > 0)
        append_inode(inum, buffer, (uint32_t)count);
    if (count < 0)
        fail("read user binary");
    close(input);
}

int main(int argc, char **argv)
{
    if (argc < 3) {
        fprintf(stderr, "usage: %s fs.img init-binary [program ...]\n", argv[0]);
        return 1;
    }
    assert(sizeof(struct dinode) == 64);
    assert(sizeof(struct dirent) == 32);

    image_fd = open(argv[1], O_RDWR | O_CREAT | O_TRUNC, 0666);
    if (image_fd < 0)
        fail(argv[1]);
    uint8_t zero[BSIZE];
    memset(zero, 0, sizeof(zero));
    for (uint32_t i = 0; i < FSSIZE; ++i)
        write_block(i, zero);

    uint32_t inode_blocks = NINODES / IPB + 1u;
    sb.magic = FSMAGIC;
    sb.size = FSSIZE;
    sb.ninodes = NINODES;
    sb.nlog = 0;
    sb.logstart = 2;
    sb.inodestart = 2;
    sb.bmapstart = sb.inodestart + inode_blocks;
    next_block = sb.bmapstart + 1u;
    sb.nblocks = FSSIZE - next_block;
    memcpy(zero, &sb, sizeof(sb));
    write_block(1, zero);
    memset(zero, 0, sizeof(zero));

    uint32_t root = allocate_inode(T_DIR);
    uint32_t bin = allocate_inode(T_DIR);
    uint32_t init = allocate_inode(T_FILE);
    assert(root == ROOTINO);
    append_dirent(root, root, ".");
    append_dirent(root, root, "..");
    append_dirent(root, bin, "bin");
    append_dirent(root, init, "init");
    append_dirent(bin, bin, ".");
    append_dirent(bin, root, "..");
    append_dirent(bin, init, "init");

    append_host_file(init, argv[2]);

    for (int i = 3; i < argc; ++i) {
        const char *name = strrchr(argv[i], '/');
        name = name ? name + 1 : argv[i];
        if (*name == '_')
            ++name;
        uint32_t program = allocate_inode(T_FILE);
        append_dirent(bin, (uint16_t)program, name);
        append_host_file(program, argv[i]);
    }

    memset(zero, 0, sizeof(zero));
    for (uint32_t i = 0; i < next_block; ++i)
        zero[i / 8u] |= (uint8_t)(1u << (i % 8u));
    write_block(sb.bmapstart, zero);
    close(image_fd);
    printf("mkfs_xv6: %s blocks=%u used=%u /init inode=%u\n",
           argv[1], FSSIZE, next_block, init);
    return 0;
}
