#ifndef MINIOS_FCNTL_H
#define MINIOS_FCNTL_H

#define O_RDONLY 0x0000
#define O_RDWR   0x0002
#define O_CREATE 0x0200
#define O_CREAT  O_CREATE
#define O_TRUNC  0x0400

int open(const char *path, int flags);

#endif
