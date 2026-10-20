/*
 * Network device core, after Linux net/core/dev.c: device registration,
 * notifiers, the receive backlog (netif_rx -> net_rx_action -> protocol
 * handlers), transmit (dev_queue_xmit) and the polled stand-ins for
 * NAPI, softirqs and workqueues.  See include/net/netdevice.h.
 */
#include "platform.h"
#include "device.h"
#include "mutex.h"
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/ip.h"
#ifdef CONFIG_WPA2_PSK
#include "net/wpa.h"
#endif

static struct mutex rtnl_mutex = MUTEX_INIT;
static struct net_device *dev_base;
static struct packet_type *ptype_base;
static struct notifier_block *netdev_chain;
static struct net_work *work_list;
static struct sk_buff_head backlog;
static uint32_t in_rx_action;

void rtnl_lock(void)
{
    mutex_lock(&rtnl_mutex);
}

void rtnl_unlock(void)
{
    mutex_unlock(&rtnl_mutex);
}

/* Subsystem initialisation in dependency order; Linux uses initcalls. */
void net_init(void)
{
    skb_queue_head_init(&backlog);
    inet_init();
#ifdef CONFIG_WPA2_PSK
    wpa_supplicant_init();
#endif
}

static void call_netdevice_notifiers(uint32_t event, struct net_device *dev)
{
    for (struct notifier_block *nb = netdev_chain; nb; nb = nb->next)
        nb->notifier_call(nb, event, dev);
}

int register_netdevice_notifier(struct notifier_block *nb)
{
    struct notifier_block **p = &netdev_chain;
    while (*p)
        p = &(*p)->next;
    nb->next = 0;
    *p = nb;
    /* Replay registrations for devices that already exist. */
    for (struct net_device *dev = dev_base; dev; dev = dev->next)
        nb->notifier_call(nb, NETDEV_REGISTER, dev);
    return 0;
}

int register_netdev(struct net_device *dev)
{
    if (!dev || !dev->netdev_ops || dev_get_by_name(dev->name))
        return -EINVAL;
    if (!dev->mtu)
        dev->mtu = ETH_DATA_LEN;
    struct net_device **p = &dev_base;
    while (*p)
        p = &(*p)->next;
    dev->next = 0;
    *p = dev;
    t113_uart_puts("net: ");
    t113_uart_puts(dev->name);
    t113_uart_puts(" registered, hwaddr ");
    net_print_mac(dev->dev_addr);
    t113_uart_putc('\n');
    call_netdevice_notifiers(NETDEV_REGISTER, dev);
    return 0;
}

struct net_device *dev_get_by_name(const char *name)
{
    for (struct net_device *dev = dev_base; dev; dev = dev->next) {
        uint32_t i = 0;
        while (i < IFNAMSIZ && dev->name[i] && dev->name[i] == name[i])
            ++i;
        if (i < IFNAMSIZ && dev->name[i] == name[i])
            return dev;
    }
    return 0;
}

struct net_device *dev_get_default(void)
{
    return dev_base;
}

void dev_add_pack(struct packet_type *pt)
{
    pt->next = ptype_base;
    ptype_base = pt;
}

void netif_carrier_on(struct net_device *dev)
{
    if (dev->carrier)
        return;
    dev->carrier = 1;
    t113_uart_puts(dev->name);
    t113_uart_puts(": link up\n");
    call_netdevice_notifiers(NETDEV_CHANGE, dev);
}

void netif_carrier_off(struct net_device *dev)
{
    if (!dev->carrier)
        return;
    dev->carrier = 0;
    t113_uart_puts(dev->name);
    t113_uart_puts(": link down\n");
    call_netdevice_notifiers(NETDEV_CHANGE, dev);
}

/* ------------------------------------------------------------ receive */

int netif_rx(struct sk_buff *skb)
{
    if (!skb->dev) {
        kfree_skb(skb);
        return -EINVAL;
    }
    ++skb->dev->rx_packets;
    skb_queue_tail(&backlog, skb);
    return 0;
}

static void deliver_skb(struct sk_buff *skb)
{
    if (skb->pkt_type == PACKET_OTHERHOST) {
        kfree_skb(skb);
        return;
    }
    for (struct packet_type *pt = ptype_base; pt; pt = pt->next) {
        if (pt->type == skb->protocol) {
            pt->func(skb, skb->dev);       /* consumes skb */
            return;
        }
    }
    ++skb->dev->rx_dropped;
    kfree_skb(skb);
}

/* The NET_RX softirq: hand every queued frame to its protocol. */
static void net_rx_action(void)
{
    struct sk_buff *skb;
    in_rx_action = 1;
    while ((skb = skb_dequeue(&backlog)))
        deliver_skb(skb);
    in_rx_action = 0;
}

int net_in_rx_action(void)
{
    return in_rx_action != 0;
}

/* ----------------------------------------------------------- transmit */

int dev_queue_xmit(struct sk_buff *skb)
{
    struct net_device *dev = skb->dev;
    if (!dev || !netif_carrier_ok(dev)) {
        if (dev)
            ++dev->tx_dropped;
        kfree_skb(skb);
        return -ENODEV;
    }
    ++dev->tx_packets;
    return dev->netdev_ops->ndo_start_xmit(skb, dev);
}

/* --------------------------------------------------------------- work */

void net_schedule_work(struct net_work *work)
{
    if (work->pending)
        return;
    work->pending = 1;
    work->next = work_list;
    work_list = work;
}

static void run_net_work(void)
{
    struct net_work *list = work_list;
    work_list = 0;
    while (list) {
        struct net_work *w = list;
        list = w->next;
        w->pending = 0;
        w->func(w);                     /* may reschedule itself */
    }
}

/* --------------------------------------------------------------- poll */

int __net_poll(struct net_device *dev, int timeout_ms)
{
    if (!dev)
        dev = dev_base;
    if (!dev)
        return -ENODEV;
    int r = dev->netdev_ops->ndo_poll ? dev->netdev_ops->ndo_poll(dev, timeout_ms)
                                      : 0;
    if (!in_rx_action) {
        net_rx_action();
        run_net_work();
    }
    return r;
}

int net_poll(struct net_device *dev, int timeout_ms)
{
    rtnl_lock();
    int r = __net_poll(dev, timeout_ms);
    rtnl_unlock();
    return r;
}
