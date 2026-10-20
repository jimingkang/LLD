#ifndef MINIOS_NET_IPCONFIG_H
#define MINIOS_NET_IPCONFIG_H

#include "net/netdevice.h"

/*
 * Kernel IPv4 autoconfiguration (DHCP client), after Linux
 * net/ipv4/ipconfig.c.  Takes the network lock itself.
 */
int ipconfig_dhcp(struct net_device *dev, int timeout_ms);

#endif
