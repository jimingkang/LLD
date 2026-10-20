/*
 * BSS table and scanning, after Linux net/wireless/scan.c.  Beacons and
 * probe responses reported by the device during a scan become
 * cfg80211_bss entries; the SME and the supplicant pick one from here.
 * Only the elements they use are kept (SSID, rates, DS, TIM, RSN).
 */
#include "platform.h"
#include "device.h"
#include "net/cfg80211.h"
#include "net/netutil.h"

#define SCAN_TIMEOUT_US 5000000u

static struct cfg80211_bss bss_table[CFG80211_MAX_BSS];
static uint32_t bss_count;

const uint8_t *cfg80211_find_ie(uint8_t eid, const uint8_t *ies, uint32_t len)
{
    for (uint32_t pos = 0; ies && pos + 2u <= len;) {
        uint8_t n = ies[pos + 1u];
        if (pos + 2u + n > len)
            break;
        if (ies[pos] == eid)
            return ies + pos;
        pos += 2u + n;
    }
    return 0;
}

static int ie_wanted(uint8_t eid)
{
    return eid == WLAN_EID_SSID || eid == WLAN_EID_SUPP_RATES ||
           eid == WLAN_EID_DS_PARAMS || eid == WLAN_EID_TIM ||
           eid == WLAN_EID_RSN || eid == WLAN_EID_EXT_SUPP_RATES;
}

static void print_bss(const struct cfg80211_bss *bss)
{
    const uint8_t *ssid = cfg80211_find_ie(WLAN_EID_SSID, bss->ies, bss->ies_len);
    t113_uart_puts("cfg80211: AP ssid=\"");
    if (!ssid || !ssid[1])
        t113_uart_puts("<hidden>");
    for (uint32_t i = 0; ssid && i < ssid[1]; ++i) {
        uint8_t c = ssid[2 + i];
        t113_uart_putc((c >= 32u && c < 127u) ? (char)c : '.');
    }
    t113_uart_puts("\" bssid=");
    net_print_mac(bss->bssid);
    t113_uart_puts(" channel=");
    net_putdec(bss->channel);
    t113_uart_puts(" rcpi=");
    t113_uart_puthex(bss->signal);
    t113_uart_puts(bss->capability & WLAN_CAPABILITY_PRIVACY ? " secured\n" : " open\n");
}

void cfg80211_inform_bss_frame(struct wiphy *wiphy, uint16_t channel,
                               uint8_t signal, const uint8_t *mgmt,
                               uint32_t len)
{
    uint32_t hdr = IEEE80211_HDR_3ADDR_LEN + IEEE80211_BEACON_IES;
    uint16_t fc = get_unaligned_le16(mgmt);
    if (len < hdr || !ieee80211_is_mgmt(fc) ||
        (ieee80211_stype(fc) != IEEE80211_STYPE_BEACON &&
         ieee80211_stype(fc) != IEEE80211_STYPE_PROBE_RESP))
        return;
    ++wiphy->scan_frames;
    const uint8_t *bssid = mgmt + 16;
    const uint8_t *ies = mgmt + hdr;
    uint32_t ies_len = len - hdr;

    struct cfg80211_bss *bss = 0;
    for (uint32_t i = 0; i < bss_count; ++i)
        if (net_memeq(bss_table[i].bssid, bssid, ETH_ALEN))
            bss = &bss_table[i];
    int is_new = !bss;
    if (is_new) {
        if (bss_count >= CFG80211_MAX_BSS)
            return;
        bss = &bss_table[bss_count++];
        net_memcpy(bss->bssid, bssid, ETH_ALEN);
    }
    const uint8_t *ds = cfg80211_find_ie(WLAN_EID_DS_PARAMS, ies, ies_len);
    bss->channel = ds && ds[1] == 1u ? ds[2] : channel;
    bss->signal = signal;
    bss->beacon_interval = get_unaligned_le16(mgmt + IEEE80211_HDR_3ADDR_LEN + 8);
    bss->capability = get_unaligned_le16(mgmt + IEEE80211_HDR_3ADDR_LEN + 10);
    bss->ies_len = 0;
    for (uint32_t pos = 0; pos + 2u <= ies_len;) {
        uint8_t n = ies[pos + 1u];
        if (pos + 2u + n > ies_len)
            break;
        if (ie_wanted(ies[pos]) && bss->ies_len + 2u + n <= CFG80211_BSS_IES_MAX) {
            net_memcpy(bss->ies + bss->ies_len, ies + pos, 2u + n);
            bss->ies_len = (uint16_t)(bss->ies_len + 2u + n);
        }
        pos += 2u + n;
    }
    if (is_new)
        print_bss(bss);
}

void cfg80211_scan_done(struct wiphy *wiphy, int aborted)
{
    wiphy->scanning = 0;
    wiphy->scan_done = 1;
    wiphy->scan_aborted = aborted != 0;
}

int cfg80211_scan(struct net_device *dev, struct cfg80211_scan_request *req)
{
    struct wireless_dev *wdev = dev ? dev->ieee80211_ptr : 0;
    if (!wdev)
        return -ENODEV;
    struct wiphy *wiphy = wdev->wiphy;
    bss_count = 0;
    wiphy->scanning = 1;
    wiphy->scan_done = 0;
    wiphy->scan_frames = 0;
    t113_uart_puts("cfg80211: passive scan, ");
    net_putdec(req->n_channels);
    t113_uart_puts(" channels\n");
    int r = wiphy->ops->scan(wiphy, req);
    if (r) {
        wiphy->scanning = 0;
        t113_uart_puts("cfg80211: scan request failed ");
        t113_uart_puthex((uint32_t)r);
        t113_uart_putc('\n');
        return r < 0 ? r : -EIO;
    }
    uint64_t deadline = t113_time_us() + SCAN_TIMEOUT_US;
    while (!wiphy->scan_done && t113_time_us() < deadline)
        __net_poll(dev, 20);
    wiphy->scanning = 0;
    if (!wiphy->scan_done) {
        t113_uart_puts("cfg80211: scan completion timeout\n");
        return -ETIMEDOUT;
    }
    t113_uart_puts("cfg80211: scan done");
    t113_uart_puts(wiphy->scan_aborted ? " (aborted), " : ", ");
    net_putdec(bss_count);
    t113_uart_puts(" BSS from ");
    net_putdec(wiphy->scan_frames);
    t113_uart_puts(" frames\n");
    return (int)bss_count;
}

const struct cfg80211_bss *cfg80211_get_bss(struct wiphy *wiphy,
                                            const uint8_t *ssid,
                                            uint32_t ssid_len)
{
    (void)wiphy;
    const struct cfg80211_bss *best = 0;
    for (uint32_t i = 0; i < bss_count; ++i) {
        const struct cfg80211_bss *bss = &bss_table[i];
        const uint8_t *ie = cfg80211_find_ie(WLAN_EID_SSID, bss->ies, bss->ies_len);
        if (!ie || ie[1] != ssid_len || !net_memeq(ie + 2, ssid, ssid_len))
            continue;
        if (!best || bss->signal > best->signal)
            best = bss;
    }
    return best;
}
