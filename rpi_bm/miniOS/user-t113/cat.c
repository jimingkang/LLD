#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (argc < 2) {
        puts("usage: cat file ...");
        return 1;
    }
    char buffer[128];
    int status = 0;
    for (int i = 1; i < argc; ++i) {
        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) {
            printf("cat: cannot open %s\n", argv[i]);
            status = 1;
            continue;
        }
        int count;
        while ((count = (int)read(fd, buffer, sizeof(buffer))) > 0)
            write(STDOUT_FILENO, buffer, (unsigned int)count);
        if (count < 0) {
            printf("cat: read error: %s\n", argv[i]);
            status = 1;
        }
        close(fd);
    }
    return status;
}
