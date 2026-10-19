/* XR829 station-management layer: firmware configuration and scan. */
#include "platform.h"
#include "device.h"
#include "xradio/wsm.h"
#include "xradio/sta.h"

#define SCAN_AP_LOG_MAX 16u

static const char *const target_ssids[] = {
    "TP-Link_B114",       /* preferred: XR829 is a 2.4 GHz radio */
    "TP-Link_B114_5G",
};

static struct {
    int scanning;
    int scan_done;
    uint32_t scan_status;
    uint32_t frames;
    int found;
    uint8_t bssid[6];
    uint16_t channel;
    uint8_t rcpi;
    uint8_t rsn[64];
    uint8_t rsn_len;
    int target_index;
    uint8_t ssid[32];
    uint8_t ssid_len;
    uint8_t dtim_period;
    uint16_t beacon_interval;
    uint8_t ap_count;
    uint8_t ap_bssid[SCAN_AP_LOG_MAX][6];
} sta;

static uint16_t le16(const uint8_t *p)
{
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

static uint32_t le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static int bytes_equal(const uint8_t *a, const uint8_t *b, uint32_t n)
{
    for (uint32_t i = 0; i < n; ++i)
        if (a[i] != b[i]) return 0;
    return 1;
}

static uint32_t string_len(const char *s)
{
    uint32_t n = 0;
    while (s[n]) ++n;
    return n;
}

static int target_ssid_index(const uint8_t *ssid, uint8_t len)
{
    for (uint32_t i = 0; i < sizeof(target_ssids) / sizeof(target_ssids[0]); ++i) {
        uint32_t target_len = string_len(target_ssids[i]);
        if (len == target_len &&
            bytes_equal(ssid, (const uint8_t *)target_ssids[i], len))
            return (int)i;
    }
    return -1;
}

static void print_mac(const uint8_t mac[6]);

static int remember_ap(const uint8_t bssid[6])
{
    for (uint32_t i = 0; i < sta.ap_count; ++i)
        if (bytes_equal(sta.ap_bssid[i], bssid, 6))
            return 0;
    if (sta.ap_count >= SCAN_AP_LOG_MAX)
        return 0;
    for (uint32_t i = 0; i < 6u; ++i)
        sta.ap_bssid[sta.ap_count][i] = bssid[i];
    ++sta.ap_count;
    return 1;
}

static void print_ap(const uint8_t bssid[6], const uint8_t *ssid,
                     uint8_t ssid_len, uint16_t channel, uint8_t rcpi)
{
    t113_uart_puts("xradio: AP ssid=\"");
    if (!ssid_len)
        t113_uart_puts("<hidden>");
    for (uint32_t i = 0; i < ssid_len; ++i) {
        uint8_t c = ssid[i];
        t113_uart_putc((c >= 32u && c < 127u) ? (char)c : '.');
    }
    t113_uart_puts("\" bssid="); print_mac(bssid);
    t113_uart_puts(" channel="); t113_uart_puthex(channel);
    t113_uart_puts(" rcpi="); t113_uart_puthex(rcpi);
    t113_uart_putc('\n');
}

static void parse_scan_frame(const uint8_t *msg, uint32_t len)
{
    if (len < WSM_HDR_LEN + WSM_RX_HDR_LEN + 36u)
        return;
    const uint8_t *rx = msg + WSM_HDR_LEN;
    const uint8_t *frame = rx + WSM_RX_HDR_LEN;
    uint32_t frame_len = len - WSM_HDR_LEN - WSM_RX_HDR_LEN;
    uint16_t fc = le16(frame);
    uint8_t subtype = (uint8_t)((fc >> 4) & 0xfu);
    if ((fc & 0xcu) || (subtype != 8u && subtype != 5u))
        return;                            /* beacon or probe response only */
    ++sta.frames;

    const uint8_t *ssid = 0;
    uint8_t ssid_len = 0;
    uint32_t pos = 36u;
    int matched_target = -1;
    uint16_t channel = le16(rx + 4);
    uint8_t dtim_period = 1;
    while (pos + 2u <= frame_len) {
        uint8_t id = frame[pos], n = frame[pos + 1u];
        if (pos + 2u + n > frame_len) break;
        if (id == 0) {
            ssid = frame + pos + 2u;
            ssid_len = n <= 32u ? n : 32u;
            matched_target = target_ssid_index(ssid, ssid_len);
        }
        if (id == 3 && n == 1)
            channel = frame[pos + 2u];
        if (id == 5 && n >= 2u)
            dtim_period = frame[pos + 3u];
        if (matched_target >= 0 && id == 48 && n + 2u <= sizeof(sta.rsn)) {
            sta.rsn_len = n + 2u;
            for (uint32_t i = 0; i < sta.rsn_len; ++i)
                sta.rsn[i] = frame[pos + i];
        }
        pos += 2u + n;
    }
    const uint8_t *bssid = frame + 16u;
    if (remember_ap(bssid))
        print_ap(bssid, ssid, ssid_len, channel, rx[7]);
    if (matched_target < 0)
        return;
    /* Keep the first match, except that the 2.4 GHz name has priority. */
    if (sta.found && sta.target_index <= matched_target)
        return;
    sta.found = 1;
    sta.target_index = matched_target;
    sta.ssid_len = ssid_len;
    for (uint32_t i = 0; i < ssid_len; ++i) sta.ssid[i] = ssid[i];
    sta.dtim_period = dtim_period;
    sta.beacon_interval = le16(frame + 32u);
    sta.channel = channel;
    sta.rcpi = rx[7];
    for (uint32_t i = 0; i < 6; ++i)
        sta.bssid[i] = frame[16 + i];
}

static void sta_indication(uint16_t id, const uint8_t *msg, uint32_t len)
{
    if (id == WSM_RX_IND && sta.scanning)
        parse_scan_frame(msg, len);
    else if (id == WSM_SCAN_COMPLETE_IND && len >= 8u) {
        sta.scan_status = le32(msg + 4);
        sta.scan_done = 1;
        sta.scanning = 0;
    }
}

static void print_mac(const uint8_t mac[6])
{
    static const char hex[] = "0123456789abcdef";
    for (uint32_t i = 0; i < 6; ++i) {
        if (i) t113_uart_putc(':');
        t113_uart_putc(hex[mac[i] >> 4]);
        t113_uart_putc(hex[mac[i] & 15]);
    }
}

int xradio_sta_start(const void *sdd, uint32_t sdd_len)
{
    static const uint8_t requested_mac[6] = { 0x02, 0x0a, 0x9e, 0x22, 0x82, 0x01 };
    struct wsm_configuration cfg;
    t113_uart_puts("xradio: configure firmware, SDD bytes=");
    t113_uart_puthex(sdd_len);
    t113_uart_putc('\n');
    int ret = wsm_configuration(requested_mac, sdd, sdd_len, &cfg);
    if (ret < 0) {
        t113_uart_puts("xradio: WSM configuration failed ");
        t113_uart_puthex((uint32_t)ret); t113_uart_putc('\n');
        return ret;
    }
    t113_uart_puts("xradio: configured MAC "); print_mac(cfg.station_id);
    t113_uart_puts(" bands="); t113_uart_puthex(cfg.bands);
    t113_uart_puts(" rates="); t113_uart_puthex(cfg.rate_mask); t113_uart_putc('\n');

    struct wsm_scan_channel channels[13];
    for (uint32_t i = 0; i < 13u; ++i) {
        channels[i].number = i + 1u;
        channels[i].min_time_ms = 50;
        channels[i].max_time_ms = 110;
    }
    sta.scanning = 1; sta.scan_done = 0; sta.frames = 0; sta.found = 0;
    sta.ap_count = 0;
    sta.target_index = -1;
    sta.rsn_len = 0;
    wsm_set_ind_handler(sta_indication);
    /* First bring-up uses a broadcast passive scan.  It does not exercise
     * firmware's probe-request TX/template path, which is kept separate until
     * RX/beacon parsing is known-good on this XR829 firmware revision. */
    t113_uart_puts("xradio: passive scan channels 1-13\n");
    ret = wsm_scan(channels, 13, 0, 0);
    if (ret < 0) {
        sta.scanning = 0;
        t113_uart_puts("xradio: scan command failed ");
        t113_uart_puthex((uint32_t)ret); t113_uart_putc('\n');
        return ret;
    }
    uint64_t deadline = t113_time_us() + 5000000u;
    while (!sta.scan_done && t113_time_us() < deadline)
        if (wsm_poll(20) < 0) break;
    if (!sta.scan_done) {
        t113_uart_puts("xradio: scan completion timeout\n");
        return -ETIMEDOUT;
    }
    t113_uart_puts("xradio: scan complete status=");
    t113_uart_puthex(sta.scan_status);
    t113_uart_puts(" management-frames="); t113_uart_puthex(sta.frames);
    t113_uart_putc('\n');
    if (!sta.found) {
        t113_uart_puts("xradio: neither target SSID found\n");
        return -ENODEV;
    }
    t113_uart_puts("xradio: selected SSID=\"");
    t113_uart_puts(target_ssids[sta.target_index]);
    t113_uart_puts("\" bssid="); print_mac(sta.bssid);
    t113_uart_puts(" channel="); t113_uart_puthex(sta.channel);
    t113_uart_puts(" rcpi="); t113_uart_puthex(sta.rcpi);
    t113_uart_puts(" rsn-bytes="); t113_uart_puthex(sta.rsn_len);
    t113_uart_putc('\n');

    struct wsm_join join;
    join.band = 0;
    join.channel = sta.channel;
    join.ssid = sta.ssid;
    join.ssid_len = sta.ssid_len;
    join.dtim_period = sta.dtim_period;
    join.beacon_interval = sta.beacon_interval;
    for (uint32_t i = 0; i < 6u; ++i) join.bssid[i] = sta.bssid[i];
    t113_uart_puts("xradio: joining selected BSS\n");
    ret = wsm_join(&join);
    if (ret < 0) {
        t113_uart_puts("xradio: WSM JOIN failed ");
        t113_uart_puthex((uint32_t)ret); t113_uart_putc('\n');
        return ret;
    }
    t113_uart_puts("xradio: WSM JOIN accepted; association/WPA pending\n");
    return 0;
}
