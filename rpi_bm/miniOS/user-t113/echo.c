/* Minimal ARM32 port of xv6 user/echo.c for the current miniOS syscall ABI. */
typedef unsigned int uint32_t;
int user_write(const char *text, uint32_t length);
int user_yield(void);

int main(void)
{
    static const char message[] = "echo: xv6fs user program\n";
    user_write(message, sizeof(message) - 1u);
    for (;;)
        user_yield();
}
