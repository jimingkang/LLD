#ifndef MINIOS_FCNTL_H
#define MINIOS_FCNTL_H

#define O_RDONLY 0x0000
#define O_RDWR   0x0002

int open(const char *path, int flags);

#endif
