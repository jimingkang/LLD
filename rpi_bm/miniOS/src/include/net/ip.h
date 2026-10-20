#ifndef MINIOS_NET_IP_H
#define MINIOS_NET_IP_H

#include <stdint.h>
#include "net/netdevice.h"

/*
 * IPv4, after Linux net/ipv4 (ip_input.c, ip_output.c, devinet.c).
 * Addresses are kept in host byte order: 192.168.1.2 is 0xc0a80102.
 * There is no routing table: everything leaves through the default
 * device, to the gateway when the destination is off-link.
 */

#define IPPROTO_ICMP    1u
#define IPPROTO_UDP     17u
#define IP_HLEN         20u      /* we never send options */
#define INADDR_BROADCAST 0xffffffffu

/* Per-device IPv4 configuration (Linux struct in_device / in_ifaddr). */
struct in_device {
    uint32_t ifa_address;
    uint32_t ifa_mask;
    uint32_t gateway;
    uint16_t ip_id;
};

void inet_init(void);

/* skb->data at the transport header; pushes the IPv4 header, resolves the
 * next hop and transmits.  Always consumes skb. */
int ip_queue_xmit(struct sk_buff *skb, uint32_t daddr, uint8_t protocol);
/* Internet checksum (ones' complement of the ones' complement sum). */
uint16_t ip_compute_csum(const uint8_t *p, uint32_t len);

/* devinet.c: address configuration ("ifconfig") */
int inet_set_addr(struct net_device *dev, uint32_t ip, uint32_t mask,
                  uint32_t gateway);
uint32_t inet_get_addr(const struct net_device *dev);
void inet_print_status(const struct net_device *dev);
/* Dotted quad <-> host order.  in4_pton returns 0 on success. */
int in4_pton(const char *text, uint32_t *ip);
void print_ip4(uint32_t ip);

#endif
