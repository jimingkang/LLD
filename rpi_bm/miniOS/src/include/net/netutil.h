#ifndef MINIOS_NET_NETUTIL_H
#define MINIOS_NET_NETUTIL_H

#include <stdint.h>

/*
 * Byte helpers shared by the network stack.  The kernel is freestanding
 * (-fno-builtin, no libc), so the usual memcpy/memcmp and Linux's
 * <asm/unaligned.h> accessors are provided here as inline functions.
 * Network byte order is big endian; 802.11 fields are little endian.
 */

static inline uint16_t get_unaligned_be16(const uint8_t *p)
{
    return (uint16_t)((p[0] << 8) | p[1]);
}

static inline uint32_t get_unaligned_be32(const uint8_t *p)
{
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) | p[3];
}

static inline void put_unaligned_be16(uint32_t v, uint8_t *p)
{
    p[0] = (uint8_t)(v >> 8);
    p[1] = (uint8_t)v;
}

static inline void put_unaligned_be32(uint32_t v, uint8_t *p)
{
    p[0] = (uint8_t)(v >> 24);
    p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8);
    p[3] = (uint8_t)v;
}

static inline uint16_t get_unaligned_le16(const uint8_t *p)
{
    return (uint16_t)(p[0] | (p[1] << 8));
}

static inline uint32_t get_unaligned_le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static inline void put_unaligned_le16(uint32_t v, uint8_t *p)
{
    p[0] = (uint8_t)v;
    p[1] = (uint8_t)(v >> 8);
}

static inline void put_unaligned_le32(uint32_t v, uint8_t *p)
{
    p[0] = (uint8_t)v;
    p[1] = (uint8_t)(v >> 8);
    p[2] = (uint8_t)(v >> 16);
    p[3] = (uint8_t)(v >> 24);
}

static inline void net_memcpy(void *dst, const void *src, uint32_t n)
{
    uint8_t *d = dst;
    const uint8_t *s = src;
    while (n--)
        *d++ = *s++;
}

/* Overlap-safe copy (used to slide 802.11 headers over stripped IVs). */
static inline void net_memmove(void *dst, const void *src, uint32_t n)
{
    uint8_t *d = dst;
    const uint8_t *s = src;
    if (d < s) {
        while (n--)
            *d++ = *s++;
    } else {
        while (n--)
            d[n] = s[n];
    }
}

static inline void net_memset(void *dst, uint8_t v, uint32_t n)
{
    uint8_t *d = dst;
    while (n--)
        *d++ = v;
}

static inline int net_memeq(const void *a, const void *b, uint32_t n)
{
    const uint8_t *x = a, *y = b;
    for (uint32_t i = 0; i < n; ++i)
        if (x[i] != y[i])
            return 0;
    return 1;
}

static inline uint32_t net_strlen(const char *s)
{
    uint32_t n = 0;
    while (s[n])
        ++n;
    return n;
}

void net_putdec(uint32_t v);
void net_print_mac(const uint8_t mac[6]);

#endif
