/*
 * UDP, after Linux net/ipv4/udp.c.  Sockets are a small static table;
 * received datagrams stay in their skb on the socket's receive queue
 * until udp_recvfrom() copies them out.  Checksums are not generated
 * (optional over IPv4) and not verified.
 */
#include "platform.h"
#include "device.h"
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/ip.h"
#include "net/udp.h"

#define UDP_SOCKS       4u
#define UDP_QUEUE       4u
#define EPHEMERAL_BASE  49152u

struct udp_sock {
    uint32_t used;
    uint16_t port;
    struct sk_buff_head rx_queue;
};

/* Source of a queued datagram, kept in skb->cb. */
struct udp_cb {
    uint32_t saddr;
    uint16_t sport;
};

static struct udp_sock socks[UDP_SOCKS];
static uint16_t next_port = EPHEMERAL_BASE;

void udp_rcv(struct sk_buff *skb, uint32_t saddr)
{
    const uint8_t *u = skb->data;
    if (skb->len < UDP_HLEN || get_unaligned_be16(u + 4) < UDP_HLEN ||
        get_unaligned_be16(u + 4) > skb->len) {
        kfree_skb(skb);
        return;
    }
    uint16_t sport = get_unaligned_be16(u), dport = get_unaligned_be16(u + 2);
    skb_trim(skb, get_unaligned_be16(u + 4));
    skb_pull(skb, UDP_HLEN);
    for (uint32_t i = 0; i < UDP_SOCKS; ++i) {
        struct udp_sock *s = &socks[i];
        if (!s->used || s->port != dport)
            continue;
        if (s->rx_queue.qlen >= UDP_QUEUE)
            break;                      /* queue full: drop */
        struct udp_cb *cb = (struct udp_cb *)(void *)skb->cb;
        cb->saddr = saddr;
        cb->sport = sport;
        skb_queue_tail(&s->rx_queue, skb);
        return;
    }
    kfree_skb(skb);
}

struct udp_sock *udp_open(uint16_t port)
{
    if (!dev_get_default())
        return 0;
    rtnl_lock();
    if (!port) {
        port = next_port++;
        if (next_port < EPHEMERAL_BASE)
            next_port = EPHEMERAL_BASE;
    }
    struct udp_sock *found = 0;
    for (uint32_t i = 0; i < UDP_SOCKS; ++i)
        if (socks[i].used && socks[i].port == port) {
            rtnl_unlock();
            return 0;
        }
    for (uint32_t i = 0; i < UDP_SOCKS && !found; ++i)
        if (!socks[i].used) {
            found = &socks[i];
            found->used = 1;
            found->port = port;
            skb_queue_head_init(&found->rx_queue);
        }
    rtnl_unlock();
    return found;
}

void udp_close(struct udp_sock *s)
{
    if (!s)
        return;
    rtnl_lock();
    skb_queue_purge(&s->rx_queue);
    s->used = 0;
    rtnl_unlock();
}

int udp_sendto(struct udp_sock *s, uint32_t ip, uint16_t port,
               const void *data, uint32_t len)
{
    if (!s || !s->used)
        return -EINVAL;
    if (len > UDP_PAYLOAD_MAX)
        return -EINVAL;
    rtnl_lock();
    struct sk_buff *skb = alloc_skb(len);
    if (!skb) {
        rtnl_unlock();
        return -ENOSPC;
    }
    net_memcpy(skb_put(skb, len), data, len);
    uint8_t *u = skb_push(skb, UDP_HLEN);
    put_unaligned_be16(s->port, u);
    put_unaligned_be16(port, u + 2);
    put_unaligned_be16(UDP_HLEN + len, u + 4);
    put_unaligned_be16(0, u + 6);
    int r = ip_queue_xmit(skb, ip, IPPROTO_UDP);
    rtnl_unlock();
    return r < 0 ? r : (int)len;
}

int udp_recvfrom(struct udp_sock *s, void *buf, uint32_t capacity,
                 uint32_t *ip, uint16_t *port, int timeout_ms)
{
    if (!s || !s->used)
        return -EINVAL;
    rtnl_lock();
    uint64_t end = t113_time_us() + (uint64_t)timeout_ms * 1000u;
    while (!s->rx_queue.qlen && t113_time_us() < end)
        __net_poll(0, 10);
    int r = 0;
    struct sk_buff *skb = skb_dequeue(&s->rx_queue);
    if (skb) {
        const struct udp_cb *cb = (const struct udp_cb *)(const void *)skb->cb;
        uint32_t n = skb->len < capacity ? skb->len : capacity;
        net_memcpy(buf, skb->data, n);
        if (ip) *ip = cb->saddr;
        if (port) *port = cb->sport;
        kfree_skb(skb);
        r = (int)n;
    }
    rtnl_unlock();
    return r;
}
