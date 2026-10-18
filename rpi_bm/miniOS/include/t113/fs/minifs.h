#ifndef MINIOS_T113_MINIFS_H
#define MINIOS_T113_MINIFS_H

#include <stdint.h>

#define MINIFS_ROOTINO   1u
#define MINIFS_BSIZE     1024u
#define MINIFS_MAGIC     0x10203040u
#define MINIFS_NDIRECT   12u
#define MINIFS_NINDIRECT (MINIFS_BSIZE / sizeof(uint32_t))
#define MINIFS_DIRSIZ    30u
#define MINIFS_T_DIR     1u
#define MINIFS_T_FILE    2u

struct minifs_superblock {
    uint32_t magic, size, nblocks, ninodes;
    uint32_t nlog, logstart, inodestart, bmapstart;
};

struct minifs_dinode {
    int16_t type, major, minor, nlink;
    uint32_t size;
    uint32_t addrs[MINIFS_NDIRECT + 1u];
};

struct minifs_dirent {
    uint16_t inum;
    char name[MINIFS_DIRSIZ];
};

int t113_minifs_mount(const void *image, uint32_t bytes);
int t113_minifs_mount_vfs(const void *image, uint32_t bytes);
int t113_minifs_read_file(const char *path, void *destination,
                         uint32_t capacity);
int t113_minifs_open(const char *path, uint32_t *inum, uint32_t *size);
int t113_minifs_read(uint32_t inum, uint32_t offset, void *destination,
                    uint32_t count);

#endif
