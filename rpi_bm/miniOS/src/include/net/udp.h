#ifndef MINIOS_NET_UDP_H
#define MINIOS_NET_UDP_H

#include <stdint.h>
#include "net/netdevice.h"
#include "net/ip.h"

/*
 * UDP, after Linux net/ipv4/udp.c, with a minimal in-kernel socket API
 * in place of the BSD socket layer.  Each socket queues up to
 * UDP_QUEUE received datagrams.
 */

#define UDP_HLEN        8u
#define UDP_PAYLOAD_MAX (ETH_DATA_LEN - IP_HLEN - UDP_HLEN)

void udp_rcv(struct sk_buff *skb, uint32_t saddr);

struct udp_sock;
/* local_port 0 picks an ephemeral port. */
struct udp_sock *udp_open(uint16_t local_port);
int udp_sendto(struct udp_sock *s, uint32_t ip, uint16_t port,
               const void *data, uint32_t len);
/* Bytes received, 0 on timeout, <0 on error. */
int udp_recvfrom(struct udp_sock *s, void *buf, uint32_t capacity,
                 uint32_t *ip, uint16_t *port, int timeout_ms);
void udp_close(struct udp_sock *s);

#endif
