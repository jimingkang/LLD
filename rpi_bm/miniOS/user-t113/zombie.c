/* xv6-style orphan/zombie reparenting smoke test. */
#include <unistd.h>

int main(void)
{
    if (fork() > 0)
        sleep(1);
    return 0;
}
