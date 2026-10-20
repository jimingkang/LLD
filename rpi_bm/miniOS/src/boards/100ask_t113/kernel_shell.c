#include "platform.h"
#include "kernel_shell.h"
#include "fs/minifs.h"

#define SHELL_LINE_MAX 128u

static int equal(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return *a == *b;
}

static int starts(const char *s, const char *prefix)
{
    while (*prefix && *s == *prefix) { ++s; ++prefix; }
    return *prefix == 0;
}

static void help(void)
{
    t113_uart_puts("commands:\n");
    t113_uart_puts("  help                         show commands\n");
    t113_uart_puts("  boot                         continue miniOS startup\n");
    t113_uart_puts("  wifi                         show XR829 bring-up state\n");
    t113_uart_puts("  ls [path]                    list a minifs directory\n");
    t113_uart_puts("  tftp <server-ip> <file>      download image (network pending)\n");
}

static void print_dirent(const char *name, uint32_t length, uint32_t inum,
                         uint32_t type, uint32_t size, void *argument)
{
    (void)argument;
    t113_uart_puts(type == MINIFS_T_DIR ? "d " : "- ");
    t113_uart_puthex(inum);
    t113_uart_putc(' ');
    t113_uart_puthex(size);
    t113_uart_putc(' ');
    for (uint32_t i = 0; i < length; ++i)
        t113_uart_putc(name[i]);
    t113_uart_putc('\n');
}

static int execute(char *line)
{
    if (!line[0]) return 0;
    if (equal(line, "help")) help();
    else if (equal(line, "boot") || equal(line, "continue")) return 1;
    else if (equal(line, "ls") || starts(line, "ls ")) {
        const char *path = equal(line, "ls") ? "/" : line + 3;
        while (*path == ' ') ++path;
        if (!*path) path = "/";
        if (t113_minifs_list(path, print_dirent, 0) < 0)
            t113_uart_puts("ls: not a minifs directory or SD read failed\n");
    }
    else if (equal(line, "wifi"))
        t113_uart_puts("wifi: XR829 driver was probed during driver-core init; DHCP is not connected yet\n");
    else if (starts(line, "tftp "))
        t113_uart_puts("tftp: command parsed, but UDP transport is not connected yet\n");
    else t113_uart_puts("unknown command; type help\n");
    return 0;
}

void t113_kernel_shell(void)
{
    char line[SHELL_LINE_MAX];
    uint32_t used = 0;
    int last_cr = 0;

    /* Discard the key/CRLF that may have been used with an older SPL. */
    while (t113_uart_getc_nonblock() >= 0) { }
    t113_uart_puts("\nminiOS kernel monitor; type help\nminiOS> ");
    for (;;) {
        char c = t113_uart_getc();
        if (c == '\n' && last_cr) { last_cr = 0; continue; }
        if (c == '\r' || c == '\n') {
            t113_uart_putc('\n');
            line[used] = 0;
            if (execute(line)) return;
            used = 0;
            last_cr = c == '\r';
            t113_uart_puts("miniOS> ");
        } else if ((c == '\b' || c == 127) && used) {
            --used;
            t113_uart_puts("\b \b");
            last_cr = 0;
        } else if (c >= 32 && c < 127 && used + 1u < SHELL_LINE_MAX) {
            line[used++] = c;
            t113_uart_putc(c);
            last_cr = 0;
        }
    }
}
