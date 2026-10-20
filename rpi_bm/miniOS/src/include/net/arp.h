#ifndef MINIOS_NET_ARP_H
#define MINIOS_NET_ARP_H

#include <stdint.h>
#include "net/netdevice.h"

/* ARP and the neighbour cache, after Linux net/ipv4/arp.c. */

int arp_rcv(struct sk_buff *skb, struct net_device *dev);
/*
 * Ethernet address of an on-link IPv4 next hop.  Broadcast addresses
 * resolve at once; otherwise the cache is consulted and, outside the
 * receive path, ARP requests are sent while polling for a reply.
 */
int arp_resolve(struct net_device *dev, uint32_t nexthop,
                uint8_t mac[ETH_ALEN]);

#endif
