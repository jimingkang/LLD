#include "platform.h"
#include "shell.h"

#define LINE_MAX 96u

static int same(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return *a == *b;
}

static void prompt(void)
{
    t113_early_uart_puts("miniboot> ");
}

static void command(const char *line, int *boot)
{
    if (!line[0]) {
        return;
    } else if (same(line, "help")) {
        t113_early_uart_puts("commands: help, boot, wifi, tftp <server-ip> <file>\n");
    } else if (same(line, "boot")) {
        *boot = 1;
    } else if (same(line, "wifi")) {
        t113_early_uart_puts("wifi: full driver belongs to DDR miniBoot proper (not SRAM SPL)\n");
    } else if (line[0] == 't' && line[1] == 'f' && line[2] == 't' &&
               line[3] == 'p' && (line[4] == 0 || line[4] == ' ')) {
        t113_early_uart_puts("tftp: DDR miniBoot proper is not loaded in this build\n");
    } else {
        t113_early_uart_puts("unknown command; type help\n");
    }
}

void miniboot_shell(void)
{
    uint64_t deadline = t113_counter_ticks() + 3u * 24000000u;
    t113_early_uart_puts("Press any key for miniBoot console: 3\n");
    while (t113_counter_ticks() < deadline) {
        if (t113_early_uart_getc_nonblock() >= 0)
            goto interactive;
    }
    t113_early_uart_puts("Autoboot\n");
    return;

interactive:
    /* The abort byte is intentionally not a command character. Drain any
     * CR/LF or escape-sequence tail without disturbing the working baud
     * rate, clock or transmitter. */
    t113_early_uart_drain_rx();
    t113_early_uart_puts("miniBoot console; type help\n");
    int boot = 0;
    char line[LINE_MAX];
    uint32_t n = 0;
    int swallowed_lf = 0;
    prompt();
    while (!boot) {
        int input = t113_early_uart_getc_nonblock();
        if (input < 0)
            continue;
        char c = (char)input;
        if (c == '\n' && swallowed_lf) {
            swallowed_lf = 0;
            continue;                       /* second half of CRLF */
        }
        if (c == '\r' || c == '\n') {
            t113_early_uart_putc('\n');
            line[n] = 0;
            command(line, &boot);
            n = 0;
            swallowed_lf = c == '\r';
            if (!boot) prompt();
        } else if ((c == '\b' || c == 127) && n) {
            swallowed_lf = 0;
            --n;
            t113_early_uart_try_putc('\b');
        } else if (c >= 32 && c < 127 && n + 1u < LINE_MAX) {
            swallowed_lf = 0;
            line[n++] = c;
            /* Echo only when FIFO space is already available; never block
             * receive polling just to display an input character. */
            t113_early_uart_try_putc(c);
        }
    }
}
