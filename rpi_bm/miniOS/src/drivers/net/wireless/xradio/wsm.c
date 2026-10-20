/*
 * XR829 WSM commands, confirms and indications, after the xradio
 * driver's wsm.c.  See wsm.h for the message format; the transport is
 * in bh.c.
 */
#include "platform.h"
#include "device.h"
#include "mmc.h"
#include "mutex.h"
#include "net/netutil.h"
#include "xradio.h"

#define WSM_CMD_BUF_SIZE        2048u
#define WSM_TX_BUF_SIZE         2048u
#define WSM_TX_HDR_LEN          24u      /* struct wsm_tx, SUPPORT_HT40 */

static struct {
    int ready;
    struct wsm_caps caps;
    /* pending command */
    uint16_t wait_cfm;
    int cfm_done;
    uint8_t *cfm_buf;
    uint32_t cfm_cap;
    int32_t cfm_status;
    int pm_ind;                  /* SET_PM indication arrived */
} wsm;

static uint32_t cmd_buf[WSM_CMD_BUF_SIZE / 4u];
static uint32_t tx_buf[WSM_TX_BUF_SIZE / 4u];
static struct mutex command_mutex;

static uint16_t get16(const uint8_t *p) { return (uint16_t)(p[0] | (p[1] << 8)); }
static uint32_t get32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) |
           ((uint32_t)p[3] << 24);
}
static void put16(uint8_t *p, uint32_t v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); }
static void put32(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8);
    p[2] = (uint8_t)(v >> 16); p[3] = (uint8_t)(v >> 24);
}

static void wsm_msg(const char *s) { t113_uart_puts("wsm: "); t113_uart_puts(s); }

const struct wsm_caps *wsm_get_caps(void) { return &wsm.caps; }
int wsm_ready(void) { return wsm.ready && !xradio_bh_halted(); }

/* ---------------------------------------------------------- RX side */

static void parse_startup(const uint8_t *p, uint32_t len)
{
    if (len < 4u + 20u)
        return;
    p += 4;
    wsm.caps.num_bufs = get16(p + 0);
    wsm.caps.buf_size = get16(p + 2);
    wsm.caps.hw_id = get16(p + 4);
    wsm.caps.hw_subid = get16(p + 6);
    uint16_t status = get16(p + 8);
    wsm.caps.fw_cap = get16(p + 10);
    wsm.caps.fw_type = get16(p + 12);
    wsm.caps.fw_api = get16(p + 14);
    wsm.caps.fw_build = get16(p + 16);
    wsm.caps.fw_version = get16(p + 18);
    uint32_t n = 0;
    for (; n + 1u < sizeof(wsm.caps.label) && 24u + n < len; ++n) {
        char c = (char)p[20 + n];
        if (!c)
            break;
        wsm.caps.label[n] = (c >= 32 && c < 127) ? c : '.';
    }
    wsm.caps.label[n] = '\0';
    if (!wsm.caps.num_bufs)
        wsm.caps.num_bufs = 1;
    xradio_bh_set_caps(wsm.caps.num_bufs, wsm.caps.buf_size);
    wsm_msg("firmware startup: ");
    net_putdec(wsm.caps.num_bufs);
    t113_uart_puts(" x ");
    net_putdec(wsm.caps.buf_size);
    t113_uart_puts(" B input buffers, hw ");
    net_putdec(wsm.caps.hw_id);
    t113_uart_putc('.');
    net_putdec(wsm.caps.hw_subid);
    t113_uart_puts(", type ");
    net_putdec(wsm.caps.fw_type);
    t113_uart_puts(", api ");
    t113_uart_puthex(wsm.caps.fw_api);
    t113_uart_puts(status ? ", STATUS ERROR" : "");
    t113_uart_puts("\nwsm: firmware label \"");
    t113_uart_puts(wsm.caps.label);
    t113_uart_puts("\"\n");
    if (!status)
        wsm.ready = 1;
}

static void tx_confirm(const uint8_t *c)
{
    xradio_tx_confirm_cb(get32(c), get32(c + 4));
}

void wsm_handle_rx(const uint8_t *m, uint32_t len)
{
    uint16_t id = WSM_MSG_ID(get16(m + 2));

    if (id & 0x0400u) {                         /* confirm */
        if (id == 0x0404u) {
            if (len >= 12u)
                tx_confirm(m + 4);
            return;
        }
        if (id == 0x041eu) {                    /* multi TX confirm */
            uint32_t cnt = len >= 8u ? get32(m + 4) : 0;
            const uint8_t *c = m + 8;
            for (uint32_t i = 0; i < cnt && c + 32 <= m + len; ++i, c += 32u)
                tx_confirm(c);
            return;
        }
        if (wsm.wait_cfm && id == wsm.wait_cfm) {
            uint32_t n = len - 4u;
            if (n > wsm.cfm_cap)
                n = wsm.cfm_cap;
            for (uint32_t i = 0; i < n; ++i)
                wsm.cfm_buf[i] = m[4 + i];
            wsm.cfm_status = len >= 8u ? (int32_t)get32(m + 4) : -EIO;
            wsm.cfm_done = 1;
        } else {
            wsm_msg("unexpected confirm ");
            t113_uart_puthex(id);
            t113_uart_putc('\n');
        }
        return;
    }
    switch (id) {
    case WSM_EXCEPTION_IND:
        wsm_msg("FIRMWARE EXCEPTION, data:");
        for (uint32_t i = 4; i + 4 <= len && i < 4 + 64; i += 4) {
            t113_uart_putc(' ');
            t113_uart_puthex(get32(m + i));
        }
        t113_uart_putc('\n');
        xradio_bh_halt();
        break;
    case WSM_STARTUP_IND:
        parse_startup(m, len);
        break;
    case WSM_SET_PM_IND:
        wsm.pm_ind = 1;
        break;
    case WSM_RX_IND:
        xradio_rx_cb(m, len);
        break;
    case WSM_SCAN_COMPLETE_IND:
        xradio_scan_complete_cb(m, len);
        break;
    case WSM_EVENT_IND:
        if (len >= 8u)
            xradio_event_cb(get32(m + 4), len >= 12u ? get32(m + 8) : 0u);
        break;
    default:
        if (!wsm.ready) {
            wsm_msg("indication ");
            t113_uart_puthex(id);
            t113_uart_puts(" before startup\n");
        }
        break;
    }
}

/* ---------------------------------------------------------- TX side */

int wsm_cmd(uint16_t req, const void *payload, uint32_t len,
            void *cfm, uint32_t cfm_cap, int timeout_ms)
{
    static uint32_t no_cfm[4];
    uint8_t *b = (uint8_t *)cmd_buf;
    if (!wsm.ready || xradio_bh_halted())
        return -ENODEV;
    if (len + WSM_HDR_LEN > sizeof(cmd_buf))
        return -EINVAL;
    if (mutex_lock(&command_mutex) < 0)
        return -EBUSY;
    const uint8_t *src = payload;
    for (uint32_t i = 0; i < len; ++i)
        b[4 + i] = src[i];
    put16(b + 2, req);                  /* if_id 0 */

    wsm.wait_cfm = (uint16_t)(req | 0x0400u);
    wsm.cfm_done = 0;
    wsm.cfm_buf = cfm ? cfm : (uint8_t *)no_cfm;
    wsm.cfm_cap = cfm ? cfm_cap : sizeof(no_cfm);
    wsm.cfm_status = -ETIMEDOUT;

    int ret = xradio_bh_tx(b, len + WSM_HDR_LEN, sizeof(cmd_buf));
    if (ret < 0) {
        wsm.wait_cfm = 0;
        mutex_unlock(&command_mutex);
        return ret;
    }
    uint64_t end = t113_time_us() + (uint64_t)timeout_ms * 1000u;
    while (!wsm.cfm_done && !xradio_bh_halted()) {
        if ((ret = xradio_bh_poll(5)) < 0)
            break;
        if (t113_time_us() > end)
            break;
    }
    wsm.wait_cfm = 0;
    if (!wsm.cfm_done) {
        wsm_msg("no confirm for request ");
        t113_uart_puthex(req);
        t113_uart_putc('\n');
        ret = ret < 0 ? ret : -ETIMEDOUT;
        mutex_unlock(&command_mutex);
        return ret;
    }
    ret = wsm.cfm_status;
    mutex_unlock(&command_mutex);
    return ret;
}

int wsm_write_mib(uint16_t mib_id, const void *data, uint32_t len)
{
    static uint8_t p[256];
    if (len + 4u > sizeof(p))
        return -EINVAL;
    put16(p, mib_id);
    put16(p + 2, len);
    const uint8_t *s = data;
    for (uint32_t i = 0; i < len; ++i)
        p[4 + i] = s[i];
    int st = wsm_cmd(WSM_WRITE_MIB_REQ, p, len + 4u, 0, 0, 1000);
    if (st) {
        wsm_msg("write MIB ");
        t113_uart_puthex(mib_id);
        t113_uart_puts(" failed, status ");
        t113_uart_puthex((uint32_t)st);
        t113_uart_putc('\n');
    }
    return st;
}

int wsm_read_mib(uint16_t mib_id, void *data, uint32_t *len)
{
    uint8_t request[4];
    uint8_t confirm[4u + 2u + 2u + 256u];
    if (!data || !len || *len > 256u)
        return -EINVAL;

    /* xradio wsm_read_mib(): mibId, argument-size, optional arguments.
     * This harmless query has no arguments. */
    put16(request, mib_id);
    put16(request + 2, 0);
    int st = wsm_cmd(WSM_READ_MIB_REQ, request, sizeof(request),
                     confirm, sizeof(confirm), 1000);
    if (st)
        return st;
    if (get16(confirm + 4) != mib_id)
        return -EIO;

    uint32_t actual = get16(confirm + 6);
    if (actual > 256u)
        return -EIO;
    uint32_t copied = actual < *len ? actual : *len;
    uint8_t *dst = (uint8_t *)data;
    for (uint32_t i = 0; i < copied; ++i)
        dst[i] = confirm[8 + i];
    *len = copied;
    return 0;
}

int wsm_configuration(const uint8_t station_id[6], const void *dpd,
                      uint32_t dpd_len, struct wsm_configuration *result)
{
    static uint8_t request[1024];
    uint8_t confirm[40];
    if (!station_id || !dpd || !result || dpd_len + 24u > sizeof(request))
        return -EINVAL;

    put32(request + 0, 512);             /* max TX MSDU lifetime, TU */
    put32(request + 4, 512);             /* max RX lifetime, TU */
    put32(request + 8, 2347);            /* RTS disabled for normal frames */
    put16(request + 12, dpd_len + 12u);  /* DPD block including its header */
    put16(request + 14, 1);              /* DPD version */
    for (uint32_t i = 0; i < 6; ++i)
        request[16 + i] = station_id[i];
    put16(request + 22, 5);              /* DPD flags used by xradio Linux */
    const uint8_t *src = (const uint8_t *)dpd;
    for (uint32_t i = 0; i < dpd_len; ++i)
        request[24 + i] = src[i];

    int st = wsm_cmd(WSM_CONFIGURATION_REQ, request, 24u + dpd_len,
                     confirm, sizeof(confirm), 2000);
    if (st)
        return st;
    for (uint32_t i = 0; i < 6; ++i)
        result->station_id[i] = confirm[4 + i];
    result->bands = confirm[10];
    result->rate_mask = get32(confirm + 12);
    return 0;
}

/*
 * Active scan is not self-contained in WSM: firmware transmits the probe
 * request stored in WSM_MIB_TEMPLATE_FRAME.  The Linux xradio scan path
 * installs this template before every START_SCAN request.  Omitting it can
 * make XR829 debug firmware raise an exception as soon as num_probes != 0.
 */
int wsm_set_probe_request_template(const uint8_t station_id[6])
{
    static uint8_t t[8u + 24u + 2u + 10u + 6u];
    uint32_t off = 0;
    if (!station_id)
        return -EINVAL;

    /* SUPPORT_HT40 template header: u16 type, u16 rate entry, u32 length */
    put16(t + off, 0); off += 2;          /* WSM_FRAME_TYPE_PROBE_REQUEST */
    put16(t + off, WSM_RATE_MGMT); off += 2;
    put32(t + off, sizeof(t) - 8u); off += 4;

    /* IEEE 802.11 probe-request management header. */
    put16(t + off, 0x0040); off += 2;     /* type=management, subtype=probe */
    put16(t + off, 0); off += 2;          /* duration */
    for (uint32_t i = 0; i < 6u; ++i) t[off++] = 0xff; /* DA */
    for (uint32_t i = 0; i < 6u; ++i) t[off++] = station_id[i]; /* SA */
    for (uint32_t i = 0; i < 6u; ++i) t[off++] = 0xff; /* BSSID */
    put16(t + off, 0); off += 2;          /* sequence control */

    t[off++] = 0; t[off++] = 0;          /* wildcard SSID IE */
    t[off++] = 1; t[off++] = 8;          /* supported rates IE */
    t[off++] = 2;  t[off++] = 4;  t[off++] = 11; t[off++] = 22;
    t[off++] = 12; t[off++] = 18; t[off++] = 24; t[off++] = 36;
    t[off++] = 50; t[off++] = 4;         /* extended supported rates IE */
    t[off++] = 48; t[off++] = 72; t[off++] = 96; t[off++] = 108;

    if (off != sizeof(t))
        return -EIO;
    return wsm_write_mib(WSM_MIB_TEMPLATE_FRAME, t, sizeof(t));
}

int wsm_scan(const struct wsm_scan_channel *channels, uint8_t num_channels,
             const uint8_t *ssid, uint8_t ssid_len)
{
    uint8_t request[12u + 48u * 16u + 36u];
    if (!channels || !num_channels || num_channels > 48u || ssid_len > 32u)
        return -EINVAL;
    uint32_t off = 0;
    request[off++] = 0;                  /* 2.4 GHz */
    request[off++] = 0;                  /* foreground scan */
    request[off++] = 0;                  /* flags */
    request[off++] = 0;                  /* 1 Mbps probe transmit rate */
    put32(request + off, 0); off += 4;   /* not an auto-scan */
    request[off++] = ssid_len ? 2 : 0;   /* zero selects passive scan */
    request[off++] = num_channels;
    request[off++] = ssid_len ? 1 : 0;
    request[off++] = 100;                /* probe delay, microseconds */
    for (uint32_t i = 0; i < num_channels; ++i) {
        put16(request + off, channels[i].number); off += 2;
        put16(request + off, 0); off += 2;
        put32(request + off, channels[i].min_time_ms); off += 4;
        put32(request + off, channels[i].max_time_ms); off += 4;
        put32(request + off, 0); off += 4; /* firmware-selected TX power */
    }
    if (ssid_len) {
        put32(request + off, ssid_len); off += 4;
        for (uint32_t i = 0; i < 32u; ++i)
            request[off++] = i < ssid_len ? ssid[i] : 0;
    }
    return wsm_cmd(WSM_START_SCAN_REQ, request, off, 0, 0, 2000);
}

/* JOIN 0x000B, SUPPORT_HT40 layout (60 bytes); confirm status 0 = joined. */
int wsm_join(const struct wsm_join *j)
{
    uint8_t request[60], confirm[12];
    uint32_t off = 0;
    if (!j || !j->ssid || !j->ssid_len || j->ssid_len > 32u || !j->channel)
        return -EINVAL;
    put16(request + off, j->phy_mode ? j->phy_mode : 0x0007u); off += 2;
    put16(request + off, j->channel); off += 2;
    for (uint32_t i = 0; i < 6u; ++i) request[off++] = j->bssid[i];
    put16(request + off, 0); off += 2;  /* ATIM window */
    request[off++] = 1;                 /* infrastructure BSS */
    /* The vendor driver enables this even when the BSS was found by a
     * passive scan; it lets firmware establish beacon synchronization. */
    request[off++] = 1;                 /* probe for join */
    request[off++] = j->dtim_period ? j->dtim_period : 1u;
    request[off++] = 0;                 /* flags, MAC instance 0 */
    put32(request + off, j->ssid_len); off += 4;
    for (uint32_t i = 0; i < 32u; ++i)
        request[off++] = i < j->ssid_len ? j->ssid[i] : 0;
    put32(request + off, j->beacon_interval ? j->beacon_interval : 100u); off += 4;
    put32(request + off, j->basic_rates ? j->basic_rates : 7u); off += 4;
    return wsm_cmd(WSM_JOIN_REQ, request, off, confirm, sizeof(confirm), 3000);
}

/* Vendor default EDCA (sta.c vif_setup); arrays on the wire are BK, BE,
 * VI, VO: cwMin[4], cwMax[4], aifs[4], txop_us[4], maxRxLifetime[4]. */
int wsm_set_edca_default(void)
{
    static const uint16_t cw_min[4] = { 15, 3, 7, 3 };
    static const uint16_t cw_max[4] = { 1023, 7, 15, 7 };
    static const uint8_t aifs[4] = { 7, 2, 2, 2 };
    static const uint16_t txop[4] = { 0, 0, 3008, 1504 };
    uint8_t p[44];
    uint32_t off = 0;
    for (uint32_t i = 0; i < 4u; ++i) { put16(p + off, cw_min[i]); off += 2; }
    for (uint32_t i = 0; i < 4u; ++i) { put16(p + off, cw_max[i]); off += 2; }
    for (uint32_t i = 0; i < 4u; ++i) p[off++] = aifs[i];
    for (uint32_t i = 0; i < 4u; ++i) { put16(p + off, txop[i]); off += 2; }
    for (uint32_t i = 0; i < 4u; ++i) { put32(p + off, 0xc8); off += 4; }
    return wsm_cmd(WSM_SET_EDCA_REQ, p, off, 0, 0, 1000);
}

/*
 * Rate retry policies (MIB 0x1016, HT40: 20 bytes each).  Rate entry:
 * [15:14] modem (0 legacy), [13:12] bandwidth, [11:8] flags,
 * [7:4] rate index (1M=0 2M=1 5.5M=2 11M=3 6M=6 ... 54M=13), [3:0] tries.
 */
int wsm_set_tx_policies(void)
{
    static const uint16_t rates[2][3] = {
        { WSM_RATE_MGMT, 0, 0 },                 /* 1 Mbps x15 */
        { WSM_RATE_DATA, 0x0034u, 0x0007u },     /* 24M x4, 11M x4, 1M x7 */
    };
    uint8_t p[4u + 2u * 20u];
    for (uint32_t i = 0; i < sizeof(p); ++i) p[i] = 0;
    p[0] = 2;
    for (uint32_t n = 0; n < 2u; ++n) {
        uint8_t *e = p + 4u + n * 20u;
        e[0] = (uint8_t)n;              /* policy index */
        e[1] = 14;                      /* short retry count */
        e[2] = 14;                      /* long retry count */
        e[3] = 0x0c;                    /* terminate at end, count 1st TX */
        for (uint32_t r = 0; r < 3u; ++r)
            put16(e + 8u + r * 2u, rates[n][r]);
    }
    return wsm_write_mib(WSM_MIB_SET_TX_RATE_RETRY_POLICY, p, sizeof(p));
}

int wsm_mib32(uint16_t mib_id, uint32_t value)
{
    uint8_t v[4];
    put32(v, value);
    return wsm_write_mib(mib_id, v, sizeof(v));
}

int wsm_set_bss_params(uint16_t aid, uint8_t beacon_lost_count,
                       uint32_t operational_rates)
{
    uint8_t p[8];
    p[0] = 0;                           /* do not just reset beacon loss */
    p[1] = beacon_lost_count;
    put16(p + 2, aid & 0x3fffu);
    put32(p + 4, operational_rates);
    return wsm_cmd(WSM_SET_BSS_PARAMS_REQ, p, sizeof(p), 0, 0, 1000);
}

/* Packed XR829 wire layout: u8 periods, u8 reserved, le16 interval. */
int wsm_set_beacon_wakeup_period(uint8_t beacon_periods,
                                 uint16_t listen_interval)
{
    uint8_t p[4] = { beacon_periods, 0, 0, 0 };
    put16(p + 2, listen_interval);
    return wsm_write_mib(WSM_MIB_BEACON_WAKEUP_PERIOD, p, sizeof(p));
}

/* Beacon-filter control consists of two little-endian u32 values. */
int wsm_set_beacon_filter(int enabled, uint32_t beacon_count)
{
    uint8_t p[8];
    uint32_t flags = enabled ? (WSM_BEACON_FILTER_ENABLE |
                                WSM_BEACON_FILTER_AUTO_ERP |
                                WSM_BEACON_FILTER_AUTO_HT) : 0u;
    put32(p, flags);
    put32(p + 4, beacon_count);
    return wsm_write_mib(WSM_MIB_BEACON_FILTER_ENABLE, p, sizeof(p));
}

int wsm_set_pm(uint8_t mode)
{
    uint8_t p[4] = { mode, 200, 200, 0 };
    wsm.pm_ind = 0;
    int st = wsm_cmd(WSM_SET_PM_REQ, p, sizeof(p), 0, 0, 1000);
    if (st)
        return st;
    uint64_t end = t113_time_us() + 1000000u;
    while (!wsm.pm_ind && !xradio_bh_halted() && t113_time_us() < end)
        if (xradio_bh_poll(10) < 0)
            break;
    return wsm.pm_ind ? 0 : -ETIMEDOUT;
}

/* ADD_KEY 0x000C: u8 type, u8 entry index, u16 0, 40-byte union. */
static int add_key(uint8_t *p)
{
    int st = wsm_cmd(WSM_ADD_KEY_REQ, p, 44, 0, 0, 1000);
    for (uint32_t i = 0; i < 44u; ++i) p[i] = 0;    /* no key copies left */
    return st;
}

int wsm_add_key_pairwise(uint8_t index, const uint8_t peer[6],
                         const uint8_t tk[16])
{
    uint8_t p[44];
    for (uint32_t i = 0; i < sizeof(p); ++i) p[i] = 0;
    p[0] = WSM_KEY_TYPE_AES_PAIRWISE;
    p[1] = index;
    for (uint32_t i = 0; i < 6u; ++i) p[4 + i] = peer[i];
    for (uint32_t i = 0; i < 16u; ++i) p[12 + i] = tk[i];
    return add_key(p);
}

/* AES group: key[16], keyId, 3 x 0, RSC[8].  TKIP group: key[16],
 * rx MIC key[8], keyId, 3 x 0, RSC[8]; gtk is then 32 bytes. */
int wsm_add_key_group(uint8_t type, uint8_t index, const uint8_t *gtk,
                      uint8_t key_id, const uint8_t rsc[8])
{
    uint8_t p[44];
    uint32_t off = 4;
    for (uint32_t i = 0; i < sizeof(p); ++i) p[i] = 0;
    p[0] = type;
    p[1] = index;
    for (uint32_t i = 0; i < 16u; ++i) p[off++] = gtk[i];
    if (type == WSM_KEY_TYPE_TKIP_GROUP)
        for (uint32_t i = 0; i < 8u; ++i) p[off++] = gtk[16 + i];
    p[off] = key_id;
    off += 4;
    for (uint32_t i = 0; i < 8u; ++i) p[off++] = rsc ? rsc[i] : 0;
    return add_key(p);
}

int wsm_remove_key(uint8_t index)
{
    uint8_t p[4] = { index, 0, 0, 0 };
    return wsm_cmd(WSM_REMOVE_KEY_REQ, p, sizeof(p), 0, 0, 1000);
}

int wsm_tx_frame(uint32_t packet_id, const uint8_t *frame, uint32_t len,
                 uint8_t queue, uint8_t policy, uint16_t rate_entry,
                 uint8_t epta_prio)
{
    uint8_t *b = (uint8_t *)tx_buf;
    if (!wsm.ready)
        return -ENODEV;
    if (WSM_TX_HDR_LEN + len > sizeof(tx_buf))
        return -EINVAL;
    put16(b + 2, WSM_TX_REQ);
    put32(b + 4, packet_id);            /* packetID */
    b[8] = queue & 3u;                  /* raw_link_id 0 (STA) << 2 | queue */
    b[9] = 0;                           /* more */
    b[10] = WSM_TX_HDR_LEN;             /* DataOffset */
    b[11] = epta_prio;
    put16(b + 12, rate_entry);          /* TxRateEntry */
    b[14] = policy;                     /* TxPolicyIndex */
    b[15] = 0;                          /* ExpireTimeSetting */
    put32(b + 16, 0);                   /* expireTime: firmware default */
    put32(b + 20, 0);
    for (uint32_t i = 0; i < len; ++i)
        b[WSM_TX_HDR_LEN + i] = frame[i];
    return xradio_bh_tx(b, WSM_TX_HDR_LEN + len, sizeof(tx_buf));
}

int wsm_init(struct sdio_func *func, int timeout_ms)
{
    mutex_init(&command_mutex);
    wsm.ready = 0;
    wsm.caps.num_bufs = 1;
    wsm.caps.buf_size = 0;
    xradio_bh_init(func);

    uint64_t end = t113_time_us() + (uint64_t)timeout_ms * 1000u;
    while (!wsm.ready && !xradio_bh_halted() && t113_time_us() < end) {
        if (xradio_bh_poll(10) < 0)
            break;
    }
    if (!wsm.ready) {
        wsm_msg("no startup indication from firmware\n");
        return -ETIMEDOUT;
    }
    /* Keep the device awake (main.c after startup): CONTROL = WUP. */
    xradio_reg_write_32(func, HIF_CONTROL_REG_ID, HIF_CTRL_WUP_BIT);
    return 0;
}
