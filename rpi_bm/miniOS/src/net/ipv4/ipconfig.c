/*
 * DHCP client, after Linux net/ipv4/ipconfig.c (kernel IP autoconfig):
 * DISCOVER -> OFFER -> REQUEST -> ACK, broadcast replies, client id =
 * our MAC, hostname "minios".  Runs over the UDP socket API.
 */
#include "platform.h"
#include "device.h"
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/ip.h"
#include "net/udp.h"
#include "net/ipconfig.h"

#define DHCP_CLIENT_PORT 68u
#define DHCP_SERVER_PORT 67u
#define DHCP_MAGIC       0x63825363u
#define DHCPDISCOVER     1u
#define DHCPOFFER        2u
#define DHCPREQUEST      3u
#define DHCPACK          5u
#define DHCPNAK          6u

static uint32_t dhcp_build(const struct net_device *dev, uint8_t *m,
                           uint32_t xid, uint8_t type, uint32_t requested,
                           uint32_t server)
{
    net_memset(m, 0, 240);
    m[0] = 1;                          /* BOOTREQUEST */
    m[1] = 1;                          /* Ethernet */
    m[2] = ETH_ALEN;
    put_unaligned_be32(xid, m + 4);
    put_unaligned_be16(0x8000, m + 10); /* ask for broadcast replies */
    net_memcpy(m + 28, dev->dev_addr, ETH_ALEN);
    put_unaligned_be32(DHCP_MAGIC, m + 236);
    uint32_t o = 240;
    m[o++] = 53; m[o++] = 1; m[o++] = type;
    m[o++] = 61; m[o++] = 7; m[o++] = 1;
    net_memcpy(m + o, dev->dev_addr, ETH_ALEN); o += ETH_ALEN;
    if (requested) { m[o++] = 50; m[o++] = 4; put_unaligned_be32(requested, m + o); o += 4; }
    if (server) { m[o++] = 54; m[o++] = 4; put_unaligned_be32(server, m + o); o += 4; }
    m[o++] = 55; m[o++] = 3; m[o++] = 1; m[o++] = 3; m[o++] = 6;
    m[o++] = 12; m[o++] = 6;
    net_memcpy(m + o, "minios", 6); o += 6;
    m[o++] = 255;
    while (o < 300u) m[o++] = 0;       /* BOOTP minimum size */
    return o;
}

/* Parse a reply for our xid: returns the DHCP message type or -1. */
static int dhcp_parse(const struct net_device *dev, const uint8_t *m,
                      uint32_t len, uint32_t xid, uint32_t *yiaddr,
                      uint32_t *server, uint32_t *mask, uint32_t *router)
{
    if (len < 240u || m[0] != 2u || get_unaligned_be32(m + 4) != xid ||
        get_unaligned_be32(m + 236) != DHCP_MAGIC ||
        !net_memeq(m + 28, dev->dev_addr, ETH_ALEN))
        return -1;
    int type = -1;
    *yiaddr = get_unaligned_be32(m + 16);
    for (uint32_t o = 240; o < len;) {
        uint8_t code = m[o++];
        if (code == 0) continue;
        if (code == 255 || o >= len) break;
        uint8_t n = m[o++];
        if (o + n > len) break;
        if (code == 53 && n == 1) type = m[o];
        if (code == 54 && n == 4) *server = get_unaligned_be32(m + o);
        if (code == 1 && n == 4) *mask = get_unaligned_be32(m + o);
        if (code == 3 && n >= 4) *router = get_unaligned_be32(m + o);
        o += n;
    }
    return type;
}

int ipconfig_dhcp(struct net_device *dev, int timeout_ms)
{
    static uint8_t msg[UDP_PAYLOAD_MAX];
    if (!dev || !dev->ip_ptr || !netif_carrier_ok(dev))
        return -ENODEV;
    struct udp_sock *s = udp_open(DHCP_CLIENT_PORT);
    if (!s)
        return -EBUSY;
    struct in_device saved = *dev->ip_ptr;
    inet_set_addr(dev, 0, 0, 0);
    uint32_t xid = (uint32_t)t113_time_us() ^ 0x6d696e69u;
    uint32_t offered = 0, server = 0, mask = 0, router = 0;
    uint64_t deadline = t113_time_us() + (uint64_t)timeout_ms * 1000u;
    uint32_t state = DHCPDISCOVER;
    int result = -ETIMEDOUT;
    t113_uart_puts("dhcp: discover\n");
    while (t113_time_us() < deadline && result == -ETIMEDOUT) {
        uint32_t n = state == DHCPDISCOVER
                   ? dhcp_build(dev, msg, xid, DHCPDISCOVER, 0, 0)
                   : dhcp_build(dev, msg, xid, DHCPREQUEST, offered, server);
        if (udp_sendto(s, INADDR_BROADCAST, DHCP_SERVER_PORT, msg, n) < 0)
            break;
        uint64_t retry = t113_time_us() + 2000000u;
        while (t113_time_us() < retry && result == -ETIMEDOUT) {
            uint32_t from;
            int got = udp_recvfrom(s, msg, sizeof(msg), &from, 0, 200);
            if (got <= 0)
                continue;
            uint32_t yi = 0, sv = 0, mk = 0, rt = 0;
            int type = dhcp_parse(dev, msg, (uint32_t)got, xid, &yi, &sv, &mk, &rt);
            if (state == DHCPDISCOVER && type == DHCPOFFER && yi) {
                offered = yi; server = sv ? sv : from;
                mask = mk; router = rt;
                state = DHCPREQUEST;
                t113_uart_puts("dhcp: offer ");
                print_ip4(offered);
                t113_uart_puts(", request\n");
                break;                  /* send REQUEST now */
            }
            if (state == DHCPREQUEST && type == DHCPACK) {
                inet_set_addr(dev, yi ? yi : offered, mk ? mk : mask,
                              rt ? rt : router);
                result = 0;
            } else if (state == DHCPREQUEST && type == DHCPNAK) {
                state = DHCPDISCOVER;
                break;
            }
        }
    }
    udp_close(s);
    if (result < 0) {
        *dev->ip_ptr = saved;
        t113_uart_puts("dhcp: no lease\n");
        return result;
    }
    if (!dev->ip_ptr->ifa_mask)
        dev->ip_ptr->ifa_mask = 0xffffff00u;
    t113_uart_puts("dhcp: bound ");
    print_ip4(dev->ip_ptr->ifa_address);
    t113_uart_puts(" gateway ");
    print_ip4(dev->ip_ptr->gateway);
    t113_uart_putc('\n');
    return 0;
}
