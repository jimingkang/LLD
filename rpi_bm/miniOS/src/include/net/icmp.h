#ifndef MINIOS_NET_ICMP_H
#define MINIOS_NET_ICMP_H

#include <stdint.h>
#include "net/netdevice.h"

/* ICMP echo, after Linux net/ipv4/icmp.c (and ping.c for the sender). */

void icmp_rcv(struct sk_buff *skb, uint32_t saddr);
/* Send one echo request; returns the round trip in microseconds or <0. */
int icmp_ping(uint32_t daddr, int timeout_ms);

#endif
