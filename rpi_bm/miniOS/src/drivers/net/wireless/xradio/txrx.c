/*
 * XRadio frame transmit and receive, after the xradio driver's txrx.c:
 * 802.11 frames from mac80211 become WSM TX requests, WSM RX indications
 * become skbs for ieee80211_rx_irqsafe(), and TX confirms become
 * ieee80211_tx_status().
 */
#include "platform.h"
#include "device.h"
#include "net/netutil.h"
#include "xradio.h"

/* mac80211 access category -> WSM queue. */
static const uint8_t ac_to_queue[4] = {
    [IEEE80211_AC_VO] = WSM_QUEUE_VOICE,
    [IEEE80211_AC_VI] = WSM_QUEUE_VIDEO,
    [IEEE80211_AC_BE] = WSM_QUEUE_BEST_EFFORT,
    [IEEE80211_AC_BK] = WSM_QUEUE_BACKGROUND,
};

static uint32_t rx_dropped;

int xradio_tx(struct ieee80211_hw *hw, struct sk_buff *skb)
{
    (void)hw;
    const struct ieee80211_tx_info *info = IEEE80211_SKB_CB(skb);
    uint8_t queue = ac_to_queue[info->hw_queue & 3u];
    if (info->flags & IEEE80211_TX_CTL_USE_MINRATE)
        return wsm_tx_frame(info->cookie, skb->data, skb->len, queue,
                            WSM_POLICY_MGMT, WSM_RATE_MGMT, 0);
    return wsm_tx_frame(info->cookie, skb->data, skb->len, queue,
                        WSM_POLICY_DATA, WSM_RATE_DATA, 0);
}

/* TX confirm (from the bottom half); the packet id is the cookie. */
void xradio_tx_confirm_cb(uint32_t packet_id, uint32_t status)
{
    if (status) {
        t113_uart_puts("xradio: TX confirm packet=");
        t113_uart_puthex(packet_id);
        t113_uart_puts(" status=");
        t113_uart_puthex(status);
        t113_uart_putc('\n');
    }
    if (xradio_priv.hw)
        ieee80211_tx_status(xradio_priv.hw, packet_id, (int32_t)status);
}

/*
 * RX indication (from the bottom half).  The firmware has decrypted the
 * frame but left the IV after the header and the MIC (and TKIP ICV) at
 * the end; strip them the way mac80211 expects from hardware crypto.
 */
void xradio_rx_cb(const uint8_t *msg, uint32_t len)
{
    struct ieee80211_hw *hw = xradio_priv.hw;
    if (!hw || len < WSM_HDR_LEN + WSM_RX_HDR_LEN + 10u)
        return;
    const uint8_t *rx = msg + WSM_HDR_LEN;
    const uint8_t *frame = rx + WSM_RX_HDR_LEN;
    uint32_t frame_len = len - WSM_HDR_LEN - WSM_RX_HDR_LEN;
    if (get_unaligned_le32(rx) != 0)    /* RX status: error / no key */
        return;

    uint16_t fc = get_unaligned_le16(frame);
    uint32_t enc = WSM_RX_STATUS_ENCRYPTION(get_unaligned_le32(rx + WSM_RX_FLAGS_OFFSET));
    uint32_t head = 0, tail = 0;
    uint8_t flag = 0;
    if (enc == WSM_RX_ENC_AES) {
        head = IEEE80211_CCMP_HDR_LEN;
        tail = IEEE80211_CCMP_MIC_LEN;
    } else if (enc == WSM_RX_ENC_TKIP) {
        head = IEEE80211_TKIP_IV_LEN;
        tail = IEEE80211_TKIP_TAIL_LEN;
    } else if (enc != WSM_RX_ENC_NONE || ieee80211_has_protected(fc)) {
        return;                         /* not decrypted by the firmware */
    }
    if (head)
        flag = RX_FLAG_DECRYPTED | RX_FLAG_IV_STRIPPED | RX_FLAG_MIC_STRIPPED;

    uint32_t hdrlen = ieee80211_hdrlen(fc);
    if (frame_len < hdrlen + head + tail)
        return;
    struct sk_buff *skb = alloc_skb(frame_len);
    if (!skb) {
        ++rx_dropped;
        return;
    }
    uint8_t *p = skb_put(skb, frame_len);
    if (!p) {
        kfree_skb(skb);
        ++rx_dropped;
        return;
    }
    net_memcpy(p, frame, frame_len);
    if (head) {
        net_memmove(p + head, p, hdrlen);       /* header over the IV */
        skb_pull(skb, head);
        skb_trim(skb, skb->len - tail);
    }
    struct ieee80211_rx_status *status = IEEE80211_SKB_RXCB(skb);
    status->channel = get_unaligned_le16(rx + 4);
    status->signal = rx[WSM_RX_RCPI_OFFSET];
    status->flag = flag;
    ieee80211_rx_irqsafe(hw, skb);
}
