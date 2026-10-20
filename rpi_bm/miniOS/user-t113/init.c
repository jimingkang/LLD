#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(void)
{
    int pid, wpid;
    char *argv[] = {"sh", 0};

    for (;;) {
        puts("init: starting shell on console");
        pid = fork();
        if (pid == 0) {
            exec("/bin/sh", argv);
            puts("init: exec /bin/sh failed");
            exit(1);
        }
        if (pid < 0) {
            puts("init: fork failed");
            sleep(1);
            continue;
        }

        /* xv6 init is also the orphan reaper: ignore unrelated children and
         * restart the shell only after its own child exits. */
        for (;;) {
            int status = 0;
            wpid = wait(&status);
            if (wpid == pid) {
                printf("init: shell exited status=%d; restarting\n", status);
                break;
            }
            if (wpid < 0) {
                puts("init: wait returned an error");
                sleep(1);
                break;
            }
        }
    }
}
