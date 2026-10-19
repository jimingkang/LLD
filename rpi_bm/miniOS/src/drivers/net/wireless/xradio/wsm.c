/*
 * XR829 WSM message layer (polled), after xradio bh.c / wsm.c.
 * See src/include/net/xradio/wsm.h for the wire format.
 */
#include "platform.h"
#include "mmc.h"
#include "xradio/wsm.h"
#include "mutex.h"

#define HIF_CONTROL_REG_ID      0x1u
#define HIF_IN_OUT_QUEUE_REG_ID 0x2u
#define HIF_ADDR(buf_id, id)    ((((uint32_t)(buf_id) & 0x1fu) << 7) | ((id) << 2))
#define HIF_CTRL_NEXT_LEN_MASK  0x0fffu
#define HIF_CTRL_WUP_BIT        (1u << 12)

#define WSM_RX_BUF_SIZE         4096u
#define WSM_TX_BUF_SIZE         2048u
#define WSM_TX_HDR_LEN          24u      /* struct wsm_tx, SUPPORT_HT40 */
#define TX_STATUS_SLOTS         16u

static struct {
    struct sdio_func *func;
    int ready;
    int dead;
    struct wsm_caps caps;
    uint8_t tx_seq, rx_seq;
    uint8_t buf_id_tx, buf_id_rx;
    int hw_bufs_used;
    uint32_t next_ctrl;          /* piggybacked CONTROL, 0 = read register */
    wsm_ind_handler ind;
    /* pending command */
    uint16_t wait_cfm;
    int cfm_done;
    uint8_t *cfm_buf;
    uint32_t cfm_cap;
    int32_t cfm_status;
    /* TX confirms */
    uint32_t next_packet_id;
    uint32_t tx_id[TX_STATUS_SLOTS];
    int32_t tx_st[TX_STATUS_SLOTS];
} wsm;

static uint32_t rx_buf[WSM_RX_BUF_SIZE / 4u];
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

static void putdec(uint32_t v)
{
    char b[11];
    int i = 10;
    b[i] = '\0';
    do {
        b[--i] = (char)('0' + v % 10u);
        v /= 10u;
    } while (v && i);
    t113_uart_puts(&b[i]);
}

static void wsm_msg(const char *s) { t113_uart_puts("wsm: "); t113_uart_puts(s); }

/* Same rule as sdio_io_rw_extended: byte mode up to min(blksz, 512). */
static uint32_t align_len(uint32_t n)
{
    uint32_t bs = wsm.func->blksz ? wsm.func->blksz : 512u;
    uint32_t byte_max = bs < 512u ? bs : 512u;
    n = (n + 3u) & ~3u;
    if (n <= byte_max)
        return n;
    return (n + bs - 1u) / bs * bs;
}

const struct wsm_caps *wsm_get_caps(void) { return &wsm.caps; }
int wsm_ready(void) { return wsm.ready && !wsm.dead; }
void wsm_set_ind_handler(wsm_ind_handler h) { wsm.ind = h; }

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
    wsm_msg("firmware startup: ");
    putdec(wsm.caps.num_bufs);
    t113_uart_puts(" x ");
    putdec(wsm.caps.buf_size);
    t113_uart_puts(" B input buffers, hw ");
    putdec(wsm.caps.hw_id);
    t113_uart_putc('.');
    putdec(wsm.caps.hw_subid);
    t113_uart_puts(", type ");
    putdec(wsm.caps.fw_type);
    t113_uart_puts(", api ");
    t113_uart_puthex(wsm.caps.fw_api);
    t113_uart_puts(status ? ", STATUS ERROR" : "");
    t113_uart_puts("\nwsm: firmware label \"");
    t113_uart_puts(wsm.caps.label);
    t113_uart_puts("\"\n");
    if (!status)
        wsm.ready = 1;
}

static void record_tx_confirm(const uint8_t *c)
{
    uint32_t id = get32(c), st = get32(c + 4);
    uint32_t slot = id % TX_STATUS_SLOTS;
    if (wsm.tx_id[slot] == id)
        wsm.tx_st[slot] = (int32_t)st;
}

static void handle_msg(const uint8_t *m, uint32_t len)
{
    uint16_t raw = get16(m + 2);
    uint16_t id = WSM_MSG_ID(raw);

    if (id & 0x0400u) {                         /* confirm */
        if (wsm.hw_bufs_used > 0)
            --wsm.hw_bufs_used;
        if (id == 0x0404u) {
            if (len >= 12u)
                record_tx_confirm(m + 4);
            return;
        }
        if (id == 0x041eu) {                    /* multi TX confirm */
            uint32_t cnt = len >= 8u ? get32(m + 4) : 0;
            const uint8_t *c = m + 8;
            /* one buffer already released above */
            for (uint32_t i = 0; i < cnt && c + 32 <= m + len; ++i, c += 32u) {
                if (i && wsm.hw_bufs_used > 0)
                    --wsm.hw_bufs_used;
                record_tx_confirm(c);
            }
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
    if (id == WSM_EXCEPTION_IND) {
        wsm_msg("FIRMWARE EXCEPTION, data:");
        for (uint32_t i = 4; i + 4 <= len && i < 4 + 64; i += 4) {
            t113_uart_putc(' ');
            t113_uart_puthex(get32(m + i));
        }
        t113_uart_putc('\n');
        wsm.dead = 1;
        return;
    }
    if (id == WSM_STARTUP_IND) {
        parse_startup(m, len);
        return;
    }
    if (wsm.ind)
        wsm.ind(id, m, len);
}

/* Read one queue transfer if CONTROL says something is pending. */
static int rx_one(void)
{
    struct sdio_func *f = wsm.func;
    uint32_t ctrl = wsm.next_ctrl;
    int ret;

    if (!(ctrl & HIF_CTRL_NEXT_LEN_MASK)) {
        if ((ret = xr829_reg_read32(f, HIF_CONTROL_REG_ID, &ctrl)) < 0)
            return ret;
    }
    wsm.next_ctrl = 0;
    uint32_t len = (ctrl & HIF_CTRL_NEXT_LEN_MASK) << 1;
    if (!len)
        return 0;
    uint32_t rd = align_len(len + 2u);
    if (len < WSM_HDR_LEN || rd > sizeof(rx_buf)) {
        wsm_msg("bad rx length ");
        putdec(len);
        t113_uart_putc('\n');
        return -EIO;
    }
    uint8_t *b = (uint8_t *)rx_buf;
    uint32_t buf_id = wsm.buf_id_rx + 1u;
    if ((ret = sdio_memcpy_fromio(f, b, HIF_ADDR(buf_id, HIF_IN_OUT_QUEUE_REG_ID), rd)) < 0) {
        wsm_msg("queue read failed\n");
        return ret;
    }
    wsm.buf_id_rx = (uint8_t)(buf_id & 3u);
    wsm.next_ctrl = get16(b + rd - 2u);         /* piggyback */

    uint8_t seq = (uint8_t)((get16(b + 2) >> 13) & 7u);
    if (seq != wsm.rx_seq) {
        wsm_msg("rx seq ");
        putdec(seq);
        t113_uart_puts(" expected ");
        putdec(wsm.rx_seq);
        t113_uart_putc('\n');
    }
    wsm.rx_seq = (uint8_t)((seq + 1u) & 7u);

    /* One transfer may carry several RX indications (multi-rx). */
    for (uint32_t off = 0; off + WSM_HDR_LEN <= len;) {
        uint32_t mlen = get16(b + off);
        if (mlen < WSM_HDR_LEN || off + mlen > len)
            break;
        handle_msg(b + off, mlen);
        off += (mlen + 3u) & ~3u;
    }
    return 1;
}

int wsm_poll(int timeout_ms)
{
    uint64_t end = t113_time_us() + (uint64_t)(timeout_ms > 0 ? timeout_ms : 0) * 1000u;
    int handled = 0;
    for (;;) {
        int r = rx_one();
        if (r < 0)
            return r;
        if (r > 0) {
            ++handled;
            continue;                   /* drain */
        }
        if (handled || t113_time_us() >= end || wsm.dead)
            return handled;
        t113_udelay(200);
    }
}

/* ---------------------------------------------------------- TX side */

static int tx_write(uint8_t *b, uint32_t len)
{
    struct sdio_func *f = wsm.func;
    uint64_t end = t113_time_us() + 2000000u;
    while (wsm.hw_bufs_used >= (int)wsm.caps.num_bufs) {
        if (wsm_poll(10) < 0 || t113_time_us() > end || wsm.dead) {
            wsm_msg("no free firmware input buffer\n");
            return -ETIMEDOUT;
        }
    }
    if (len > wsm.caps.buf_size && wsm.caps.buf_size) {
        wsm_msg("message too long\n");
        return -EINVAL;
    }
    put16(b, len);
    put16(b + 2, (get16(b + 2) & 0x1fffu) | ((uint32_t)wsm.tx_seq << 13));
    uint32_t wlen = len <= 8u ? 16u : len;
    wlen = align_len(wlen);
    if (wlen > sizeof(tx_buf))
        return -EINVAL;
    for (uint32_t i = len; i < wlen; ++i)
        b[i] = 0;
    int ret = sdio_memcpy_toio(f, HIF_ADDR(wsm.buf_id_tx, HIF_IN_OUT_QUEUE_REG_ID), b, wlen);
    if (ret < 0) {
        wsm_msg("queue write failed\n");
        return ret;
    }
    wsm.buf_id_tx = (uint8_t)((wsm.buf_id_tx + 1u) & 31u);
    wsm.tx_seq = (uint8_t)((wsm.tx_seq + 1u) & 7u);
    ++wsm.hw_bufs_used;
    return 0;
}

int wsm_cmd(uint16_t req, const void *payload, uint32_t len,
            void *cfm, uint32_t cfm_cap, int timeout_ms)
{
    static uint32_t no_cfm[4];
    uint8_t *b = (uint8_t *)tx_buf;
    if (!wsm.func || !wsm.ready || wsm.dead)
        return -ENODEV;
    if (len + WSM_HDR_LEN > sizeof(tx_buf))
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

    int ret = tx_write(b, len + WSM_HDR_LEN);
    if (ret < 0) {
        wsm.wait_cfm = 0;
        mutex_unlock(&command_mutex);
        return ret;
    }
    uint64_t end = t113_time_us() + (uint64_t)timeout_ms * 1000u;
    while (!wsm.cfm_done && !wsm.dead) {
        if ((ret = wsm_poll(5)) < 0)
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
    static uint8_t t[4u + 24u + 2u + 10u + 6u];
    uint32_t off = 0;
    if (!station_id)
        return -EINVAL;

    t[off++] = 0;                         /* WSM_FRAME_TYPE_PROBE_REQUEST */
    t[off++] = 0;                         /* firmware rate index: 1 Mbps */
    put16(t + off, sizeof(t) - 4u); off += 2;

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

int wsm_join(const struct wsm_join *j)
{
    uint8_t request[96], confirm[12];
    uint32_t off = 0;
    if (!j || !j->ssid || !j->ssid_len || j->ssid_len > 32u || !j->channel)
        return -EINVAL;
    request[off++] = 1;                 /* infrastructure BSS */
    request[off++] = j->band;
    put16(request + off, j->channel); off += 2;
    for (uint32_t i = 0; i < 6u; ++i) request[off++] = j->bssid[i];
    put16(request + off, 0); off += 2;
    request[off++] = 0;                 /* long preamble */
    request[off++] = 0;                 /* do not probe again */
    request[off++] = j->dtim_period ? j->dtim_period : 1u;
    request[off++] = 0;                 /* MAC instance 0 */
    put32(request + off, j->ssid_len); off += 4;
    for (uint32_t i = 0; i < 32u; ++i)
        request[off++] = i < j->ssid_len ? j->ssid[i] : 0;
    put32(request + off, j->beacon_interval ? j->beacon_interval : 100u); off += 4;
    put32(request + off, 7); off += 4;  /* basic rates 1, 2, 5.5 Mbps */

    /* XR829's 0x0013 JOIN extension includes initial EDCA values. */
    put16(request + off, 0x03ff); off += 2;
    for (uint32_t i = 0; i < 4u; ++i) request[off++] = 0;
    for (uint32_t i = 0; i < 4u; ++i) { put16(request + off, 0); off += 2; }
    for (uint32_t i = 0; i < 4u; ++i) { put32(request + off, 0xc8); off += 4; }
    return wsm_cmd(WSM_JOIN_REQ, request, off, confirm, sizeof(confirm), 3000);
}

int wsm_tx_frame(const uint8_t *frame, uint32_t len, uint8_t queue,
                 uint8_t policy, uint16_t rate_entry, uint8_t epta_prio)
{
    uint8_t *b = (uint8_t *)tx_buf;
    if (!wsm.func || wsm.dead)
        return -ENODEV;
    if (WSM_TX_HDR_LEN + len > sizeof(tx_buf))
        return -EINVAL;
    uint32_t id = ++wsm.next_packet_id;
    if (!id)
        id = ++wsm.next_packet_id;
    put16(b + 2, WSM_TX_REQ);
    put32(b + 4, id);                   /* packetID */
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
    uint32_t slot = id % TX_STATUS_SLOTS;
    wsm.tx_id[slot] = id;
    wsm.tx_st[slot] = -1;
    int ret = tx_write(b, WSM_TX_HDR_LEN + len);
    return ret < 0 ? ret : (int)id;
}

int wsm_tx_status(int packet_id)
{
    uint32_t slot = (uint32_t)packet_id % TX_STATUS_SLOTS;
    if (wsm.tx_id[slot] != (uint32_t)packet_id)
        return -2;
    return wsm.tx_st[slot];
}

int wsm_init(struct sdio_func *func, int timeout_ms)
{
    mutex_init(&command_mutex);
    wsm.func = func;
    wsm.ready = 0;
    wsm.dead = 0;
    wsm.tx_seq = wsm.rx_seq = 0;
    wsm.buf_id_tx = wsm.buf_id_rx = 0;
    wsm.hw_bufs_used = 0;
    wsm.next_ctrl = 0;
    wsm.caps.num_bufs = 1;
    wsm.caps.buf_size = 0;

    uint64_t end = t113_time_us() + (uint64_t)timeout_ms * 1000u;
    while (!wsm.ready && !wsm.dead && t113_time_us() < end) {
        if (wsm_poll(10) < 0)
            break;
    }
    if (!wsm.ready) {
        wsm_msg("no startup indication from firmware\n");
        return -ETIMEDOUT;
    }
    /* Keep the device awake (main.c after startup): CONTROL = WUP. */
    xr829_reg_write32(func, HIF_CONTROL_REG_ID, HIF_CTRL_WUP_BIT);
    return 0;
}
