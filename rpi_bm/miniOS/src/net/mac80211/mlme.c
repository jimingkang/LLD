/*
 * Station MLME, after Linux net/mac80211/mlme.c: join the BSS, open
 * system authentication, association and deauthentication, and the
 * management frames that answer them.
 *
 * Linux runs these as asynchronous work items reporting back to
 * cfg80211; here each step sends its frame, waits for the TX status and
 * the AP's answer by polling, and returns the result.
 */
#include "platform.h"
#include "device.h"
#include "net/netutil.h"
#include "ieee80211_i.h"

#define MLME_TRIES          3
#define MLME_TX_TIMEOUT_MS  500
#define MLME_RESP_TIMEOUT_MS 1000
#define LISTEN_INTERVAL     5u

static void say(const char *s)
{
    t113_uart_puts("wlan0: ");
    t113_uart_puts(s);
}

static void say_hex(const char *s, uint32_t v)
{
    say(s);
    t113_uart_puthex(v);
    t113_uart_putc('\n');
}

/* Poll until *flag is set, the AP deauthenticates us, or timeout. */
static int wait_flag(struct ieee80211_local *local, volatile uint32_t *flag,
                     int timeout_ms)
{
    uint64_t end = t113_time_us() + (uint64_t)timeout_ms * 1000u;
    while (!*flag && !local->deauth_received && t113_time_us() < end)
        __net_poll(&local->dev, 10);
    return *flag ? 0 : -ETIMEDOUT;
}

/* Rate bitmaps of the BSS (BIT(hw_value)), from its rate elements. */
static void bss_rates(struct ieee80211_local *local,
                      const struct cfg80211_bss *bss)
{
    struct wiphy *wiphy = local->hw.wiphy;
    uint32_t basic = 0, supp = 0;
    const uint8_t eids[2] = { WLAN_EID_SUPP_RATES, WLAN_EID_EXT_SUPP_RATES };
    for (uint32_t e = 0; e < 2u; ++e) {
        const uint8_t *ie = cfg80211_find_ie(eids[e], bss->ies, bss->ies_len);
        for (uint32_t i = 0; ie && i < ie[1]; ++i) {
            uint32_t bit = ieee80211_rate_bit(wiphy, ie[2 + i]);
            supp |= bit;
            if (ie[2 + i] & 0x80u)
                basic |= bit;
        }
    }
    if (!basic || !supp) {
        uint32_t all = 0, cck = 0;
        for (uint32_t i = 0; i < wiphy->n_bitrates; ++i) {
            all |= 1u << wiphy->bitrates[i].hw_value;
            if (wiphy->bitrates[i].bitrate <= 110u)
                cck |= 1u << wiphy->bitrates[i].hw_value;
        }
        if (!basic) basic = cck;
        if (!supp) supp = all;
    }
    local->bss_conf.basic_rates = basic;
    local->bss_conf.supp_rates = supp;
}

/* Drop the association: keys out, no frame (ieee80211_set_disassoc). */
static void set_disassoc(struct ieee80211_local *local)
{
    ieee80211_free_keys(local);
    local->associated = 0;
    local->bss_conf.assoc = 0;
    local->bss_conf.aid = 0;
}

static int send_mgmt(struct ieee80211_local *local, struct sk_buff *skb,
                     const char *what)
{
    uint32_t cookie;
    int r = ieee80211_tx_skb(local, skb, IEEE80211_AC_VO,
                             IEEE80211_TX_CTL_USE_MINRATE, 0, &cookie);
    if (r < 0)
        return r;
    int st = ieee80211_wait_tx_status(local, cookie, MLME_TX_TIMEOUT_MS);
    if (st != 0) {
        say(what);
        say_hex(" TX status ", (uint32_t)st);
    }
    return 0;
}

int ieee80211_mgd_auth(struct ieee80211_local *local,
                       struct cfg80211_auth_request *req)
{
    const struct cfg80211_bss *bss = req->bss;
    struct ieee80211_bss_conf *conf = &local->bss_conf;
    set_disassoc(local);
    local->joined = 0;

    net_memset(conf, 0, sizeof(*conf));
    net_memcpy(conf->bssid, bss->bssid, ETH_ALEN);
    conf->channel = bss->channel;
    const uint8_t *ssid = cfg80211_find_ie(WLAN_EID_SSID, bss->ies, bss->ies_len);
    conf->ssid_len = ssid && ssid[1] <= 32u ? ssid[1] : 0;
    if (conf->ssid_len)
        net_memcpy(conf->ssid, ssid + 2, conf->ssid_len);
    const uint8_t *tim = cfg80211_find_ie(WLAN_EID_TIM, bss->ies, bss->ies_len);
    conf->dtim_period = tim && tim[1] >= 2u ? tim[3] : 1u;
    conf->beacon_int = bss->beacon_interval;
    conf->use_short_preamble =
        (bss->capability & WLAN_CAPABILITY_SHORT_PREAMBLE) != 0;
    conf->use_short_slot = (bss->capability & WLAN_CAPABILITY_SHORT_SLOT_TIME) != 0;
    local->bss_capability = bss->capability;
    bss_rates(local, bss);

    say("joining BSS\n");
    int r = local->hw.ops->bss_info_changed(&local->hw, conf, BSS_CHANGED_BSSID);
    if (r) {
        say_hex("join failed, status ", (uint32_t)r);
        return r < 0 ? r : -EIO;
    }
    local->joined = 1;
    local->deauth_received = 0;
    skb_queue_purge(&local->rx_queue);

    say("open-system authentication\n");
    for (int attempt = 0; attempt < MLME_TRIES; ++attempt) {
        struct sk_buff *skb = alloc_skb(6);
        if (!skb)
            return -ENOSPC;
        uint8_t *b = skb_put(skb, 6);
        put_unaligned_le16(WLAN_AUTH_OPEN, b);
        put_unaligned_le16(1, b + 2);   /* transaction sequence */
        put_unaligned_le16(0, b + 4);   /* status */
        ieee80211_build_mgmt_hdr(local, skb, IEEE80211_STYPE_AUTH);
        local->auth_done = 0;
        if ((r = send_mgmt(local, skb, "auth")) < 0)
            return r;
        if (wait_flag(local, &local->auth_done, MLME_RESP_TIMEOUT_MS) == 0) {
            if (local->auth_status == WLAN_STATUS_SUCCESS)
                return 0;
            say_hex("authentication refused, status ", local->auth_status);
            return -EIO;
        }
        if (local->deauth_received)
            break;
    }
    say("no authentication response\n");
    return -ETIMEDOUT;
}

static uint8_t *add_ie(struct sk_buff *skb, const uint8_t *ie, uint32_t max)
{
    uint32_t n = ie[1] < max ? ie[1] : max;
    uint8_t *p = skb_put(skb, 2u + n);
    p[0] = ie[0];
    p[1] = (uint8_t)n;
    net_memcpy(p + 2, ie + 2, n);
    return p;
}

int ieee80211_mgd_assoc(struct ieee80211_local *local,
                        struct cfg80211_assoc_request *req)
{
    static const uint8_t b_rates[] = { WLAN_EID_SUPP_RATES, 4, 0x82, 0x84, 0x8b, 0x96 };
    const struct cfg80211_bss *bss = req->bss;
    struct ieee80211_bss_conf *conf = &local->bss_conf;
    int r;

    say("association request\n");
    for (int attempt = 0; attempt < MLME_TRIES; ++attempt) {
        struct sk_buff *skb = alloc_skb(256u + req->ie_len);
        if (!skb)
            return -ENOSPC;
        uint8_t *b = skb_put(skb, 4);
        uint16_t cap = WLAN_CAPABILITY_ESS |
                       (bss->capability & (WLAN_CAPABILITY_PRIVACY |
                                           WLAN_CAPABILITY_SHORT_PREAMBLE |
                                           WLAN_CAPABILITY_SHORT_SLOT_TIME));
        put_unaligned_le16(cap, b);
        put_unaligned_le16(LISTEN_INTERVAL, b + 2);
        b = skb_put(skb, 2u + conf->ssid_len);
        b[0] = WLAN_EID_SSID;
        b[1] = conf->ssid_len;
        net_memcpy(b + 2, conf->ssid, conf->ssid_len);
        const uint8_t *rates = cfg80211_find_ie(WLAN_EID_SUPP_RATES, bss->ies, bss->ies_len);
        add_ie(skb, rates && rates[1] ? rates : b_rates, 8);
        const uint8_t *ext = cfg80211_find_ie(WLAN_EID_EXT_SUPP_RATES, bss->ies, bss->ies_len);
        if (ext && ext[1])
            add_ie(skb, ext, 16);
        if (req->ie_len)
            net_memcpy(skb_put(skb, req->ie_len), req->ie, req->ie_len);
        ieee80211_build_mgmt_hdr(local, skb, IEEE80211_STYPE_ASSOC_REQ);
        local->assoc_done = 0;
        if ((r = send_mgmt(local, skb, "assoc")) < 0)
            return r;
        if (wait_flag(local, &local->assoc_done, MLME_RESP_TIMEOUT_MS) == 0) {
            if (local->assoc_status != WLAN_STATUS_SUCCESS) {
                say_hex("association refused, status ", local->assoc_status);
                return -EIO;
            }
            say_hex("associated, AID ", conf->aid);
            conf->assoc = 1;
            local->associated = 1;
            r = local->hw.ops->bss_info_changed(&local->hw, conf, BSS_CHANGED_ASSOC);
            return r < 0 ? r : 0;
        }
        if (local->deauth_received)
            break;
    }
    say("no association response\n");
    return -ETIMEDOUT;
}

int ieee80211_mgd_deauth(struct ieee80211_local *local, uint16_t reason)
{
    if (!local->joined)
        return 0;
    struct sk_buff *skb = alloc_skb(2);
    if (skb) {
        put_unaligned_le16(reason, skb_put(skb, 2));
        ieee80211_build_mgmt_hdr(local, skb, IEEE80211_STYPE_DEAUTH);
        uint32_t cookie;
        if (ieee80211_tx_skb(local, skb, IEEE80211_AC_VO,
                             IEEE80211_TX_CTL_USE_MINRATE, 0, &cookie) == 0)
            ieee80211_wait_tx_status(local, cookie, 300);
    }
    set_disassoc(local);
    local->joined = 0;
    return 0;
}

/* Management frames from our AP while joined (from the RX tasklet). */
void ieee80211_rx_mgmt(struct ieee80211_local *local, struct sk_buff *skb)
{
    const uint8_t *f = skb->data;
    uint32_t len = skb->len;
    uint16_t fc = get_unaligned_le16(f);
    if (len < IEEE80211_HDR_3ADDR_LEN + 2u ||
        !net_memeq(f + 16, local->bss_conf.bssid, ETH_ALEN) ||
        !net_memeq(f + 4, local->dev.dev_addr, ETH_ALEN))
        return;
    const uint8_t *b = f + IEEE80211_HDR_3ADDR_LEN;
    uint32_t stype = ieee80211_stype(fc);
    if (stype == IEEE80211_STYPE_AUTH && len >= IEEE80211_HDR_3ADDR_LEN + 6u &&
        get_unaligned_le16(b) == WLAN_AUTH_OPEN && get_unaligned_le16(b + 2) == 2u) {
        local->auth_status = get_unaligned_le16(b + 4);
        local->auth_done = 1;
    } else if ((stype == IEEE80211_STYPE_ASSOC_RESP ||
                stype == IEEE80211_STYPE_REASSOC_RESP) &&
               len >= IEEE80211_HDR_3ADDR_LEN + 6u) {
        local->assoc_status = get_unaligned_le16(b + 2);
        local->bss_conf.aid = get_unaligned_le16(b + 4) & 0x3fffu;
        local->assoc_done = 1;
    } else if (stype == IEEE80211_STYPE_DEAUTH || stype == IEEE80211_STYPE_DISASSOC) {
        local->deauth_received = 1;
        set_disassoc(local);            /* keys out of the hardware */
        cfg80211_disconnected(&local->dev, get_unaligned_le16(b));
    }
}
