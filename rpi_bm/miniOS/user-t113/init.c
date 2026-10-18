/* Adapted from xv6's initial user-program role for miniOS/T113. */
typedef unsigned int uint32_t;

int user_write(const char *text, uint32_t length);
int user_getpid(void);
int user_yield(void);

int main(void)
{
    static const char message[] = "init: loaded /init from xv6fs\n";
    user_write(message, sizeof(message) - 1u);

    for (;;) {
        (void)user_getpid();
        user_yield();
    }
}
