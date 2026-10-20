/*
 * mac80211 receive path, after Linux net/mac80211/rx.c.
 *
 * The driver queues frames with ieee80211_rx_irqsafe() from its bottom
 * half; the tasklet below runs after the driver poll and dispatches
 *   beacons / probe responses while scanning -> cfg80211 BSS table
 *   other management frames                 -> MLME (auth, assoc, deauth)
 *   data frames                             -> 802.3, then EAPOL to the
 *                                              control port, the rest to
 *                                              netif_rx() once authorized
 * The driver has already decrypted and removed IV/MIC (RX_FLAG_*).
 */
#include "platform.h"
#include "device.h"
#include "net/netutil.h"
#include "ieee80211_i.h"

void ieee80211_rx_irqsafe(struct ieee80211_hw *hw, struct sk_buff *skb)
{
    skb_queue_tail(&hw_to_local(hw)->rx_queue, skb);
}

static void ieee80211_rx_data(struct ieee80211_local *local,
                              struct sk_buff *skb)
{
    const struct ieee80211_rx_status *status = IEEE80211_SKB_RXCB(skb);
    const uint8_t *hdr = skb->data;
    uint16_t fc = get_unaligned_le16(hdr);
    if ((fc & IEEE80211_STYPE_NULLFUNC) ||            /* no payload */
        (fc & (IEEE80211_FCTL_TODS | IEEE80211_FCTL_FROMDS)) !=
            IEEE80211_FCTL_FROMDS ||                  /* only from our AP */
        !net_memeq(hdr + 10, local->bss_conf.bssid, ETH_ALEN))
        goto drop;
    if (ieee80211_has_protected(fc) &&
        (status->flag & (RX_FLAG_DECRYPTED | RX_FLAG_IV_STRIPPED)) !=
            (RX_FLAG_DECRYPTED | RX_FLAG_IV_STRIPPED))
        goto drop;                      /* hardware did not decrypt it */
    int type = ieee80211_data_to_8023(skb);
    if (type < 0)
        goto drop;
    struct net_device *dev = &local->dev;
    if ((uint32_t)type == ETH_P_PAE) {
        cfg80211_rx_control_port(dev, skb->data + ETH_ALEN,
                                 skb->data + ETH_HLEN, skb->len - ETH_HLEN);
        kfree_skb(skb);
        return;
    }
    if (!local->wdev.port_authorized || skb->len - ETH_HLEN > ETH_DATA_LEN)
        goto drop;
    eth_type_trans(skb, dev);
    netif_rx(skb);
    return;
drop:
    kfree_skb(skb);
}

static void ieee80211_rx_one(struct ieee80211_local *local, struct sk_buff *skb)
{
    if (skb->len < IEEE80211_HDR_3ADDR_LEN) {
        kfree_skb(skb);
        return;
    }
    uint16_t fc = get_unaligned_le16(skb->data);
    if (ieee80211_is_mgmt(fc)) {
        if (local->scanning)
            ieee80211_scan_rx(local, skb);
        else if (local->joined)
            ieee80211_rx_mgmt(local, skb);
        kfree_skb(skb);
    } else if (ieee80211_is_data(fc) && local->joined) {
        ieee80211_rx_data(local, skb);
    } else {
        kfree_skb(skb);
    }
}

void ieee80211_rx_tasklet(struct ieee80211_local *local)
{
    struct sk_buff *skb;
    local->in_tasklet = 1;
    while ((skb = skb_dequeue(&local->rx_queue)))
        ieee80211_rx_one(local, skb);
    /* Report the scan only after its last beacons were processed. */
    if (local->scan_completed)
        ieee80211_scan_finish(local);
    local->in_tasklet = 0;
}
