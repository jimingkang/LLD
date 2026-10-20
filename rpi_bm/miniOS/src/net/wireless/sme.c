/*
 * Station SME, after Linux net/wireless/sme.c: connect = authenticate +
 * associate through the rdev (mac80211) ops, disconnect, and the data
 * port that opens once the supplicant has installed the keys.
 */
#include "platform.h"
#include "device.h"
#include "net/cfg80211.h"
#include "net/netutil.h"

void cfg80211_notify_disconnected(struct net_device *dev, uint16_t reason);

int cfg80211_connect(struct net_device *dev,
                     struct cfg80211_connect_params *params)
{
    struct wireless_dev *wdev = dev ? dev->ieee80211_ptr : 0;
    if (!wdev || !params->bss)
        return -EINVAL;
    struct wiphy *wiphy = wdev->wiphy;
    if (wdev->sme_state != CFG80211_SME_IDLE)
        cfg80211_disconnect(dev, WLAN_REASON_DEAUTH_LEAVING);

    net_memcpy(&wdev->current_bss, params->bss, sizeof(wdev->current_bss));
    wdev->sme_state = CFG80211_SME_CONNECTING;
    wdev->port_authorized = 0;

    struct cfg80211_auth_request auth = {
        .bss = &wdev->current_bss,
        .auth_type = WLAN_AUTH_OPEN,
    };
    int r = wiphy->ops->auth(wiphy, dev, &auth);
    if (r < 0 || wdev->sme_state != CFG80211_SME_CONNECTING)
        goto fail;
    struct cfg80211_assoc_request assoc = {
        .bss = &wdev->current_bss,
        .ie = params->ie,
        .ie_len = params->ie_len,
    };
    r = wiphy->ops->assoc(wiphy, dev, &assoc);
    if (r < 0 || wdev->sme_state != CFG80211_SME_CONNECTING)
        goto fail;
    wdev->sme_state = CFG80211_SME_CONNECTED;
    t113_uart_puts("cfg80211: connected to ");
    net_print_mac(wdev->current_bss.bssid);
    t113_uart_putc('\n');
    return 0;

fail:
    wiphy->ops->deauth(wiphy, dev, WLAN_REASON_DEAUTH_LEAVING);
    wdev->sme_state = CFG80211_SME_IDLE;
    return r < 0 ? r : -EIO;
}

void cfg80211_disconnect(struct net_device *dev, uint16_t reason)
{
    struct wireless_dev *wdev = dev ? dev->ieee80211_ptr : 0;
    if (!wdev)
        return;
    /* Also tidies a device left joined after the AP dropped us. */
    wdev->wiphy->ops->deauth(wdev->wiphy, dev, reason);
    wdev->sme_state = CFG80211_SME_IDLE;
    wdev->port_authorized = 0;
    netif_carrier_off(dev);
}

void cfg80211_disconnected(struct net_device *dev, uint16_t reason)
{
    struct wireless_dev *wdev = dev ? dev->ieee80211_ptr : 0;
    if (!wdev || wdev->sme_state == CFG80211_SME_IDLE)
        return;
    t113_uart_puts("cfg80211: disconnected by AP, reason ");
    net_putdec(reason);
    t113_uart_putc('\n');
    wdev->sme_state = CFG80211_SME_IDLE;
    wdev->port_authorized = 0;
    netif_carrier_off(dev);
    cfg80211_notify_disconnected(dev, reason);
}

void cfg80211_port_authorized(struct net_device *dev)
{
    struct wireless_dev *wdev = dev ? dev->ieee80211_ptr : 0;
    if (!wdev || wdev->sme_state != CFG80211_SME_CONNECTED)
        return;
    wdev->port_authorized = 1;
    netif_carrier_on(dev);
}
