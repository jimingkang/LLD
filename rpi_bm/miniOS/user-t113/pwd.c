#include <stdio.h>
#include <unistd.h>

int main(void)
{
    char path[128];
    if (!getcwd(path, sizeof(path))) {
        puts("pwd: getcwd failed");
        return 1;
    }
    puts(path);
    return 0;
}
