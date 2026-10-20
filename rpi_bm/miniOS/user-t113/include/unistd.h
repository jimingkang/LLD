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
int dup(int oldfd);
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

/* Networking (kernel UDP/IP stack over the XR829 WiFi). */
#define NETCTL_STATUS 0
#define NETCTL_DHCP   1
#define NETCTL_PING   2
#define NETCTL_STATIC 3
#define NETCTL_WIFI   4
int tftp(const char *server, const char *remote, const char *local);
int netctl(int command, const char *a1, const char *a2, const char *a3);

#endif
