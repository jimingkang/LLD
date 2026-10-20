#ifndef MINIOS_NET_NETDEVICE_H
#define MINIOS_NET_NETDEVICE_H

#include <stdint.h>
#include "net/if_ether.h"
#include "net/skbuff.h"

/*
 * Network devices and the core receive/transmit path, after Linux
 * include/linux/netdevice.h and net/core/dev.c.
 *
 *   driver RX  -> netif_rx(skb)        queue on the backlog
 *   net_rx_action()                    backlog -> packet_type handlers
 *                                      (ETH_P_IP -> ip_rcv, ETH_P_ARP -> arp_rcv)
 *   protocol TX -> dev_queue_xmit(skb) -> dev->netdev_ops->ndo_start_xmit
 *
 * miniOS has no network interrupts, softirqs or workqueues.  Everything
 * runs inside __net_poll(): it lets the device receive (ndo_poll, in the
 * role of a NAPI poll), then runs net_rx_action() and the scheduled
 * net_work items.  Callers that wait for the network (ARP, UDP receive,
 * DHCP, the WiFi connect sequence) loop on __net_poll().
 *
 * Locking: one big network lock, rtnl_lock(), serialises every entry
 * point (a socket call, a connect, a poll).  Functions named __xxx expect
 * the caller to hold it; the lock is not recursive.
 */

#define IFNAMSIZ 16u

struct net_device;
struct wireless_dev;
struct in_device;

struct net_device_ops {
    /* Transmit one Ethernet II frame (no FCS).  Always consumes skb. */
    int (*ndo_start_xmit)(struct sk_buff *skb, struct net_device *dev);
    /* miniOS: receive for up to timeout_ms, handing frames to netif_rx().
     * Stands in for the RX interrupt + NAPI poll. */
    int (*ndo_poll)(struct net_device *dev, int timeout_ms);
};

struct net_device {
    char name[IFNAMSIZ];
    uint8_t dev_addr[ETH_ALEN];
    uint32_t mtu;
    const struct net_device_ops *netdev_ops;
    struct wireless_dev *ieee80211_ptr;  /* set for 802.11 devices */
    struct in_device *ip_ptr;            /* IPv4 configuration */
    void *ml_priv;                       /* owned by the layer below */
    uint32_t carrier;
    uint32_t rx_packets, tx_packets, rx_dropped, tx_dropped;
    struct net_device *next;
};

/* Protocol handlers (dev_add_pack), matched on skb->protocol. */
struct packet_type {
    uint16_t type;                       /* ETH_P_* */
    int (*func)(struct sk_buff *skb, struct net_device *dev);
    struct packet_type *next;
};

/* Netdevice notifier events. */
#define NETDEV_REGISTER  1u
#define NETDEV_CHANGE    2u              /* carrier changed */

struct notifier_block {
    int (*notifier_call)(struct notifier_block *nb, uint32_t event,
                         struct net_device *dev);
    struct notifier_block *next;
};

/* Deferred work run at the end of every __net_poll() (schedule_work). */
struct net_work {
    void (*func)(struct net_work *work);
    uint32_t pending;
    struct net_work *next;
};

/* Subsystem start-up: stands in for the initcalls (inet_init, ...). */
void net_init(void);

int register_netdev(struct net_device *dev);
struct net_device *dev_get_by_name(const char *name);
/* The first registered device (miniOS routes everything through it). */
struct net_device *dev_get_default(void);

int register_netdevice_notifier(struct notifier_block *nb);
void dev_add_pack(struct packet_type *pt);

void netif_carrier_on(struct net_device *dev);
void netif_carrier_off(struct net_device *dev);
static inline int netif_carrier_ok(const struct net_device *dev)
{
    return dev && dev->carrier;
}

/* Driver RX: skb->data at the Ethernet header, eth_type_trans() done. */
int netif_rx(struct sk_buff *skb);
/* Protocol TX: skb->dev set, skb->data at the Ethernet header. */
int dev_queue_xmit(struct sk_buff *skb);

void net_schedule_work(struct net_work *work);

void rtnl_lock(void);
void rtnl_unlock(void);
/* Receive and process for up to timeout_ms; takes the network lock. */
int net_poll(struct net_device *dev, int timeout_ms);
/* Same with the lock already held. */
int __net_poll(struct net_device *dev, int timeout_ms);
/* Nonzero while net_rx_action() runs protocol handlers: code that would
 * otherwise wait on the network (ARP) must not recurse into __net_poll. */
int net_in_rx_action(void);

/* net/ethernet/eth.c */
int eth_header(struct sk_buff *skb, struct net_device *dev, uint16_t type,
               const uint8_t *daddr);
uint16_t eth_type_trans(struct sk_buff *skb, struct net_device *dev);
extern const uint8_t eth_broadcast_addr[ETH_ALEN];

#endif
