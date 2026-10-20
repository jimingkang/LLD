/* Dynamic process-list test adapted from xv6. */
#include <stdio.h>
#include <unistd.h>

#define CHILDREN 128

int main(void)
{
    int created = 0;
    puts("fork test");
    for (; created < CHILDREN; ++created) {
        int pid = fork();
        if (pid < 0)
            break;
        if (pid == 0)
            return 0;
    }
    for (int remaining = created; remaining > 0; --remaining) {
        if (wait(0) < 0) {
            puts("forktest: wait stopped early");
            return 1;
        }
    }
    if (wait(0) != -1) {
        puts("forktest: wait returned too many children");
        return 1;
    }
    printf("forktest: created and reaped %d children\n", created);
    return created ? 0 : 1;
}
