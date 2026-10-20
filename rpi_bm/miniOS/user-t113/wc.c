/* Ported from xv6 wc. */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

static char buffer[512];

static int count_file(int fd, const char *name)
{
    int lines = 0, words = 0, bytes = 0, in_word = 0;
    int count;
    while ((count = (int)read(fd, buffer, sizeof(buffer))) > 0) {
        for (int i = 0; i < count; ++i) {
            ++bytes;
            if (buffer[i] == '\n')
                ++lines;
            if (strchr(" \r\t\n\v", buffer[i]))
                in_word = 0;
            else if (!in_word)
                ++words, in_word = 1;
        }
    }
    if (count < 0) {
        printf("wc: read error: %s\n", name);
        return 1;
    }
    printf("%d %d %d %s\n", lines, words, bytes, name);
    return 0;
}

int main(int argc, char **argv)
{
    if (argc == 1)
        return count_file(STDIN_FILENO, "");
    int status = 0;
    for (int i = 1; i < argc; ++i) {
        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) {
            printf("wc: cannot open %s\n", argv[i]);
            status = 1;
            continue;
        }
        status |= count_file(fd, argv[i]);
        close(fd);
    }
    return status;
}
