#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define LINE_MAX 128
#define ARGV_MAX 16

static int readline(char *line, int capacity)
{
    int used = 0;
    for (;;) {
        char c;
        if (read(STDIN_FILENO, &c, 1) != 1)
            return -1;
        if (c == '\r' || c == '\n') {
            putchar('\n');
            line[used] = 0;
            return used;
        }
        if ((c == '\b' || c == 127) && used) {
            --used;
            printf("\b \b");
        } else if (c >= 32 && c < 127 && used + 1 < capacity) {
            line[used++] = c;
            putchar(c);
        }
    }
}

static int split(char *line, char **argv)
{
    int argc = 0;
    while (*line && argc + 1 < ARGV_MAX) {
        while (*line == ' ' || *line == '\t') ++line;
        if (!*line) break;
        argv[argc++] = line;
        while (*line && *line != ' ' && *line != '\t') ++line;
        if (*line) *line++ = 0;
    }
    argv[argc] = 0;
    return argc;
}

int main(void)
{
    char line[LINE_MAX];
    char path[LINE_MAX];
    char *argv[ARGV_MAX];
    puts("miniOS shell ready");
    for (;;) {
        printf("$ ");
        if (readline(line, sizeof(line)) < 0)
            continue;
        int argc = split(line, argv);
        if (!argc)
            continue;
        if (!strcmp(argv[0], "exit"))
            return 0;
        if (argv[0][0] == '/') {
            strncpy(path, argv[0], sizeof(path));
            path[sizeof(path) - 1] = 0;
        } else {
            strcpy(path, "/bin/");
            strncat(path, argv[0], sizeof(path) - strlen(path) - 1u);
        }
        /* Keep the command child in a private address space.  This matches
         * xv6 sh's fork/exec/wait model and avoids exposing the shell stack
         * to the child while exec is replacing its page table. */
        int pid = fork();
        if (pid == 0) {
            exec(path, argv);
            printf("sh: %s: command not found\n", argv[0]);
            exit(127);
        }
        if (pid > 0) {
            int status;
            wait(&status);
        } else {
            puts("sh: cannot create process");
        }
    }
}
