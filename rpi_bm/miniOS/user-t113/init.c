/* Adapted from xv6's initial user-program role for miniOS/T113. */
typedef unsigned int uint32_t;

int user_write(const char *text, uint32_t length);
int user_getpid(void);
int user_yield(void);
int fork(void);
int sleep(uint32_t seconds);
int wait(void);
void exit(int status);

int main(void)
{
    static const char start[] = "init: fork child\n";
    static const char sleeping[] = "child: sleep 3 seconds\n";
    static const char done[] = "child: wake and exit\n";
    static const char waited[] = "init: child exited\n";
    user_write(start, sizeof(start) - 1u);

    int pid = fork();
    if (pid == 0) {
        user_write(sleeping, sizeof(sleeping) - 1u);
        sleep(3);
        user_write(done, sizeof(done) - 1u);
        exit(0);
    }
    if (pid > 0) {
        (void)wait();
        user_write(waited, sizeof(waited) - 1u);
    }
    for (;;)
        user_yield();
}
