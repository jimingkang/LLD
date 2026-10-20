/*
 * cfg80211 core, after Linux net/wireless/core.c: the wiphy, the
 * wireless_dev attached to each 802.11 netdev, and the control port
 * that carries EAPOL between the device and the supplicant (what
 * nl80211's CMD_CONTROL_PORT_FRAME does for wpa_supplicant).
 */
#include "platform.h"
#include "device.h"
#include "net/cfg80211.h"
#include "net/netutil.h"

static struct wiphy wiphy0;
static uint32_t wiphy0_used;
static const struct cfg80211_control_port_ops *control_port;

struct wiphy *wiphy_new(const struct cfg80211_ops *ops, void *priv)
{
    if (wiphy0_used)
        return 0;                       /* one radio in miniOS */
    wiphy0_used = 1;
    net_memset(&wiphy0, 0, sizeof(wiphy0));
    wiphy0.ops = ops;
    wiphy0.priv = priv;
    return &wiphy0;
}

int wiphy_register(struct wiphy *wiphy)
{
    t113_uart_puts("cfg80211: phy0 registered, ");
    net_putdec(wiphy->n_bitrates);
    t113_uart_puts(" bitrates\n");
    return 0;
}

void cfg80211_init_wdev(struct wireless_dev *wdev, struct wiphy *wiphy,
                        struct net_device *dev)
{
    net_memset(wdev, 0, sizeof(*wdev));
    wdev->wiphy = wiphy;
    wdev->netdev = dev;
    wdev->sme_state = CFG80211_SME_IDLE;
    dev->ieee80211_ptr = wdev;
}

void cfg80211_set_control_port_ops(const struct cfg80211_control_port_ops *ops)
{
    control_port = ops;
}

int cfg80211_add_key(struct net_device *dev, uint8_t key_index, int pairwise,
                     const uint8_t *mac_addr, struct key_params *params)
{
    struct wireless_dev *wdev = dev ? dev->ieee80211_ptr : 0;
    if (!wdev || wdev->sme_state == CFG80211_SME_IDLE)
        return -ENODEV;
    return wdev->wiphy->ops->add_key(wdev->wiphy, dev, key_index, pairwise,
                                     mac_addr, params);
}

int cfg80211_tx_control_port(struct net_device *dev, const uint8_t *buf,
                             uint32_t len, const uint8_t *dest,
                             uint16_t proto, uint32_t *cookie)
{
    struct wireless_dev *wdev = dev ? dev->ieee80211_ptr : 0;
    if (!wdev || wdev->sme_state == CFG80211_SME_IDLE)
        return -ENODEV;
    return wdev->wiphy->ops->tx_control_port(wdev->wiphy, dev, buf, len,
                                             dest, proto, cookie);
}

void cfg80211_rx_control_port(struct net_device *dev, const uint8_t *src,
                              const uint8_t *frame, uint32_t len)
{
    if (control_port && control_port->rx)
        control_port->rx(dev, src, frame, len);
}

void cfg80211_control_port_tx_status(struct net_device *dev, uint32_t cookie,
                                     int acked)
{
    if (control_port && control_port->tx_status)
        control_port->tx_status(dev, cookie, acked);
}

void cfg80211_notify_disconnected(struct net_device *dev, uint16_t reason)
{
    if (control_port && control_port->disconnected)
        control_port->disconnected(dev, reason);
}
