/*
 * IPv4 protocol family start-up, after Linux net/ipv4/af_inet.c
 * inet_init(): register the IP and ARP packet handlers with the core.
 */
#include "net/netdevice.h"
#include "net/ip.h"
#include "net/arp.h"

int ip_rcv(struct sk_buff *skb, struct net_device *dev);
void devinet_init(void);

static struct packet_type ip_packet_type = {
    .type = ETH_P_IP,
    .func = ip_rcv,
};

static struct packet_type arp_packet_type = {
    .type = ETH_P_ARP,
    .func = arp_rcv,
};

void inet_init(void)
{
    devinet_init();
    dev_add_pack(&ip_packet_type);
    dev_add_pack(&arp_packet_type);
}
