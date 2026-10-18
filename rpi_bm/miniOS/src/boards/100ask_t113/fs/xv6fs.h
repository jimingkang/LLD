#ifndef MINIOS_T113_XV6FS_H
#define MINIOS_T113_XV6FS_H

#include <stdint.h>

#define XV6FS_ROOTINO   1u
#define XV6FS_BSIZE     1024u
#define XV6FS_MAGIC     0x10203040u
#define XV6FS_NDIRECT   12u
#define XV6FS_NINDIRECT (XV6FS_BSIZE / sizeof(uint32_t))
#define XV6FS_DIRSIZ    30u
#define XV6FS_T_DIR     1u
#define XV6FS_T_FILE    2u

struct xv6fs_superblock {
    uint32_t magic, size, nblocks, ninodes;
    uint32_t nlog, logstart, inodestart, bmapstart;
};

struct xv6fs_dinode {
    int16_t type, major, minor, nlink;
    uint32_t size;
    uint32_t addrs[XV6FS_NDIRECT + 1u];
};

struct xv6fs_dirent {
    uint16_t inum;
    char name[XV6FS_DIRSIZ];
};

int t113_xv6fs_mount(const void *image, uint32_t bytes);
int t113_xv6fs_read_file(const char *path, void *destination,
                         uint32_t capacity);

#endif
