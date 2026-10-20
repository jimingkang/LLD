#ifndef MINIOS_NET_CFG80211_H
#define MINIOS_NET_CFG80211_H

#include <stdint.h>
#include "net/netdevice.h"
#include "net/ieee80211.h"

/*
 * cfg80211: 802.11 configuration API, after Linux include/net/cfg80211.h
 * and net/wireless/.
 *
 * The device driver stack below (mac80211 here) implements cfg80211_ops;
 * cfg80211 keeps the BSS table from scans, runs the station SME (connect
 * = auth + assoc) and carries EAPOL between the device and the
 * supplicant (control port), the way nl80211 does for wpa_supplicant.
 *
 * Unlike Linux, the MLME operations are synchronous: rdev auth/assoc
 * return once the AP answered, polling the device meanwhile.
 */

#define CFG80211_MAX_BSS        16u
#define CFG80211_BSS_IES_MAX    320u
#define CFG80211_MAX_CHANNELS   14u

struct wiphy;

struct cfg80211_bss {
    uint8_t bssid[ETH_ALEN];
    uint16_t channel;
    uint8_t signal;              /* RCPI as reported by the device */
    uint16_t capability;
    uint16_t beacon_interval;
    uint16_t ies_len;
    uint8_t ies[CFG80211_BSS_IES_MAX];
};

struct cfg80211_scan_request {
    uint8_t n_channels;
    uint16_t channels[CFG80211_MAX_CHANNELS];
    uint32_t min_dwell_ms;
    uint32_t max_dwell_ms;       /* passive scan: no SSIDs */
};

struct cfg80211_auth_request {
    const struct cfg80211_bss *bss;
    uint8_t auth_type;           /* WLAN_AUTH_OPEN */
};

struct cfg80211_assoc_request {
    const struct cfg80211_bss *bss;
    const uint8_t *ie;           /* extra IEs for the request (RSN) */
    uint32_t ie_len;
};

struct cfg80211_connect_params {
    const struct cfg80211_bss *bss;
    const uint8_t *ie;
    uint32_t ie_len;
};

struct key_params {
    const uint8_t *key;
    uint32_t key_len;
    const uint8_t *seq;          /* RSC, 8 bytes, may be 0 */
    uint32_t cipher;             /* WLAN_CIPHER_SUITE_* */
};

struct cfg80211_ops {
    int (*scan)(struct wiphy *wiphy, struct cfg80211_scan_request *req);
    int (*auth)(struct wiphy *wiphy, struct net_device *dev,
                struct cfg80211_auth_request *req);
    int (*assoc)(struct wiphy *wiphy, struct net_device *dev,
                 struct cfg80211_assoc_request *req);
    int (*deauth)(struct wiphy *wiphy, struct net_device *dev,
                  uint16_t reason);
    int (*add_key)(struct wiphy *wiphy, struct net_device *dev,
                   uint8_t key_index, int pairwise, const uint8_t *mac_addr,
                   struct key_params *params);
    /* EAPOL from the supplicant; *cookie identifies its TX status. */
    int (*tx_control_port)(struct wiphy *wiphy, struct net_device *dev,
                           const uint8_t *buf, uint32_t len,
                           const uint8_t *dest, uint16_t proto,
                           uint32_t *cookie);
};

/* 802.11 rate as advertised by the device (struct ieee80211_rate). */
struct ieee80211_rate {
    uint16_t bitrate;            /* 100 kb/s units */
    uint16_t hw_value;           /* device rate index */
};

struct wiphy {
    const struct cfg80211_ops *ops;
    uint8_t perm_addr[ETH_ALEN];
    const struct ieee80211_rate *bitrates;   /* 2.4 GHz band */
    uint32_t n_bitrates;
    void *priv;
    /* scan state */
    uint32_t scanning;
    uint32_t scan_done;
    uint32_t scan_aborted;
    uint32_t scan_frames;
};

/* Control port receiver: the supplicant (nl80211 socket in Linux). */
struct cfg80211_control_port_ops {
    void (*rx)(struct net_device *dev, const uint8_t *src,
               const uint8_t *frame, uint32_t len);
    void (*tx_status)(struct net_device *dev, uint32_t cookie, int acked);
    void (*disconnected)(struct net_device *dev, uint16_t reason);
};

enum cfg80211_sme_state {
    CFG80211_SME_IDLE,
    CFG80211_SME_CONNECTING,
    CFG80211_SME_CONNECTED,
};

struct wireless_dev {
    struct wiphy *wiphy;
    struct net_device *netdev;
    enum cfg80211_sme_state sme_state;
    struct cfg80211_bss current_bss;
    uint32_t port_authorized;
};

/* --- core.c -------------------------------------------------------- */
struct wiphy *wiphy_new(const struct cfg80211_ops *ops, void *priv);
int wiphy_register(struct wiphy *wiphy);
/* Attach a wireless_dev to dev; call before register_netdev(). */
void cfg80211_init_wdev(struct wireless_dev *wdev, struct wiphy *wiphy,
                        struct net_device *dev);
void cfg80211_set_control_port_ops(const struct cfg80211_control_port_ops *ops);
/* Wrappers around the rdev ops for the supplicant (nl80211 commands). */
int cfg80211_add_key(struct net_device *dev, uint8_t key_index, int pairwise,
                     const uint8_t *mac_addr, struct key_params *params);
int cfg80211_tx_control_port(struct net_device *dev, const uint8_t *buf,
                             uint32_t len, const uint8_t *dest,
                             uint16_t proto, uint32_t *cookie);
/* Called by mac80211. */
void cfg80211_rx_control_port(struct net_device *dev, const uint8_t *src,
                              const uint8_t *frame, uint32_t len);
void cfg80211_control_port_tx_status(struct net_device *dev, uint32_t cookie,
                                     int acked);

/* --- scan.c -------------------------------------------------------- */
void cfg80211_inform_bss_frame(struct wiphy *wiphy, uint16_t channel,
                               uint8_t signal, const uint8_t *mgmt,
                               uint32_t len);
void cfg80211_scan_done(struct wiphy *wiphy, int aborted);
/* Trigger a scan and wait for it (caller holds the network lock). */
int cfg80211_scan(struct net_device *dev, struct cfg80211_scan_request *req);
/* Strongest BSS advertising this SSID, or 0. */
const struct cfg80211_bss *cfg80211_get_bss(struct wiphy *wiphy,
                                            const uint8_t *ssid,
                                            uint32_t ssid_len);
/* Pointer to the element (id, len, data...) or 0. */
const uint8_t *cfg80211_find_ie(uint8_t eid, const uint8_t *ies, uint32_t len);

/* --- sme.c --------------------------------------------------------- */
/* Authenticate and associate (caller holds the network lock). */
int cfg80211_connect(struct net_device *dev,
                     struct cfg80211_connect_params *params);
void cfg80211_disconnect(struct net_device *dev, uint16_t reason);
/* From mac80211: the AP deauthenticated or disassociated us. */
void cfg80211_disconnected(struct net_device *dev, uint16_t reason);
/* From the supplicant: keys are in place, open the data port. */
void cfg80211_port_authorized(struct net_device *dev);

/* --- util.c -------------------------------------------------------- */
/* 802.11 data frame (crypto already removed) -> Ethernet II, in place.
 * Returns the ethertype, or -1 if the frame carries no LLC/SNAP. */
int ieee80211_data_to_8023(struct sk_buff *skb);
/* Rate code (500 kb/s, bit 7 = basic) -> BIT(hw_value) of that rate. */
uint32_t ieee80211_rate_bit(const struct wiphy *wiphy, uint8_t rate);

#endif
