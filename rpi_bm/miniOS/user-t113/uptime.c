#include <stdio.h>
#include <unistd.h>

int main(void)
{
    printf("uptime: %u seconds\n", uptime());
    return 0;
}
