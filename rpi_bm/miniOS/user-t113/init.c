#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(void)
{
    puts("init: fork child");
    int fd = open("/bin/echo", O_RDONLY);
    uint8_t elf_magic[4];
    if (fd >= 0 && read(fd, elf_magic, sizeof(elf_magic)) ==
                   (int)sizeof(elf_magic))
        printf("init: /bin/echo ELF magic=%x%x%x%x uptime=%u\n",
               elf_magic[0], elf_magic[1], elf_magic[2], elf_magic[3],
               uptime());
    if (fd >= 0)
        close(fd);
    char *heap_test = malloc(32);
    if (heap_test) {
        strcpy(heap_test, "user heap via sbrk OK");
        printf("init: %s\n", heap_test);
        free(heap_test);
    }

    int pid = vfork();
    if (pid == 0) {
        char *argv[] = {"echo", "hello", 0};
        exec("/bin/echo", argv);
        puts("init: exec /bin/echo failed");
        exit(1);
    }
    if (pid > 0) {
        int status;
        int child = wait(&status);
        printf("init: child %d exited, status=%d\n", child, status);
    }
    for (;;)
        yield();
}
