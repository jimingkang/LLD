#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/* ping <ip> [count] */
int main(int argc, char **argv)
{
    if (argc != 2 && argc != 3) {
        puts("usage: ping ip [count]");
        return 1;
    }
    int count = argc == 3 ? atoi(argv[2]) : 4;
    int replies = 0;
    for (int i = 0; i < count; ++i) {
        int us = netctl(NETCTL_PING, argv[1], 0, 0);
        if (us >= 0) {
            ++replies;
            printf("reply from %s: seq=%d time=%d us\n", argv[1], i + 1, us);
        } else if (errno == ETIMEDOUT) {
            printf("seq=%d timeout\n", i + 1);
        } else {
            printf("ping: network unavailable (errno %d)\n", errno);
            return 1;
        }
        if (i + 1 < count)
            sleep(1);
    }
    printf("%d/%d replies\n", replies, count);
    return replies ? 0 : 1;
}
