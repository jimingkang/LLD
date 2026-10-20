/*
 * WPA2-PSK supplicant side of the 802.11i key handshakes.
 *
 * EAPOL-Key frame (802.1X version, type 3, length) followed by:
 *   0 descriptor type (2 = RSN)    1 key information (BE)
 *   3 key length                   5 replay counter (8)
 *  13 nonce (32)                  45 key IV (16)
 *  61 key RSC (8)                 69 reserved (8)
 *  77 MIC (16)                    93 key data length (BE)   95 key data
 */
#include "net/eapol.h"
#include "crypto/wpa_crypto.h"
#include "platform.h"

#define EAPOL_HDR        4u
#define KEY_BODY         95u
#define KI_VERSION_MASK  0x0007u
#define KI_PAIRWISE      0x0008u
#define KI_INSTALL       0x0040u
#define KI_ACK           0x0080u
#define KI_MIC           0x0100u
#define KI_SECURE        0x0200u
#define KI_ENCRYPTED     0x1000u

static uint16_t be16(const uint8_t *p) { return (uint16_t)((p[0] << 8) | p[1]); }
static void put_be16(uint8_t *p, uint32_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
static void copy(void *d, const void *s, uint32_t n)
{
    uint8_t *dst = d;
    const uint8_t *src = s;
    while (n--) *dst++ = *src++;
}
static void zero(void *d, uint32_t n)
{
    uint8_t *dst = d;
    while (n--) *dst++ = 0;
}
static int equal(const uint8_t *a, const uint8_t *b, uint32_t n)
{
    uint8_t diff = 0;
    for (uint32_t i = 0; i < n; ++i) diff |= (uint8_t)(a[i] ^ b[i]);
    return diff == 0;
}

void eapol_init(struct eapol_ctx *c, const uint8_t pmk[32],
                const uint8_t aa[6], const uint8_t spa[6],
                const uint8_t *rsn_ie, uint32_t rsn_len,
                uint8_t group_cipher)
{
    zero(c, sizeof(*c));
    copy(c->pmk, pmk, 32);
    copy(c->aa, aa, 6);
    copy(c->spa, spa, 6);
    if (rsn_len > sizeof(c->rsn_ie))
        rsn_len = sizeof(c->rsn_ie);
    copy(c->rsn_ie, rsn_ie, rsn_len);
    c->rsn_len = (uint8_t)rsn_len;
    c->group_cipher = group_cipher;
}

/* Replay counters must strictly increase once one has been accepted. */
static int replay_ok(const struct eapol_ctx *c, const uint8_t *counter)
{
    if (!c->have_replay)
        return 1;
    for (uint32_t i = 0; i < 8u; ++i) {
        if (counter[i] > c->replay[i]) return 1;
        if (counter[i] < c->replay[i]) return 0;
    }
    return 0;
}

static int mic_ok(const struct eapol_ctx *c, const uint8_t *frame, uint32_t len)
{
    static uint8_t copy_buf[512];
    uint8_t mic[16];
    if (len > sizeof(copy_buf))
        return 0;
    copy(copy_buf, frame, len);
    zero(copy_buf + EAPOL_HDR + 77u, 16);
    wpa_eapol_mic(c->ptk, copy_buf, (int)len, mic);
    return equal(mic, frame + EAPOL_HDR + 77u, 16);
}

/* Build a supplicant EAPOL-Key frame and sign it with the KCK. */
static int build_key(struct eapol_ctx *c, uint8_t *out, uint32_t capacity,
                     uint16_t info, const uint8_t *replay,
                     const uint8_t *nonce, const uint8_t *data,
                     uint32_t data_len)
{
    uint32_t len = EAPOL_HDR + KEY_BODY + data_len;
    if (len > capacity)
        return -1;
    zero(out, len);
    out[0] = 1;                        /* 802.1X-2001 */
    out[1] = 3;                        /* EAPOL-Key */
    put_be16(out + 2, KEY_BODY + data_len);
    uint8_t *k = out + EAPOL_HDR;
    k[0] = 2;                          /* RSN key descriptor */
    put_be16(k + 1, info);
    copy(k + 5, replay, 8);
    if (nonce)
        copy(k + 13, nonce, 32);
    put_be16(k + 93, data_len);
    if (data_len)
        copy(k + 95, data, data_len);
    wpa_eapol_mic(c->ptk, out, (int)len, k + 77);
    return (int)len;
}

/* Find the GTK KDE (dd len 00-0f-ac 01 ...) in decrypted key data. */
static int take_gtk(struct eapol_ctx *c, const uint8_t *d, uint32_t len)
{
    for (uint32_t o = 0; o + 2u <= len;) {
        uint8_t id = d[o], n = d[o + 1u];
        if (id == 0xddu && n == 0 && o + 2u == len)
            break;                     /* padding */
        if (o + 2u + n > len)
            break;
        if (id == 0xddu && n >= 6u + 16u && d[o + 2] == 0x00 &&
            d[o + 3] == 0x0f && d[o + 4] == 0xac && d[o + 5] == 0x01) {
            uint32_t glen = n - 6u;
            if (glen > sizeof(c->gtk))
                return -1;
            c->gtk_index = d[o + 6] & 3u;
            copy(c->gtk, d + o + 8, glen);
            c->gtk_len = (uint8_t)glen;
            return 0;
        }
        o += 2u + n;
    }
    return -1;
}

static int unwrap_key_data(struct eapol_ctx *c, const uint8_t *k,
                           uint8_t *plain, uint32_t capacity)
{
    uint32_t n = be16(k + 93);
    if (n < 24u || (n & 7u) || n - 8u > capacity)
        return -1;
    return wpa_aes_unwrap(c->ptk + 16, k + 95, (int)n, plain);
}

int eapol_input(struct eapol_ctx *c, const uint8_t *frame, uint32_t len,
                uint8_t *out, uint32_t capacity)
{
    static uint8_t plain[256];
    if (len < EAPOL_HDR + KEY_BODY || frame[1] != 3u)
        return -1;
    uint32_t body = be16(frame + 2);
    if (body < KEY_BODY || EAPOL_HDR + body > len)
        return -1;
    len = EAPOL_HDR + body;
    const uint8_t *k = frame + EAPOL_HDR;
    if (k[0] != 2u || be16(k + 93) > body - KEY_BODY)
        return -1;
    uint16_t info = be16(k + 1);
    if ((info & KI_VERSION_MASK) != 2u) {
        t113_uart_puts("eapol: unsupported key descriptor version\n");
        return -1;
    }
    if (!(info & KI_ACK) || !replay_ok(c, k + 5))
        return -1;

    if ((info & KI_PAIRWISE) && !(info & KI_MIC)) {
        /* Message 1: ANonce.  Derive the PTK and answer with message 2. */
        copy(c->anonce, k + 13, 32);
        wpa_make_snonce(c->pmk, c->anonce, t113_time_us(), c->snonce);
        wpa_derive_ptk(c->pmk, c->aa, c->spa, c->anonce, c->snonce, c->ptk);
        c->have_ptk = 1;
        copy(c->replay, k + 5, 8);
        c->have_replay = 1;
        return build_key(c, out, capacity, 2u | KI_PAIRWISE | KI_MIC,
                         k + 5, c->snonce, c->rsn_ie, c->rsn_len);
    }
    if (!c->have_ptk || !(info & KI_MIC) || !mic_ok(c, frame, len)) {
        t113_uart_puts("eapol: MIC check failed (wrong passphrase?)\n");
        return -1;
    }
    copy(c->replay, k + 5, 8);
    c->have_replay = 1;

    if (info & KI_PAIRWISE) {
        /* Message 3: same ANonce, encrypted GTK, install the PTK. */
        if (!equal(k + 13, c->anonce, 32) || !(info & KI_INSTALL) ||
            !(info & KI_ENCRYPTED))
            return -1;
        int n = unwrap_key_data(c, k, plain, sizeof(plain));
        if (n < 0 || take_gtk(c, plain, (uint32_t)n) < 0) {
            t113_uart_puts("eapol: no GTK in message 3\n");
            return -1;
        }
        copy(c->gtk_rsc, k + 61, 8);
        c->ready |= EAPOL_PTK_READY | EAPOL_GTK_READY;
        c->done = 1;
        return build_key(c, out, capacity,
                         2u | KI_PAIRWISE | KI_MIC | KI_SECURE,
                         k + 5, 0, 0, 0);
    }
    /* Group key handshake message 1 (GTK rekey). */
    if (!(info & KI_ENCRYPTED))
        return -1;
    int n = unwrap_key_data(c, k, plain, sizeof(plain));
    if (n < 0 || take_gtk(c, plain, (uint32_t)n) < 0)
        return -1;
    copy(c->gtk_rsc, k + 61, 8);
    c->ready |= EAPOL_GTK_READY;
    return build_key(c, out, capacity, 2u | KI_MIC | KI_SECURE,
                     k + 5, 0, 0, 0);
}
