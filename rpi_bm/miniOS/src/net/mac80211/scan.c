/*
 * Scanning, after Linux net/mac80211/scan.c: the device scans by itself
 * (hw_scan); every beacon and probe response it reports meanwhile goes
 * to the cfg80211 BSS table, and completion is reported once the queued
 * frames have been processed.
 */
#include "net/netutil.h"
#include "ieee80211_i.h"

int ieee80211_request_scan(struct ieee80211_local *local,
                           struct cfg80211_scan_request *req)
{
    local->scanning = 1;
    local->scan_completed = 0;
    int r = local->hw.ops->hw_scan(&local->hw, req);
    if (r)
        local->scanning = 0;
    return r;
}

void ieee80211_scan_rx(struct ieee80211_local *local, struct sk_buff *skb)
{
    const struct ieee80211_rx_status *status = IEEE80211_SKB_RXCB(skb);
    cfg80211_inform_bss_frame(local->hw.wiphy, status->channel, status->signal,
                              skb->data, skb->len);
}

/* From the driver bottom half: only record it. */
void ieee80211_scan_completed(struct ieee80211_hw *hw, int aborted)
{
    struct ieee80211_local *local = hw_to_local(hw);
    local->scan_completed = 1;
    local->scan_aborted = aborted != 0;
}

void ieee80211_scan_finish(struct ieee80211_local *local)
{
    local->scan_completed = 0;
    local->scanning = 0;
    cfg80211_scan_done(local->hw.wiphy, local->scan_aborted);
}
