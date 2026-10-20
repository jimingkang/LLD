/* Ported from xv6 grep: ^ . * and $ regular-expression operators. */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

static char buffer[1024];

static int matchhere(const char *, const char *);

static int matchstar(int character, const char *regexp, const char *text)
{
    do {
        if (matchhere(regexp, text))
            return 1;
    } while (*text && (*text++ == character || character == '.'));
    return 0;
}

static int matchhere(const char *regexp, const char *text)
{
    if (!regexp[0])
        return 1;
    if (regexp[1] == '*')
        return matchstar(regexp[0], regexp + 2, text);
    if (regexp[0] == '$' && !regexp[1])
        return !*text;
    if (*text && (regexp[0] == '.' || regexp[0] == *text))
        return matchhere(regexp + 1, text + 1);
    return 0;
}

static int match(const char *regexp, const char *text)
{
    if (regexp[0] == '^')
        return matchhere(regexp + 1, text);
    do {
        if (matchhere(regexp, text))
            return 1;
    } while (*text++);
    return 0;
}

static void grep(const char *pattern, int fd)
{
    int used = 0;
    int count;
    while ((count = (int)read(fd, buffer + used,
                              sizeof(buffer) - (unsigned)used - 1u)) > 0) {
        used += count;
        buffer[used] = 0;
        char *line = buffer;
        char *end;
        while ((end = strchr(line, '\n')) != 0) {
            *end = 0;
            if (match(pattern, line)) {
                *end = '\n';
                write(STDOUT_FILENO, line, (size_t)(end + 1 - line));
            }
            line = end + 1;
        }
        used -= (int)(line - buffer);
        memmove(buffer, line, (size_t)used);
    }
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        puts("usage: grep pattern [file ...]");
        return 1;
    }
    if (argc == 2) {
        grep(argv[1], STDIN_FILENO);
        return 0;
    }
    for (int i = 2; i < argc; ++i) {
        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) {
            printf("grep: cannot open %s\n", argv[i]);
            return 1;
        }
        grep(argv[1], fd);
        close(fd);
    }
    return 0;
}
