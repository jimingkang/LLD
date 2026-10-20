#ifndef MINIOS_UNISTD_H
#define MINIOS_UNISTD_H

#include <sys/types.h>

#define STDOUT_FILENO 1
#define STDERR_FILENO 2
#define STDIN_FILENO  0

struct dirent {
    unsigned int d_ino;
    unsigned int d_type;
    unsigned int d_size;
    char d_name[31];
};

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
int readdir(const char *path, unsigned int index, struct dirent *entry);
char *getcwd(char *buffer, size_t size);

#endif
