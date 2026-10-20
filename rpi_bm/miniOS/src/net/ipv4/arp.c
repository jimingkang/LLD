/*
 * ARP and a small neighbour cache, after Linux net/ipv4/arp.c.
 *
 * Linux queues packets on an unresolved neighbour and sends them when the
 * reply arrives.  miniOS resolves synchronously instead: arp_resolve()
 * polls the device until the reply is in.  Inside the receive path (an
 * ICMP echo reply to an unknown host) it only sends the request and lets
 * the packet go; the peer has normally ARPed us first anyway.
 */
#include "platform.h"
#include "device.h"
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/ip.h"
#include "net/arp.h"

#define ARP_ENTRIES     8u
#define ARPHRD_ETHER    1u
#define ARPOP_REQUEST   1u
#define ARPOP_REPLY     2u
#define ARP_PKT_LEN     28u

static struct {
    uint32_t ip;
    uint8_t mac[ETH_ALEN];
    uint32_t used;
} arp_tbl[ARP_ENTRIES];
static uint32_t arp_next;

static void arp_learn(uint32_t ip, const uint8_t mac[ETH_ALEN])
{
    if (!ip)
        return;
    for (uint32_t i = 0; i < ARP_ENTRIES; ++i)
        if (arp_tbl[i].used && arp_tbl[i].ip == ip) {
            net_memcpy(arp_tbl[i].mac, mac, ETH_ALEN);
            return;
        }
    uint32_t i = arp_next++ % ARP_ENTRIES;
    arp_tbl[i].used = 1;
    arp_tbl[i].ip = ip;
    net_memcpy(arp_tbl[i].mac, mac, ETH_ALEN);
}

static int arp_lookup(uint32_t ip, uint8_t mac[ETH_ALEN])
{
    for (uint32_t i = 0; i < ARP_ENTRIES; ++i)
        if (arp_tbl[i].used && arp_tbl[i].ip == ip) {
            net_memcpy(mac, arp_tbl[i].mac, ETH_ALEN);
            return 0;
        }
    return -1;
}

static int arp_send(struct net_device *dev, uint16_t op,
                    const uint8_t tha[ETH_ALEN], uint32_t tip,
                    const uint8_t *eth_dst)
{
    struct sk_buff *skb = alloc_skb(ARP_PKT_LEN);
    if (!skb)
        return -ENOSPC;
    uint8_t *a = skb_put(skb, ARP_PKT_LEN);
    put_unaligned_be16(ARPHRD_ETHER, a);
    put_unaligned_be16(ETH_P_IP, a + 2);
    a[4] = ETH_ALEN;
    a[5] = 4;
    put_unaligned_be16(op, a + 6);
    net_memcpy(a + 8, dev->dev_addr, ETH_ALEN);
    put_unaligned_be32(inet_get_addr(dev), a + 14);
    net_memcpy(a + 18, tha, ETH_ALEN);
    put_unaligned_be32(tip, a + 24);
    if (eth_header(skb, dev, ETH_P_ARP, eth_dst) < 0) {
        kfree_skb(skb);
        return -EINVAL;
    }
    return dev_queue_xmit(skb);
}

int arp_rcv(struct sk_buff *skb, struct net_device *dev)
{
    const uint8_t *a = skb->data;
    if (skb->len < ARP_PKT_LEN || get_unaligned_be16(a) != ARPHRD_ETHER ||
        get_unaligned_be16(a + 2) != ETH_P_IP || a[4] != ETH_ALEN || a[5] != 4u) {
        kfree_skb(skb);
        return 0;
    }
    uint16_t op = get_unaligned_be16(a + 6);
    uint32_t sip = get_unaligned_be32(a + 14), tip = get_unaligned_be32(a + 24);
    uint8_t sha[ETH_ALEN];
    net_memcpy(sha, a + 8, ETH_ALEN);
    kfree_skb(skb);
    arp_learn(sip, sha);
    uint32_t ours = inet_get_addr(dev);
    if (op == ARPOP_REQUEST && ours && tip == ours)
        arp_send(dev, ARPOP_REPLY, sha, sip, sha);
    return 0;
}

int arp_resolve(struct net_device *dev, uint32_t hop, uint8_t mac[ETH_ALEN])
{
    uint32_t mask = dev->ip_ptr ? dev->ip_ptr->ifa_mask : 0;
    if (hop == INADDR_BROADCAST || (mask && (hop | mask) == INADDR_BROADCAST)) {
        net_memcpy(mac, eth_broadcast_addr, ETH_ALEN);
        return 0;
    }
    static const uint8_t none[ETH_ALEN];
    if (arp_lookup(hop, mac) == 0)
        return 0;
    if (net_in_rx_action()) {
        arp_send(dev, ARPOP_REQUEST, none, hop, eth_broadcast_addr);
        return -EBUSY;
    }
    for (int attempt = 0; attempt < 4; ++attempt) {
        arp_send(dev, ARPOP_REQUEST, none, hop, eth_broadcast_addr);
        uint64_t end = t113_time_us() + 500000u;
        while (t113_time_us() < end) {
            __net_poll(dev, 20);
            if (arp_lookup(hop, mac) == 0)
                return 0;
        }
    }
    t113_uart_puts("arp: no reply from ");
    print_ip4(hop);
    t113_uart_putc('\n');
    return -ETIMEDOUT;
}
