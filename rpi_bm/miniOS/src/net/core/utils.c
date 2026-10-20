/*
 * Generic network helpers, after Linux net/core/utils.c (in4_pton) and
 * the printk %pM / %pI4 formats.
 */
#include "platform.h"
#include "net/netutil.h"
#include "net/ip.h"

void net_putdec(uint32_t v)
{
    char b[11];
    int i = 10;
    b[i] = 0;
    do { b[--i] = (char)('0' + v % 10u); v /= 10u; } while (v);
    t113_uart_puts(&b[i]);
}

void net_print_mac(const uint8_t mac[6])
{
    static const char hex[] = "0123456789abcdef";
    for (uint32_t i = 0; i < 6; ++i) {
        if (i) t113_uart_putc(':');
        t113_uart_putc(hex[mac[i] >> 4]);
        t113_uart_putc(hex[mac[i] & 15]);
    }
}

void print_ip4(uint32_t ip)
{
    for (int i = 3; i >= 0; --i) {
        net_putdec((ip >> (i * 8)) & 0xffu);
        if (i) t113_uart_putc('.');
    }
}

int in4_pton(const char *s, uint32_t *ip)
{
    uint32_t v = 0;
    for (int part = 0; part < 4; ++part) {
        uint32_t n = 0, digits = 0;
        while (*s >= '0' && *s <= '9' && digits < 4u) {
            n = n * 10u + (uint32_t)(*s++ - '0');
            ++digits;
        }
        if (!digits || n > 255u || (part < 3 && *s++ != '.'))
            return -1;
        v = (v << 8) | n;
    }
    if (*s)
        return -1;
    *ip = v;
    return 0;
}
