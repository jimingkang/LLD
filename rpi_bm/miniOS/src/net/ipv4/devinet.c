/*
 * IPv4 per-device configuration, after Linux net/ipv4/devinet.c: every
 * registered device gets an in_device holding its address, netmask and
 * (miniOS has no routing table) default gateway.
 */
#include "platform.h"
#include "device.h"
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/ip.h"

#define MAX_IN_DEVICES 2u

static struct in_device in_devices[MAX_IN_DEVICES];
static uint32_t in_devices_used;

static int inetdev_event(struct notifier_block *nb, uint32_t event,
                         struct net_device *dev)
{
    (void)nb;
    if (event == NETDEV_REGISTER && !dev->ip_ptr &&
        in_devices_used < MAX_IN_DEVICES) {
        struct in_device *in = &in_devices[in_devices_used++];
        in->ifa_address = in->ifa_mask = in->gateway = 0;
        in->ip_id = 0;
        dev->ip_ptr = in;
    }
    return 0;
}

static struct notifier_block ip_netdev_notifier = {
    .notifier_call = inetdev_event,
};

void devinet_init(void)
{
    register_netdevice_notifier(&ip_netdev_notifier);
}

int inet_set_addr(struct net_device *dev, uint32_t ip, uint32_t mask,
                  uint32_t gateway)
{
    if (!dev || !dev->ip_ptr)
        return -ENODEV;
    dev->ip_ptr->ifa_address = ip;
    dev->ip_ptr->ifa_mask = mask;
    dev->ip_ptr->gateway = gateway;
    return 0;
}

uint32_t inet_get_addr(const struct net_device *dev)
{
    return dev && dev->ip_ptr ? dev->ip_ptr->ifa_address : 0;
}

void inet_print_status(const struct net_device *dev)
{
    if (!dev) {
        t113_uart_puts("net: no interface\n");
        return;
    }
    t113_uart_puts(dev->name);
    t113_uart_puts(": hwaddr ");
    net_print_mac(dev->dev_addr);
    t113_uart_puts(netif_carrier_ok(dev) ? " link up" : " link down");
    if (dev->ip_ptr) {
        t113_uart_puts("\n  inet ");
        print_ip4(dev->ip_ptr->ifa_address);
        t113_uart_puts(" netmask ");
        print_ip4(dev->ip_ptr->ifa_mask);
        t113_uart_puts(" gateway ");
        print_ip4(dev->ip_ptr->gateway);
    }
    t113_uart_puts("\n  rx packets ");
    net_putdec(dev->rx_packets);
    t113_uart_puts(" dropped ");
    net_putdec(dev->rx_dropped);
    t113_uart_puts("  tx packets ");
    net_putdec(dev->tx_packets);
    t113_uart_puts(" dropped ");
    net_putdec(dev->tx_dropped);
    t113_uart_putc('\n');
}
