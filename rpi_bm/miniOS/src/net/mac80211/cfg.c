/*
 * cfg80211_ops implemented by mac80211, after Linux net/mac80211/cfg.c.
 */
#include "ieee80211_i.h"

static int ieee80211_scan(struct wiphy *wiphy, struct cfg80211_scan_request *req)
{
    return ieee80211_request_scan(wiphy_to_local(wiphy), req);
}

static int ieee80211_auth(struct wiphy *wiphy, struct net_device *dev,
                          struct cfg80211_auth_request *req)
{
    (void)dev;
    return ieee80211_mgd_auth(wiphy_to_local(wiphy), req);
}

static int ieee80211_assoc(struct wiphy *wiphy, struct net_device *dev,
                           struct cfg80211_assoc_request *req)
{
    (void)dev;
    return ieee80211_mgd_assoc(wiphy_to_local(wiphy), req);
}

static int ieee80211_deauth(struct wiphy *wiphy, struct net_device *dev,
                            uint16_t reason)
{
    (void)dev;
    return ieee80211_mgd_deauth(wiphy_to_local(wiphy), reason);
}

static int ieee80211_cfg_add_key(struct wiphy *wiphy, struct net_device *dev,
                                 uint8_t key_index, int pairwise,
                                 const uint8_t *mac_addr,
                                 struct key_params *params)
{
    (void)dev;
    return ieee80211_add_key(wiphy_to_local(wiphy), key_index, pairwise,
                             mac_addr, params);
}

const struct cfg80211_ops mac80211_config_ops = {
    .scan = ieee80211_scan,
    .auth = ieee80211_auth,
    .assoc = ieee80211_assoc,
    .deauth = ieee80211_deauth,
    .add_key = ieee80211_cfg_add_key,
    .tx_control_port = ieee80211_tx_control_port,
};
