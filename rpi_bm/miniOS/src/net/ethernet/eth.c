/*
 * Ethernet II framing, after Linux net/ethernet/eth.c.
 */
#include "device.h"
#include "net/netdevice.h"
#include "net/netutil.h"

const uint8_t eth_broadcast_addr[ETH_ALEN] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };

/* Push the Ethernet header: daddr, our address, ethertype. */
int eth_header(struct sk_buff *skb, struct net_device *dev, uint16_t type,
               const uint8_t *daddr)
{
    uint8_t *eth = skb_push(skb, ETH_HLEN);
    if (!eth)
        return -EINVAL;
    net_memcpy(eth, daddr, ETH_ALEN);
    net_memcpy(eth + ETH_ALEN, dev->dev_addr, ETH_ALEN);
    put_unaligned_be16(type, eth + 12);
    skb->dev = dev;
    return ETH_HLEN;
}

/* Classify a received frame and strip its Ethernet header. */
uint16_t eth_type_trans(struct sk_buff *skb, struct net_device *dev)
{
    const uint8_t *eth = skb->data;
    skb->dev = dev;
    if (skb->len < ETH_HLEN) {
        skb->pkt_type = PACKET_OTHERHOST;
        return 0;
    }
    if (eth[0] & 1u)
        skb->pkt_type = net_memeq(eth, eth_broadcast_addr, ETH_ALEN)
                        ? PACKET_BROADCAST : PACKET_MULTICAST;
    else if (net_memeq(eth, dev->dev_addr, ETH_ALEN))
        skb->pkt_type = PACKET_HOST;
    else
        skb->pkt_type = PACKET_OTHERHOST;
    skb->protocol = get_unaligned_be16(eth + 12);
    skb_pull(skb, ETH_HLEN);
    return skb->protocol;
}
