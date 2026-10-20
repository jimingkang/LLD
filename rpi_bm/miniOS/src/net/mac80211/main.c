/*
 * mac80211 hardware registration, after Linux net/mac80211/main.c and
 * iface.c: allocate the local state, register the wiphy and the wlan0
 * network device, and poll the driver (the miniOS stand-in for its
 * interrupt + the mac80211 tasklet).
 */
#include "platform.h"
#include "device.h"
#include "net/netutil.h"
#include "ieee80211_i.h"

static struct ieee80211_local local0;
static uint32_t local0_used;

static int ieee80211_poll(struct net_device *dev, int timeout_ms)
{
    struct ieee80211_local *local = dev->ml_priv;
    int r = local->hw.ops->poll(&local->hw, timeout_ms);
    if (!local->in_tasklet)
        ieee80211_rx_tasklet(local);
    return r;
}

static const struct net_device_ops ieee80211_dataif_ops = {
    .ndo_start_xmit = ieee80211_subif_start_xmit,
    .ndo_poll = ieee80211_poll,
};

struct ieee80211_hw *ieee80211_alloc_hw(const struct ieee80211_ops *ops,
                                        void *priv)
{
    if (local0_used || !ops)
        return 0;
    local0_used = 1;
    net_memset(&local0, 0, sizeof(local0));
    local0.hw.ops = ops;
    local0.hw.priv = priv;
    skb_queue_head_init(&local0.rx_queue);
    return &local0.hw;
}

int ieee80211_register_hw(struct ieee80211_hw *hw, const uint8_t addr[ETH_ALEN],
                          const struct ieee80211_rate *rates, uint32_t n_rates)
{
    struct ieee80211_local *local = hw_to_local(hw);
    struct wiphy *wiphy = wiphy_new(&mac80211_config_ops, local);
    if (!wiphy)
        return -EBUSY;
    hw->wiphy = wiphy;
    net_memcpy(wiphy->perm_addr, addr, ETH_ALEN);
    wiphy->bitrates = rates;
    wiphy->n_bitrates = n_rates;
    int r = wiphy_register(wiphy);
    if (r < 0)
        return r;

    struct net_device *dev = &local->dev;
    net_memcpy(dev->name, "wlan0", 6);
    net_memcpy(dev->dev_addr, addr, ETH_ALEN);
    dev->netdev_ops = &ieee80211_dataif_ops;
    dev->ml_priv = local;
    cfg80211_init_wdev(&local->wdev, wiphy, dev);

    if ((r = hw->ops->start(hw)) < 0) {
        t113_uart_puts("mac80211: driver start failed\n");
        return r;
    }
    return register_netdev(dev);
}

void ieee80211_beacon_loss(struct ieee80211_hw *hw)
{
    struct ieee80211_local *local = hw_to_local(hw);
    if (local->associated) {
        t113_uart_puts(local->dev.name);
        t113_uart_puts(": beacons lost\n");
    }
}
