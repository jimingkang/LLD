/*
 * IPv4 output, after Linux net/ipv4/ip_output.c.  No fragmentation and
 * no routing table: the next hop is the destination when it is on-link,
 * otherwise the default gateway.
 */
#include "device.h"
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/ip.h"
#include "net/arp.h"

uint16_t ip_compute_csum(const uint8_t *p, uint32_t len)
{
    uint32_t sum = 0;
    for (; len > 1u; p += 2, len -= 2u)
        sum += get_unaligned_be16(p);
    if (len)
        sum += (uint32_t)p[0] << 8;
    while (sum >> 16)
        sum = (sum & 0xffffu) + (sum >> 16);
    return (uint16_t)~sum;
}

int ip_queue_xmit(struct sk_buff *skb, uint32_t daddr, uint8_t protocol)
{
    struct net_device *dev = dev_get_default();
    struct in_device *in = dev ? dev->ip_ptr : 0;
    if (!in) {
        kfree_skb(skb);
        return -ENODEV;
    }
    uint32_t hop = daddr;
    if (daddr != INADDR_BROADCAST && in->ifa_mask && in->gateway &&
        (daddr & in->ifa_mask) != (in->ifa_address & in->ifa_mask))
        hop = in->gateway;
    uint8_t mac[ETH_ALEN];
    int r = arp_resolve(dev, hop, mac);
    if (r < 0) {
        kfree_skb(skb);
        return r;
    }
    uint32_t payload = skb->len;
    uint8_t *ip = skb_push(skb, IP_HLEN);
    if (!ip) {
        kfree_skb(skb);
        return -EINVAL;
    }
    ip[0] = 0x45;                       /* version 4, 5 words */
    ip[1] = 0;
    put_unaligned_be16(IP_HLEN + payload, ip + 2);
    put_unaligned_be16(++in->ip_id, ip + 4);
    put_unaligned_be16(0x4000, ip + 6);  /* don't fragment */
    ip[8] = 64;
    ip[9] = protocol;
    put_unaligned_be16(0, ip + 10);
    put_unaligned_be32(in->ifa_address, ip + 12);
    put_unaligned_be32(daddr, ip + 16);
    put_unaligned_be16(ip_compute_csum(ip, IP_HLEN), ip + 10);
    if (eth_header(skb, dev, ETH_P_IP, mac) < 0) {
        kfree_skb(skb);
        return -EINVAL;
    }
    return dev_queue_xmit(skb);
}
