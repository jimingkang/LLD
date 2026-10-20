/*
 * ICMP echo, after Linux net/ipv4/icmp.c (replies) and net/ipv4/ping.c
 * (requests).  Only one ping runs at a time.
 */
#include "platform.h"
#include "device.h"
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/ip.h"
#include "net/icmp.h"
#include "net/udp.h"

#define ICMP_ECHOREPLY  0u
#define ICMP_ECHO       8u
#define PING_ID         0x4d4fu          /* "MO" */
#define PING_LEN        40u

static struct {
    uint16_t seq;
    uint32_t done;
} ping;

void icmp_rcv(struct sk_buff *skb, uint32_t saddr)
{
    uint8_t *p = skb->data;
    uint32_t len = skb->len;
    if (len < 8u || ip_compute_csum(p, len) != 0) {
        kfree_skb(skb);
        return;
    }
    if (p[0] == ICMP_ECHO && inet_get_addr(skb->dev) && len <= UDP_PAYLOAD_MAX) {
        /* Turn the request into the reply in place and send it back. */
        p[0] = ICMP_ECHOREPLY;
        put_unaligned_be16(0, p + 2);
        put_unaligned_be16(ip_compute_csum(p, len), p + 2);
        ip_queue_xmit(skb, saddr, IPPROTO_ICMP);
        return;
    }
    if (p[0] == ICMP_ECHOREPLY && get_unaligned_be16(p + 4) == PING_ID &&
        get_unaligned_be16(p + 6) == ping.seq)
        ping.done = 1;
    kfree_skb(skb);
}

int icmp_ping(uint32_t daddr, int timeout_ms)
{
    struct net_device *dev = dev_get_default();
    if (!dev || !inet_get_addr(dev))
        return -ENODEV;
    rtnl_lock();
    struct sk_buff *skb = alloc_skb(PING_LEN);
    if (!skb) {
        rtnl_unlock();
        return -ENOSPC;
    }
    uint8_t *p = skb_put(skb, PING_LEN);
    ++ping.seq;
    ping.done = 0;
    p[0] = ICMP_ECHO;
    p[1] = 0;
    put_unaligned_be16(0, p + 2);
    put_unaligned_be16(PING_ID, p + 4);
    put_unaligned_be16(ping.seq, p + 6);
    for (uint32_t i = 0; i < PING_LEN - 8u; ++i)
        p[8 + i] = (uint8_t)('a' + i % 23u);
    put_unaligned_be16(ip_compute_csum(p, PING_LEN), p + 2);
    uint64_t start = t113_time_us();
    int r = ip_queue_xmit(skb, daddr, IPPROTO_ICMP);
    uint64_t end = start + (uint64_t)timeout_ms * 1000u;
    while (r >= 0 && !ping.done && t113_time_us() < end)
        __net_poll(dev, 10);
    rtnl_unlock();
    if (r < 0)
        return r;
    return ping.done ? (int)(t113_time_us() - start) : -ETIMEDOUT;
}
