/*
 * TFTP download over the UDP stack into a file.
 *
 * The whole image is received into RAM first and only written to the
 * destination once the transfer completed, so an interrupted download
 * never leaves a half-written kernel in /boot.  After writing, the file is
 * read back and its CRC32 compared with the received image.
 */
#include "platform.h"
#include "device.h"
#include "fs/vfs.h"
#include "net/netdevice.h"
#include "net/ip.h"
#include "net/udp.h"
#include "net/ipconfig.h"
#include "net/tftp.h"

#define TFTP_TIMEOUT_MS   1000
#define TFTP_RETRIES      6u
#define TFTP_IMAGE_PAGES  2048u          /* 8 MiB */

static uint32_t crc32_update(uint32_t crc, const uint8_t *p, uint32_t n)
{
    crc = ~crc;
    while (n--) {
        crc ^= *p++;
        for (int k = 0; k < 8; ++k)
            crc = (crc >> 1) ^ (0xedb88320u & (0u - (crc & 1u)));
    }
    return ~crc;
}

static void putdec(uint32_t v)
{
    char b[11];
    int i = 10;
    b[i] = 0;
    do { b[--i] = (char)('0' + v % 10u); v /= 10u; } while (v);
    t113_uart_puts(&b[i]);
}

static int receive(uint32_t server, struct tftp_client *c)
{
    static uint8_t packet[4u + TFTP_BLOCK_SIZE + 4u];
    static uint8_t reply[TFTP_BLOCK_SIZE];
    struct udp_sock *s = udp_open(0);
    if (!s)
        return -EBUSY;
    int len = tftp_client_rrq(c, reply, sizeof(reply));
    uint16_t reply_port = TFTP_PORT;
    uint32_t retries = 0, last_report = 0;
    int result = -ETIMEDOUT;
    while (len > 0 && retries <= TFTP_RETRIES) {
        if (udp_sendto(s, server, reply_port, reply, (uint32_t)len) < 0) {
            result = -EIO;
            break;
        }
        if (c->state == TFTP_COMPLETE) {
            result = 0;
            break;
        }
        uint32_t from;
        uint16_t port;
        int got = udp_recvfrom(s, packet, sizeof(packet), &from, &port,
                               TFTP_TIMEOUT_MS);
        if (got < 0) {
            result = got;
            break;
        }
        if (got == 0 || from != server) {
            ++retries;                 /* resend the RRQ or the last ACK */
            continue;
        }
        int n = tftp_client_input(c, port, packet, (uint32_t)got,
                                  reply, sizeof(reply));
        if (n < 0) {
            t113_uart_puts(c->state == TFTP_ERROR && c->error_code == 1
                           ? "tftp: file not found on server\n"
                           : "tftp: transfer error\n");
            result = n;
            break;
        }
        if (n == 0)
            continue;                  /* stray packet: keep waiting */
        len = n;
        reply_port = c->server_port;
        retries = 0;
        if (c->size - last_report >= 64u * 1024u) {
            last_report = c->size;
            t113_uart_putc('#');
        }
    }
    udp_close(s);
    if (last_report)
        t113_uart_putc('\n');
    return result;
}

static int write_file(const char *path, const uint8_t *data, uint32_t size)
{
    struct file *f = t113_vfs_open(path, VFS_O_RDWR | VFS_O_CREATE |
                                             VFS_O_TRUNC);
    if (!f) {
        t113_uart_puts("tftp: cannot create ");
        t113_uart_puts(path);
        t113_uart_putc('\n');
        return -EIO;
    }
    uint32_t done = 0;
    while (done < size) {
        uint32_t n = size - done < 4096u ? size - done : 4096u;
        if (t113_vfs_write(f, data + done, n) != (int)n)
            break;
        done += n;
    }
    t113_vfs_close(f);
    if (done != size) {
        t113_uart_puts("tftp: write failed\n");
        return -EIO;
    }
    /* Read back through the filesystem and compare checksums. */
    static uint8_t chunk[4096] __attribute__((aligned(4)));
    f = t113_vfs_open(path, VFS_O_RDONLY);
    uint32_t crc = 0, total = 0;
    int r;
    while (f && (r = t113_vfs_read(f, chunk, sizeof(chunk))) > 0) {
        crc = crc32_update(crc, chunk, (uint32_t)r);
        total += (uint32_t)r;
    }
    t113_vfs_close(f);
    if (total != size || crc != crc32_update(0, data, size)) {
        t113_uart_puts("tftp: read-back verify FAILED\n");
        return -EIO;
    }
    return 0;
}

int tftp_get(uint32_t server, const char *remote, const char *local)
{
    struct net_device *dev = dev_get_default();
    if (!netif_carrier_ok(dev)) {
        t113_uart_puts("tftp: WiFi link is down (try: wifi)\n");
        return -ENODEV;
    }
    if (!inet_get_addr(dev) && ipconfig_dhcp(dev, 8000) < 0)
        return -ENODEV;

    uint32_t pages = TFTP_IMAGE_PAGES;
    void *image = 0;
    while (pages >= 64u && !(image = t113_alloc_pages(pages, 1)))
        pages /= 2u;
    if (!image) {
        t113_uart_puts("tftp: out of memory\n");
        return -ENOSPC;
    }
    struct tftp_client c;
    tftp_client_init(&c, remote, image, pages * 4096u);
    t113_uart_puts("tftp: get ");
    t113_uart_puts(remote);
    t113_uart_puts(" from ");
    print_ip4(server);
    t113_uart_putc('\n');

    uint64_t start = t113_time_us();
    int r = receive(server, &c);
    uint32_t ms = (uint32_t)(t113_time_us() - start) / 1000u;
    if (r == 0) {
        t113_uart_puts("tftp: received ");
        putdec(c.size);
        t113_uart_puts(" bytes in ");
        putdec(ms);
        t113_uart_puts(" ms, crc32 ");
        t113_uart_puthex(crc32_update(0, image, c.size));
        t113_uart_putc('\n');
        r = write_file(local, image, c.size);
        if (r == 0) {
            t113_uart_puts("tftp: saved ");
            t113_uart_puts(local);
            t113_uart_putc('\n');
        }
    } else if (r == -ETIMEDOUT) {
        t113_uart_puts("tftp: timeout, no answer from server\n");
    }
    uint32_t size = c.size;
    t113_free_pages(image, pages);
    return r < 0 ? r : (int)size;
}
