#ifndef MINIOS_NET_MAC80211_H
#define MINIOS_NET_MAC80211_H

#include <stdint.h>
#include "net/cfg80211.h"

/*
 * mac80211: the SoftMAC layer between cfg80211/the network stack and a
 * device driver, after Linux include/net/mac80211.h and net/mac80211/.
 *
 * mac80211 builds management frames (auth, assoc, deauth), converts data
 * frames between Ethernet and 802.11, tracks keys and implements the
 * cfg80211_ops.  The driver implements ieee80211_ops and only moves
 * frames and commands to and from the hardware.
 *
 * Contexts: the driver calls ieee80211_rx_irqsafe(), ieee80211_tx_status()
 * and ieee80211_scan_completed() from its bottom half (inside ops->poll);
 * they only queue or record.  Frames are processed afterwards by the
 * mac80211 RX tasklet, which may transmit and issue driver commands.
 */

struct ieee80211_hw {
    struct wiphy *wiphy;
    const struct ieee80211_ops *ops;
    void *priv;                  /* driver private data */
};

/* BSS state handed to the driver (struct ieee80211_bss_conf). */
struct ieee80211_bss_conf {
    uint8_t bssid[ETH_ALEN];
    uint16_t channel;
    uint8_t ssid[32];
    uint8_t ssid_len;
    uint8_t dtim_period;
    uint16_t beacon_int;
    uint32_t basic_rates;        /* BIT(hw_value) */
    uint32_t supp_rates;         /* BIT(hw_value), all rates of the BSS */
    uint16_t aid;
    uint32_t use_short_preamble;
    uint32_t use_short_slot;
    uint32_t assoc;
};

#define BSS_CHANGED_BSSID   (1u << 0)    /* join this BSS */
#define BSS_CHANGED_ASSOC   (1u << 1)    /* association state changed */

enum set_key_cmd { SET_KEY, DISABLE_KEY };

struct ieee80211_key_conf {
    uint32_t cipher;             /* WLAN_CIPHER_SUITE_* */
    uint8_t keyidx;              /* 802.11 key id */
    uint8_t pairwise;
    uint8_t hw_key_idx;          /* chosen by the driver in set_key */
    uint8_t keylen;
    uint8_t key[32];             /* TKIP: key | tx MIC | rx MIC */
    uint8_t peer[ETH_ALEN];
    uint8_t rsc[8];
};

/* RX status in skb->cb (IEEE80211_SKB_RXCB). */
#define RX_FLAG_DECRYPTED    (1u << 0)
#define RX_FLAG_IV_STRIPPED  (1u << 1)
#define RX_FLAG_MIC_STRIPPED (1u << 2)

struct ieee80211_rx_status {
    uint16_t channel;
    uint8_t signal;
    uint8_t flag;
};

/* Access categories (mac80211 numbering). */
#define IEEE80211_AC_VO 0u
#define IEEE80211_AC_VI 1u
#define IEEE80211_AC_BE 2u
#define IEEE80211_AC_BK 3u

#define IEEE80211_TX_CTL_USE_MINRATE (1u << 0)   /* mgmt / EAPOL */

/* TX control in skb->cb (IEEE80211_SKB_CB). */
struct ieee80211_tx_info {
    uint32_t cookie;             /* echoed by ieee80211_tx_status() */
    uint8_t hw_queue;            /* IEEE80211_AC_* */
    uint8_t flags;
};

#define IEEE80211_SKB_RXCB(skb) ((struct ieee80211_rx_status *)(void *)(skb)->cb)
#define IEEE80211_SKB_CB(skb)   ((struct ieee80211_tx_info *)(void *)(skb)->cb)

struct ieee80211_ops {
    /* One-time MAC setup when the device is registered. */
    int (*start)(struct ieee80211_hw *hw);
    /* Hand one 802.11 frame to the hardware.  The driver copies it;
     * mac80211 frees skb when this returns. */
    int (*tx)(struct ieee80211_hw *hw, struct sk_buff *skb);
    int (*hw_scan)(struct ieee80211_hw *hw,
                   struct cfg80211_scan_request *req);
    /* Returns <0 if the device could not apply the change (join). */
    int (*bss_info_changed)(struct ieee80211_hw *hw,
                            struct ieee80211_bss_conf *info,
                            uint32_t changed);
    int (*set_key)(struct ieee80211_hw *hw, enum set_key_cmd cmd,
                   struct ieee80211_key_conf *key);
    /* miniOS: run the bottom half for up to timeout_ms (no IRQs). */
    int (*poll)(struct ieee80211_hw *hw, int timeout_ms);
};

struct ieee80211_hw *ieee80211_alloc_hw(const struct ieee80211_ops *ops,
                                        void *priv);
/* Registers the wiphy and the "wlan0" network device. */
int ieee80211_register_hw(struct ieee80211_hw *hw, const uint8_t addr[ETH_ALEN],
                          const struct ieee80211_rate *rates,
                          uint32_t n_rates);

/* Driver -> mac80211, from the bottom half. */
void ieee80211_rx_irqsafe(struct ieee80211_hw *hw, struct sk_buff *skb);
void ieee80211_tx_status(struct ieee80211_hw *hw, uint32_t cookie, int status);
void ieee80211_scan_completed(struct ieee80211_hw *hw, int aborted);
void ieee80211_beacon_loss(struct ieee80211_hw *hw);

#endif
