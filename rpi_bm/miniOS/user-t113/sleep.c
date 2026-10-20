#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (argc != 2) {
        puts("usage: sleep seconds");
        return 1;
    }
    sleep((unsigned int)strtoul(argv[1], 0, 10));
    return 0;
}
