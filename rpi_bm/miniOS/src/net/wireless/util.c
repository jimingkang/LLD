/*
 * 802.11 helpers, after Linux net/wireless/util.c: header length and
 * the 802.11 -> 802.3 conversion of received data frames.
 */
#include "net/cfg80211.h"
#include "net/netutil.h"

uint32_t ieee80211_hdrlen(uint16_t fc)
{
    uint32_t len = IEEE80211_HDR_3ADDR_LEN;
    if (ieee80211_is_data(fc)) {
        if ((fc & (IEEE80211_FCTL_TODS | IEEE80211_FCTL_FROMDS)) ==
            (IEEE80211_FCTL_TODS | IEEE80211_FCTL_FROMDS))
            len += ETH_ALEN;            /* addr4 */
        if (ieee80211_is_data_qos(fc)) {
            len += IEEE80211_QOS_CTL_LEN;
            if (fc & IEEE80211_FCTL_ORDER)
                len += IEEE80211_HT_CTL_LEN;
        }
    } else if (ieee80211_is_mgmt(fc) && (fc & IEEE80211_FCTL_ORDER)) {
        len += IEEE80211_HT_CTL_LEN;
    }
    return len;
}

/*
 * [802.11 header][aa aa 03 00 00 00][type][payload] becomes
 * [DA][SA][type][payload]: the ethertype is already in place, so only
 * the addresses are written in front of it.
 */
int ieee80211_data_to_8023(struct sk_buff *skb)
{
    static const uint8_t rfc1042[6] = { 0xaa, 0xaa, 0x03, 0x00, 0x00, 0x00 };
    const uint8_t *hdr = skb->data;
    uint16_t fc = get_unaligned_le16(hdr);
    uint32_t hdrlen = ieee80211_hdrlen(fc);
    if (skb->len < hdrlen + 8u || !net_memeq(hdr + hdrlen, rfc1042, 6))
        return -1;
    uint8_t da[ETH_ALEN], sa[ETH_ALEN];
    uint32_t ds = fc & (IEEE80211_FCTL_TODS | IEEE80211_FCTL_FROMDS);
    net_memcpy(da, ds & IEEE80211_FCTL_TODS ? hdr + 16 : hdr + 4, ETH_ALEN);
    net_memcpy(sa, ds == IEEE80211_FCTL_FROMDS ? hdr + 16
                 : ds == (IEEE80211_FCTL_TODS | IEEE80211_FCTL_FROMDS) ? hdr + 24
                 : hdr + 10, ETH_ALEN);
    uint16_t type = get_unaligned_be16(hdr + hdrlen + 6);
    skb_pull(skb, hdrlen + 8u - ETH_HLEN);
    net_memcpy(skb->data, da, ETH_ALEN);
    net_memcpy(skb->data + ETH_ALEN, sa, ETH_ALEN);
    return type;
}

uint32_t ieee80211_rate_bit(const struct wiphy *wiphy, uint8_t rate)
{
    uint32_t bitrate = (uint32_t)(rate & 0x7fu) * 5u;   /* -> 100 kb/s */
    for (uint32_t i = 0; i < wiphy->n_bitrates; ++i)
        if (wiphy->bitrates[i].bitrate == bitrate)
            return 1u << wiphy->bitrates[i].hw_value;
    return 0;
}
