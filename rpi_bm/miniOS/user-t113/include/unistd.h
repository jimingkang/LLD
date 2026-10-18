#ifndef MINIOS_UNISTD_H
#define MINIOS_UNISTD_H

#include <sys/types.h>

#define STDOUT_FILENO 1
#define STDERR_FILENO 2

ssize_t write(int fd, const void *buffer, size_t count);
ssize_t read(int fd, void *buffer, size_t count);
int close(int fd);
pid_t getpid(void);
int yield(void);
pid_t fork(void);
pid_t vfork(void);
unsigned int sleep(unsigned int seconds);
pid_t wait(int *status);
unsigned int uptime(void);
int exec(const char *path, char *const argv[]);
void *sbrk(ptrdiff_t increment);

#endif
