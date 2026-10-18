#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    printf("echo: minifs user program, pid=%d\n", getpid());
    for (int i = 1; i < argc; ++i)
        printf("%s%s", i == 1 ? "" : " ", argv[i]);
    putchar('\n');
    return 0;
}
