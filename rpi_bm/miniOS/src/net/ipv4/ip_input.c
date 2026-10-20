/*
 * IPv4 input, after Linux net/ipv4/ip_input.c: validate the header,
 * accept datagrams for us (anything while we have no address, so DHCP
 * replies get through) and hand them to ICMP or UDP.  Fragments are not
 * reassembled.
 */
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/ip.h"
#include "net/icmp.h"
#include "net/udp.h"

int ip_rcv(struct sk_buff *skb, struct net_device *dev)
{
    const uint8_t *ip = skb->data;
    uint32_t len = skb->len;
    if (len < IP_HLEN || (ip[0] >> 4) != 4u)
        goto drop;
    uint32_t hlen = (ip[0] & 0x0fu) * 4u, total = get_unaligned_be16(ip + 2);
    if (hlen < IP_HLEN || total < hlen || total > len ||
        ip_compute_csum(ip, hlen) != 0)
        goto drop;
    if (get_unaligned_be16(ip + 6) & 0x3fffu)
        goto drop;
    uint32_t daddr = get_unaligned_be32(ip + 16);
    uint32_t saddr = get_unaligned_be32(ip + 12);
    uint32_t ours = inet_get_addr(dev);
    uint32_t mask = dev->ip_ptr ? dev->ip_ptr->ifa_mask : 0;
    if (ours && daddr != ours && daddr != INADDR_BROADCAST &&
        !(mask && (daddr | mask) == INADDR_BROADCAST))
        goto drop;
    uint8_t protocol = ip[9];
    skb_trim(skb, total);
    skb_pull(skb, hlen);
    if (protocol == IPPROTO_ICMP)
        icmp_rcv(skb, saddr);
    else if (protocol == IPPROTO_UDP)
        udp_rcv(skb, saddr);
    else
        kfree_skb(skb);
    return 0;
drop:
    ++dev->rx_dropped;
    kfree_skb(skb);
    return 0;
}
