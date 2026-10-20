/*
 * mac80211 transmit path, after Linux net/mac80211/tx.c:
 *   ieee80211_subif_start_xmit()  Ethernet frame from the stack -> 802.11
 *   ieee80211_tx_control_port()   EAPOL from the supplicant
 *   ieee80211_tx_skb()            hand a finished frame to the driver
 *
 * Data frames go to the AP (ToDS) with an RFC 1042 LLC/SNAP header.  Once
 * the pairwise key is installed they are marked Protected and carry room
 * for the CCMP header and MIC, which the hardware fills in.
 */
#include "platform.h"
#include "device.h"
#include "net/netutil.h"
#include "ieee80211_i.h"

int ieee80211_tx_skb(struct ieee80211_local *local, struct sk_buff *skb,
                     uint8_t ac, uint8_t flags, int control_port,
                     uint32_t *cookie)
{
    uint32_t id = ++local->next_cookie;
    if (!id)
        id = ++local->next_cookie;
    struct ieee80211_tx_info *info = IEEE80211_SKB_CB(skb);
    info->cookie = id;
    info->hw_queue = ac;
    info->flags = flags;
    uint32_t slot = id % TX_STATUS_SLOTS;
    local->tx_status[slot].cookie = id;
    local->tx_status[slot].status = TX_STATUS_PENDING;
    local->tx_status[slot].control_port = control_port != 0;
    int r = local->hw.ops->tx(&local->hw, skb);
    kfree_skb(skb);                     /* the driver copied it */
    if (cookie)
        *cookie = id;
    return r < 0 ? r : 0;
}

void ieee80211_tx_status(struct ieee80211_hw *hw, uint32_t cookie, int status)
{
    struct ieee80211_local *local = hw_to_local(hw);
    uint32_t slot = cookie % TX_STATUS_SLOTS;
    if (local->tx_status[slot].cookie != cookie)
        return;
    local->tx_status[slot].status = status;
    if (local->tx_status[slot].control_port)
        cfg80211_control_port_tx_status(&local->dev, cookie, status == 0);
}

int ieee80211_wait_tx_status(struct ieee80211_local *local, uint32_t cookie,
                             int timeout_ms)
{
    uint32_t slot = cookie % TX_STATUS_SLOTS;
    uint64_t end = t113_time_us() + (uint64_t)timeout_ms * 1000u;
    while (local->tx_status[slot].cookie == cookie &&
           local->tx_status[slot].status == TX_STATUS_PENDING &&
           t113_time_us() < end)
        __net_poll(&local->dev, 5);
    if (local->tx_status[slot].cookie != cookie)
        return TX_STATUS_PENDING;
    return local->tx_status[slot].status;
}

static uint8_t *put_hdr(struct ieee80211_local *local, struct sk_buff *skb,
                        uint16_t fc, const uint8_t *a1, const uint8_t *a3)
{
    uint8_t *h = skb_push(skb, IEEE80211_HDR_3ADDR_LEN);
    if (!h)
        return 0;
    put_unaligned_le16(fc, h);
    put_unaligned_le16(0, h + 2);       /* duration: filled by hardware */
    net_memcpy(h + 4, a1, ETH_ALEN);
    net_memcpy(h + 10, local->dev.dev_addr, ETH_ALEN);
    net_memcpy(h + 16, a3, ETH_ALEN);
    put_unaligned_le16((uint32_t)(local->seq++ & 0x0fffu) << 4, h + 22);
    return h;
}

uint8_t *ieee80211_build_mgmt_hdr(struct ieee80211_local *local,
                                  struct sk_buff *skb, uint16_t stype)
{
    return put_hdr(local, skb, IEEE80211_FTYPE_MGMT | stype,
                   local->bss_conf.bssid, local->bss_conf.bssid);
}

int ieee80211_build_data_hdr(struct ieee80211_local *local,
                             struct sk_buff *skb, const uint8_t *da,
                             uint16_t ethertype)
{
    static const uint8_t rfc1042[6] = { 0xaa, 0xaa, 0x03, 0x00, 0x00, 0x00 };
    int protect = local->ptk_set;
    uint8_t *llc = skb_push(skb, 8);
    if (!llc)
        return -EINVAL;
    net_memcpy(llc, rfc1042, 6);
    put_unaligned_be16(ethertype, llc + 6);
    if (protect) {
        uint8_t *iv = skb_push(skb, IEEE80211_CCMP_HDR_LEN);
        uint8_t *mic = skb_put(skb, IEEE80211_CCMP_MIC_LEN);
        if (!iv || !mic)
            return -EINVAL;
        net_memset(iv, 0, IEEE80211_CCMP_HDR_LEN);
        net_memset(mic, 0, IEEE80211_CCMP_MIC_LEN);
    }
    uint16_t fc = IEEE80211_FTYPE_DATA | IEEE80211_STYPE_DATA |
                  IEEE80211_FCTL_TODS | (protect ? IEEE80211_FCTL_PROTECTED : 0);
    return put_hdr(local, skb, fc, local->bss_conf.bssid, da) ? 0 : -EINVAL;
}

int ieee80211_subif_start_xmit(struct sk_buff *skb, struct net_device *dev)
{
    struct ieee80211_local *local = dev->ml_priv;
    if (!local->associated || skb->len < ETH_HLEN) {
        kfree_skb(skb);
        return -ENODEV;
    }
    uint8_t da[ETH_ALEN];
    net_memcpy(da, skb->data, ETH_ALEN);
    uint16_t type = get_unaligned_be16(skb->data + 12);
    skb_pull(skb, ETH_HLEN);
    if (ieee80211_build_data_hdr(local, skb, da, type) < 0) {
        kfree_skb(skb);
        return -EINVAL;
    }
    return ieee80211_tx_skb(local, skb, IEEE80211_AC_BE, 0, 0, 0);
}

int ieee80211_tx_control_port(struct wiphy *wiphy, struct net_device *dev,
                              const uint8_t *buf, uint32_t len,
                              const uint8_t *dest, uint16_t proto,
                              uint32_t *cookie)
{
    struct ieee80211_local *local = wiphy_to_local(wiphy);
    (void)dev;
    /* EAPOL message 1 can arrive with the association response, before
     * the association is complete on our side: only require the join. */
    if (!local->joined)
        return -ENODEV;
    struct sk_buff *skb = alloc_skb(len + IEEE80211_CCMP_MIC_LEN);
    if (!skb)
        return -ENOSPC;
    net_memcpy(skb_put(skb, len), buf, len);
    if (ieee80211_build_data_hdr(local, skb, dest, proto) < 0) {
        kfree_skb(skb);
        return -EINVAL;
    }
    /* EAPOL: highest priority queue at the lowest rate. */
    return ieee80211_tx_skb(local, skb, IEEE80211_AC_VO,
                            IEEE80211_TX_CTL_USE_MINRATE, 1, cookie);
}
