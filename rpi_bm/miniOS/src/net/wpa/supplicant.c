/*
 * WPA2-PSK supplicant (see include/net/wpa.h).
 *
 * EAPOL frames arrive through the cfg80211 control port, from the
 * mac80211 RX tasklet.  A reply is sent straight away; when it completes
 * the 4-way handshake (message 4), the pairwise key may only be installed
 * after that frame has left, so installing waits for its TX status in a
 * net_work item instead of blocking the receive path.
 */
#include "platform.h"
#include "device.h"
#include "fs/vfs.h"
#include "net/netdevice.h"
#include "net/netutil.h"
#include "net/cfg80211.h"
#include "net/ip.h"
#include "net/ipconfig.h"
#include "net/eapol.h"
#include "net/wpa.h"
#include "crypto/wpa_crypto.h"

#define HANDSHAKE_TIMEOUT_US 6000000u
#define M4_STATUS_TIMEOUT_US 1000000u
#define DHCP_TIMEOUT_MS      10000

/* Used when /boot/wifi.txt names no SSID, in order of preference. */
static const char *const default_ssids[] = {
    "TP-Link_B114",       /* preferred: XR829 is a 2.4 GHz radio */
    "TP-Link_B114_5G",
};

static struct {
    char ssid[33];
    char psk[64];
    uint32_t ip, netmask, gateway;
} cfg;

static struct {
    struct net_device *dev;
    uint8_t bssid[ETH_ALEN];
    uint32_t secure;
    uint32_t active;             /* expecting EAPOL from the AP */
    uint32_t group_cipher;       /* WLAN_CIPHER_SUITE_* */
    uint32_t ptk_installed;
    struct eapol_ctx eapol;
    /* keys held back until message 4 has been sent */
    uint32_t pending;
    uint32_t pending_cookie;
    uint32_t pending_done;
    uint32_t pending_acked;
    uint64_t pending_deadline;
} wpa;

static void say(const char *s)
{
    t113_uart_puts("wpa: ");
    t113_uart_puts(s);
}

/* ------------------------------------------------------ wifi.txt */

static int key_is(const char *line, uint32_t len, const char *key)
{
    uint32_t n = net_strlen(key);
    return len > n && line[n] == '=' && net_memeq(line, key, n);
}

static void set_value(char *dst, uint32_t cap, const char *src, uint32_t len)
{
    if (len >= cap)
        len = cap - 1u;
    net_memcpy(dst, src, len);
    dst[len] = 0;
}

static void load_config(void)
{
    static char text[512];
    struct file *f = t113_vfs_open("/boot/wifi.txt", VFS_O_RDONLY);
    int n = f ? t113_vfs_read(f, text, sizeof(text) - 1u) : -1;
    t113_vfs_close(f);
    cfg.ssid[0] = cfg.psk[0] = 0;
    cfg.ip = cfg.netmask = cfg.gateway = 0;
    if (n <= 0) {
        say("no /boot/wifi.txt, using built-in SSIDs without passphrase\n");
        return;
    }
    text[n] = 0;
    for (char *line = text; *line;) {
        char *end = line;
        while (*end && *end != '\n') ++end;
        uint32_t len = (uint32_t)(end - line);
        while (len && (line[len - 1u] == '\r' || line[len - 1u] == ' '))
            --len;
        char value[20];
        if (key_is(line, len, "ssid"))
            set_value(cfg.ssid, sizeof(cfg.ssid), line + 5, len - 5u);
        else if (key_is(line, len, "psk"))
            set_value(cfg.psk, sizeof(cfg.psk), line + 4, len - 4u);
        else if (key_is(line, len, "ip")) {
            set_value(value, sizeof(value), line + 3, len - 3u);
            in4_pton(value, &cfg.ip);
        } else if (key_is(line, len, "netmask")) {
            set_value(value, sizeof(value), line + 8, len - 8u);
            in4_pton(value, &cfg.netmask);
        } else if (key_is(line, len, "gateway")) {
            set_value(value, sizeof(value), line + 8, len - 8u);
            in4_pton(value, &cfg.gateway);
        }
        line = *end ? end + 1 : end;
    }
    say("/boot/wifi.txt ssid=\"");
    t113_uart_puts(cfg.ssid);
    t113_uart_puts(cfg.psk[0] ? "\" psk=<set>" : "\" psk=<none>");
    if (cfg.ip) {
        t113_uart_puts(" ip=");
        print_ip4(cfg.ip);
    }
    t113_uart_putc('\n');
}

/* ------------------------------------------------- network choice */

static const struct cfg80211_bss *select_bss(struct wiphy *wiphy)
{
    if (cfg.ssid[0])
        return cfg80211_get_bss(wiphy, (const uint8_t *)cfg.ssid,
                                net_strlen(cfg.ssid));
    for (uint32_t i = 0; i < sizeof(default_ssids) / sizeof(default_ssids[0]); ++i) {
        const struct cfg80211_bss *bss =
            cfg80211_get_bss(wiphy, (const uint8_t *)default_ssids[i],
                             net_strlen(default_ssids[i]));
        if (bss)
            return bss;
    }
    return 0;
}

static int is_suite(const uint8_t *p, uint32_t suite)
{
    return get_unaligned_be32(p) == suite;
}

/*
 * Check the AP's RSN element: we speak PSK with CCMP pairwise; the group
 * cipher may be CCMP or TKIP.  Builds our own RSN element in out.
 */
static int build_rsn(const struct cfg80211_bss *bss, uint8_t *out,
                     uint32_t *out_len, uint32_t *group_cipher)
{
    const uint8_t *ie = cfg80211_find_ie(WLAN_EID_RSN, bss->ies, bss->ies_len);
    if (!ie)
        return -EINVAL;
    const uint8_t *r = ie + 2;
    uint32_t n = ie[1];
    if (n < 2u + 4u + 2u + 4u || get_unaligned_le16(r) != 1u)
        return -EINVAL;
    const uint8_t *group = r + 2;
    uint32_t pairwise = get_unaligned_le16(r + 6), pos = 8;
    int ccmp = 0, psk = 0;
    for (uint32_t i = 0; i < pairwise && pos + 4u <= n; ++i, pos += 4u)
        if (is_suite(r + pos, WLAN_CIPHER_SUITE_CCMP))
            ccmp = 1;
    uint32_t akms = pos + 2u <= n ? get_unaligned_le16(r + pos) : 0;
    pos += 2u;
    for (uint32_t i = 0; i < akms && pos + 4u <= n; ++i, pos += 4u)
        if (is_suite(r + pos, WLAN_AKM_SUITE_PSK))
            psk = 1;
    if (!ccmp || !psk || !(is_suite(group, WLAN_CIPHER_SUITE_TKIP) ||
                           is_suite(group, WLAN_CIPHER_SUITE_CCMP))) {
        say("AP needs WPA2-PSK with CCMP (TKIP-only/WPA3 not supported)\n");
        return -EINVAL;
    }
    static const uint8_t tail[] = {
        0x01, 0x00, 0x00, 0x0f, 0xac, 0x04,     /* 1 pairwise: CCMP */
        0x01, 0x00, 0x00, 0x0f, 0xac, 0x02,     /* 1 AKM: PSK */
        0x00, 0x00,                             /* capabilities */
    };
    out[0] = WLAN_EID_RSN;
    out[1] = 20;
    out[2] = 1; out[3] = 0;                     /* version 1 */
    net_memcpy(out + 4, group, 4);
    net_memcpy(out + 8, tail, sizeof(tail));
    *out_len = 22;
    *group_cipher = get_unaligned_be32(group);
    return 0;
}

/* ------------------------------------------------------ keys */

static void install_keys(void)
{
    struct eapol_ctx *e = &wpa.eapol;
    if (e->ready & EAPOL_PTK_READY) {
        struct key_params p = {
            .key = eapol_tk(e),
            .key_len = WLAN_KEY_LEN_CCMP,
            .cipher = WLAN_CIPHER_SUITE_CCMP,
        };
        if (cfg80211_add_key(wpa.dev, 0, 1, wpa.bssid, &p) == 0)
            wpa.ptk_installed = 1;
    }
    if (e->ready & EAPOL_GTK_READY) {
        /* nl80211 TKIP layout is key | Tx MIC | Rx MIC; the GTK from the
         * AP has the authenticator's Tx MIC key (our Rx key) first. */
        uint8_t key[32];
        uint32_t len = WLAN_KEY_LEN_CCMP;
        net_memcpy(key, e->gtk, 16);
        if (wpa.group_cipher == WLAN_CIPHER_SUITE_TKIP) {
            net_memcpy(key + 16, e->gtk + 24, 8);
            net_memcpy(key + 24, e->gtk + 16, 8);
            len = WLAN_KEY_LEN_TKIP;
        }
        struct key_params p = {
            .key = key,
            .key_len = len,
            .seq = e->gtk_rsc,
            .cipher = wpa.group_cipher,
        };
        cfg80211_add_key(wpa.dev, e->gtk_index, 0, 0, &p);
        net_memset(key, 0, sizeof(key));
    }
    e->ready = 0;
}

static void key_work_fn(struct net_work *work)
{
    if (!wpa.pending)
        return;
    if (!wpa.pending_done && t113_time_us() < wpa.pending_deadline) {
        net_schedule_work(work);        /* check again after the next poll */
        return;
    }
    if (!wpa.pending_done)
        say("no TX status for EAPOL message 4\n");
    else if (!wpa.pending_acked)
        say("EAPOL message 4 not acknowledged\n");
    wpa.pending = 0;
    install_keys();
}

static struct net_work key_work = { .func = key_work_fn };

/* ------------------------------------------------- control port */

static void wpa_rx_eapol(struct net_device *dev, const uint8_t *src,
                         const uint8_t *frame, uint32_t len)
{
    static uint8_t reply[256];
    (void)src;                          /* mac80211 checked it is our AP */
    if (!wpa.active || dev != wpa.dev)
        return;
    int n = eapol_input(&wpa.eapol, frame, len, reply, sizeof(reply));
    if (n <= 0)
        return;
    uint32_t cookie = 0;
    int r = cfg80211_tx_control_port(dev, reply, (uint32_t)n, wpa.bssid,
                                     ETH_P_PAE, &cookie);
    if (!wpa.eapol.ready)
        return;
    if ((wpa.eapol.ready & EAPOL_PTK_READY) && r == 0) {
        wpa.pending = 1;
        wpa.pending_cookie = cookie;
        wpa.pending_done = 0;
        wpa.pending_acked = 0;
        wpa.pending_deadline = t113_time_us() + M4_STATUS_TIMEOUT_US;
        net_schedule_work(&key_work);
    } else {
        install_keys();                 /* group rekey: no new PTK */
    }
}

static void wpa_tx_status(struct net_device *dev, uint32_t cookie, int acked)
{
    (void)dev;
    if (wpa.pending && cookie == wpa.pending_cookie) {
        wpa.pending_done = 1;
        wpa.pending_acked = acked != 0;
    }
}

static void wpa_disconnected(struct net_device *dev, uint16_t reason)
{
    (void)dev;
    (void)reason;
    wpa.active = 0;
    wpa.pending = 0;
}

static const struct cfg80211_control_port_ops wpa_control_port = {
    .rx = wpa_rx_eapol,
    .tx_status = wpa_tx_status,
    .disconnected = wpa_disconnected,
};

/* ------------------------------------------------------ connect */

static int __wpa_connect(struct net_device *dev)
{
    static uint8_t pmk[32];
    struct wireless_dev *wdev = dev->ieee80211_ptr;
    uint8_t rsn[24];
    uint32_t rsn_len = 0;
    int r;

    cfg80211_disconnect(dev, WLAN_REASON_DEAUTH_LEAVING);
    inet_set_addr(dev, 0, 0, 0);
    wpa.dev = dev;
    wpa.active = 0;
    wpa.pending = 0;
    wpa.ptk_installed = 0;
    load_config();

    struct cfg80211_scan_request req;
    req.n_channels = 13;
    for (uint32_t i = 0; i < 13u; ++i)
        req.channels[i] = (uint16_t)(i + 1u);
    req.min_dwell_ms = 50;
    req.max_dwell_ms = 110;
    if ((r = cfg80211_scan(dev, &req)) < 0)
        return r;
    const struct cfg80211_bss *bss = select_bss(wdev->wiphy);
    if (!bss) {
        say("target SSID not found\n");
        return -ENODEV;
    }
    const uint8_t *ssid = cfg80211_find_ie(WLAN_EID_SSID, bss->ies, bss->ies_len);
    say("selected SSID=\"");
    for (uint32_t i = 0; i < ssid[1]; ++i)
        t113_uart_putc((char)ssid[2 + i]);
    t113_uart_puts("\" bssid=");
    net_print_mac(bss->bssid);
    t113_uart_puts(" channel=");
    net_putdec(bss->channel);
    t113_uart_putc('\n');
    net_memcpy(wpa.bssid, bss->bssid, ETH_ALEN);

    wpa.secure = (bss->capability & WLAN_CAPABILITY_PRIVACY) != 0;
    if (wpa.secure) {
        if (build_rsn(bss, rsn, &rsn_len, &wpa.group_cipher) < 0) {
            say("AP uses WEP/WPA1 or an unsupported cipher\n");
            return -EINVAL;
        }
        if (!cfg.psk[0]) {
            say("secured AP: put psk=<passphrase> in /boot/wifi.txt\n");
            return -EINVAL;
        }
        char name[33];
        net_memcpy(name, ssid + 2, ssid[1]);
        name[ssid[1]] = 0;
        say("deriving WPA2 key (PBKDF2)\n");
        wpa_pbkdf2(cfg.psk, name, pmk);
        eapol_init(&wpa.eapol, pmk, bss->bssid, dev->dev_addr, rsn, rsn_len,
                   (uint8_t)wpa.group_cipher);
        wpa.active = 1;
    }

    struct cfg80211_connect_params params = {
        .bss = bss,
        .ie = wpa.secure ? rsn : 0,
        .ie_len = wpa.secure ? rsn_len : 0,
    };
    if ((r = cfg80211_connect(dev, &params)) < 0)
        return r;

    if (wpa.secure) {
        say("WPA2 4-way handshake\n");
        uint64_t end = t113_time_us() + HANDSHAKE_TIMEOUT_US;
        while (!wpa.ptk_installed && wdev->sme_state == CFG80211_SME_CONNECTED &&
               t113_time_us() < end)
            __net_poll(dev, 10);
        if (!wpa.ptk_installed) {
            say(wdev->sme_state != CFG80211_SME_CONNECTED
                ? "AP rejected the handshake (wrong psk?)\n"
                : "4-way handshake timeout\n");
            cfg80211_disconnect(dev, WLAN_REASON_DEAUTH_LEAVING);
            return -EIO;
        }
        say("WPA2 keys installed\n");
    }
    cfg80211_port_authorized(dev);
    return 0;
}

int wpa_supplicant_connect(struct net_device *dev)
{
    if (!dev || !dev->ieee80211_ptr)
        return -ENODEV;
    rtnl_lock();
    /* Registration already starts WiFi automatically.  A second `wifi`
     * command must not tear down an authenticated WSM JOIN and immediately
     * scan on top of it; a real reconnect needs the driver's RESET/unjoin
     * sequence, which is separate from this idempotent connect operation. */
    if (dev->ieee80211_ptr->sme_state == CFG80211_SME_CONNECTED &&
        netif_carrier_ok(dev)) {
        rtnl_unlock();
        say("already connected\n");
        return 0;
    }
    int r = __wpa_connect(dev);
    rtnl_unlock();
    if (r < 0)
        return r;
    if (cfg.ip) {
        inet_set_addr(dev, cfg.ip, cfg.netmask ? cfg.netmask : 0xffffff00u,
                      cfg.gateway);
        say("static address ");
        print_ip4(cfg.ip);
        t113_uart_putc('\n');
    } else if (ipconfig_dhcp(dev, DHCP_TIMEOUT_MS) < 0) {
        say("no IPv4 address yet (try: ifconfig dhcp)\n");
    }
    return 0;
}

/* Bring up every 802.11 device as soon as it is registered. */
static int wpa_netdev_event(struct notifier_block *nb, uint32_t event,
                            struct net_device *dev)
{
    (void)nb;
    if (event == NETDEV_REGISTER && dev->ieee80211_ptr)
        wpa_supplicant_connect(dev);
    return 0;
}

static struct notifier_block wpa_notifier = {
    .notifier_call = wpa_netdev_event,
};

void wpa_supplicant_init(void)
{
    cfg80211_set_control_port_ops(&wpa_control_port);
    register_netdevice_notifier(&wpa_notifier);
}
