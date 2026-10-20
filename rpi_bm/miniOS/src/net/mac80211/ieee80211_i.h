#ifndef MINIOS_MAC80211_IEEE80211_I_H
#define MINIOS_MAC80211_IEEE80211_I_H

/*
 * mac80211 private state, after Linux net/mac80211/ieee80211_i.h.  One
 * hardware and one station interface: ieee80211_local merges Linux's
 * ieee80211_local, ieee80211_sub_if_data and its u.mgd (managed mode).
 */
#include "net/mac80211.h"

#define TX_STATUS_SLOTS 16u
#define TX_STATUS_PENDING (-1)

struct ieee80211_local {
    struct ieee80211_hw hw;              /* first: hw <-> local cast */
    struct net_device dev;               /* wlan0 */
    struct wireless_dev wdev;
    struct sk_buff_head rx_queue;        /* filled by ieee80211_rx_irqsafe */
    uint32_t in_tasklet;

    /* scan */
    uint32_t scanning;
    uint32_t scan_completed;
    uint32_t scan_aborted;

    /* managed mode (sdata->u.mgd) */
    struct ieee80211_bss_conf bss_conf;
    uint16_t bss_capability;
    uint32_t joined;                     /* device synced to bss_conf.bssid */
    uint32_t associated;
    uint32_t auth_done;
    uint16_t auth_status;
    uint32_t assoc_done;
    uint16_t assoc_status;
    uint32_t deauth_received;
    uint16_t seq;

    /* keys (one pairwise, one group) */
    struct ieee80211_key_conf ptk;
    struct ieee80211_key_conf gtk;
    uint32_t ptk_set;
    uint32_t gtk_set;

    /* TX status by cookie */
    uint32_t next_cookie;
    struct {
        uint32_t cookie;
        int32_t status;
        uint32_t control_port;
    } tx_status[TX_STATUS_SLOTS];
};

static inline struct ieee80211_local *hw_to_local(struct ieee80211_hw *hw)
{
    return (struct ieee80211_local *)(void *)hw;
}

static inline struct ieee80211_local *wiphy_to_local(struct wiphy *wiphy)
{
    return (struct ieee80211_local *)wiphy->priv;
}

/* tx.c */
int ieee80211_tx_skb(struct ieee80211_local *local, struct sk_buff *skb,
                     uint8_t ac, uint8_t flags, int control_port,
                     uint32_t *cookie);
/* skb->data at the payload: add LLC/SNAP, CCMP room and the header. */
int ieee80211_build_data_hdr(struct ieee80211_local *local,
                             struct sk_buff *skb, const uint8_t *da,
                             uint16_t ethertype);
uint8_t *ieee80211_build_mgmt_hdr(struct ieee80211_local *local,
                                  struct sk_buff *skb, uint16_t stype);
/* Wait for the TX status of a frame: 0 = acked, -1 = none yet. */
int ieee80211_wait_tx_status(struct ieee80211_local *local, uint32_t cookie,
                             int timeout_ms);
int ieee80211_subif_start_xmit(struct sk_buff *skb, struct net_device *dev);
int ieee80211_tx_control_port(struct wiphy *wiphy, struct net_device *dev,
                              const uint8_t *buf, uint32_t len,
                              const uint8_t *dest, uint16_t proto,
                              uint32_t *cookie);

/* rx.c */
void ieee80211_rx_tasklet(struct ieee80211_local *local);

/* mlme.c */
int ieee80211_mgd_auth(struct ieee80211_local *local,
                       struct cfg80211_auth_request *req);
int ieee80211_mgd_assoc(struct ieee80211_local *local,
                        struct cfg80211_assoc_request *req);
int ieee80211_mgd_deauth(struct ieee80211_local *local, uint16_t reason);
void ieee80211_rx_mgmt(struct ieee80211_local *local, struct sk_buff *skb);

/* scan.c */
int ieee80211_request_scan(struct ieee80211_local *local,
                           struct cfg80211_scan_request *req);
void ieee80211_scan_rx(struct ieee80211_local *local, struct sk_buff *skb);
void ieee80211_scan_finish(struct ieee80211_local *local);

/* key.c */
int ieee80211_add_key(struct ieee80211_local *local, uint8_t key_index,
                      int pairwise, const uint8_t *mac_addr,
                      struct key_params *params);
void ieee80211_free_keys(struct ieee80211_local *local);

/* cfg.c */
extern const struct cfg80211_ops mac80211_config_ops;

#endif
