/*
 * WPA2-PSK host crypto, ported from xv6-aarch64 kernel/wpa_crypto.c.
 * Freestanding: no libc, so byte helpers are local. PBKDF2 caches the
 * HMAC ipad/opad SHA-1 states (4096 iterations x 2 blocks on a
 * Cortex-A7 takes about a second); AES tables are built once.
 */
#include "crypto/wpa_crypto.h"

struct sha1_ctx {
    uint32_t h[5];
    uint64_t bytes;
    uint8_t block[64];
    int used;
};

static void bcopy_(void *d, const void *s, int n)
{
    uint8_t *dp = d;
    const uint8_t *sp = s;
    while (n-- > 0)
        *dp++ = *sp++;
}

static void bfill(void *d, uint8_t v, int n)
{
    uint8_t *dp = d;
    while (n-- > 0)
        *dp++ = v;
}

static int slen(const char *s)
{
    int n = 0;
    while (s[n])
        ++n;
    return n;
}

static uint32_t rol(uint32_t x, int n)
{
    return (x << n) | (x >> (32 - n));
}

static void sha1_transform(struct sha1_ctx *ctx, const uint8_t *p)
{
    uint32_t w[80], a, b, c, d, e, f, k, t;
    for (int i = 0; i < 16; i++)
        w[i] = ((uint32_t)p[i * 4] << 24) | ((uint32_t)p[i * 4 + 1] << 16) |
               ((uint32_t)p[i * 4 + 2] << 8) | p[i * 4 + 3];
    for (int i = 16; i < 80; i++)
        w[i] = rol(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
    a = ctx->h[0]; b = ctx->h[1]; c = ctx->h[2]; d = ctx->h[3]; e = ctx->h[4];
    for (int i = 0; i < 80; i++) {
        if (i < 20) { f = (b & c) | ((~b) & d); k = 0x5a827999u; }
        else if (i < 40) { f = b ^ c ^ d; k = 0x6ed9eba1u; }
        else if (i < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8f1bbcdcu; }
        else { f = b ^ c ^ d; k = 0xca62c1d6u; }
        t = rol(a, 5) + f + e + k + w[i];
        e = d; d = c; c = rol(b, 30); b = a; a = t;
    }
    ctx->h[0] += a; ctx->h[1] += b; ctx->h[2] += c; ctx->h[3] += d; ctx->h[4] += e;
}

static void sha1_init(struct sha1_ctx *ctx)
{
    ctx->h[0] = 0x67452301u; ctx->h[1] = 0xefcdab89u; ctx->h[2] = 0x98badcfeu;
    ctx->h[3] = 0x10325476u; ctx->h[4] = 0xc3d2e1f0u;
    ctx->bytes = 0;
    ctx->used = 0;
}

static void sha1_update(struct sha1_ctx *ctx, const void *data, int length)
{
    const uint8_t *p = data;
    ctx->bytes += (uint64_t)length;
    while (length > 0) {
        int n = 64 - ctx->used;
        if (n > length)
            n = length;
        bcopy_(ctx->block + ctx->used, p, n);
        ctx->used += n;
        p += n;
        length -= n;
        if (ctx->used == 64) {
            sha1_transform(ctx, ctx->block);
            ctx->used = 0;
        }
    }
}

static void sha1_final(struct sha1_ctx *ctx, uint8_t out[20])
{
    uint64_t bits = ctx->bytes * 8u;
    uint8_t pad[72];
    int n;
    bfill(pad, 0, sizeof(pad));
    pad[0] = 0x80;
    n = ctx->used < 56 ? 56 - ctx->used : 120 - ctx->used;
    sha1_update(ctx, pad, n);
    for (int i = 0; i < 8; i++)
        pad[i] = (uint8_t)(bits >> (56 - i * 8));
    sha1_update(ctx, pad, 8);
    for (int i = 0; i < 5; i++) {
        out[i * 4] = (uint8_t)(ctx->h[i] >> 24);
        out[i * 4 + 1] = (uint8_t)(ctx->h[i] >> 16);
        out[i * 4 + 2] = (uint8_t)(ctx->h[i] >> 8);
        out[i * 4 + 3] = (uint8_t)ctx->h[i];
    }
}

/* HMAC with the two keyed SHA-1 prefixes precomputed. */
struct hmac_key {
    struct sha1_ctx inner, outer;
};

static void hmac_setkey(struct hmac_key *hk, const uint8_t *key, int keylen)
{
    uint8_t ipad[64], opad[64], kd[20];
    if (keylen > 64) {
        struct sha1_ctx c;
        sha1_init(&c);
        sha1_update(&c, key, keylen);
        sha1_final(&c, kd);
        key = kd;
        keylen = 20;
    }
    bfill(ipad, 0x36, 64);
    bfill(opad, 0x5c, 64);
    for (int i = 0; i < keylen; i++) {
        ipad[i] ^= key[i];
        opad[i] ^= key[i];
    }
    sha1_init(&hk->inner);
    sha1_update(&hk->inner, ipad, 64);
    sha1_init(&hk->outer);
    sha1_update(&hk->outer, opad, 64);
}

/* Explicit copy: a struct assignment could turn into a memcpy call. */
static void sha1_copy(struct sha1_ctx *d, const struct sha1_ctx *s)
{
    for (int i = 0; i < 5; i++)
        d->h[i] = s->h[i];
    d->bytes = s->bytes;
    d->used = s->used;
    bcopy_(d->block, s->block, s->used);
}

static void hmac_run(const struct hmac_key *hk, const void *a, int alen,
                     const void *b, int blen, const void *c, int clen,
                     uint8_t out[20])
{
    struct sha1_ctx ctx;
    sha1_copy(&ctx, &hk->inner);
    uint8_t inner[20];
    sha1_update(&ctx, a, alen);
    if (b && blen)
        sha1_update(&ctx, b, blen);
    if (c && clen)
        sha1_update(&ctx, c, clen);
    sha1_final(&ctx, inner);
    sha1_copy(&ctx, &hk->outer);
    sha1_update(&ctx, inner, 20);
    sha1_final(&ctx, out);
}

void wpa_hmac_sha1(const uint8_t *key, int keylen, const void *a, int alen,
                   const void *b, int blen, uint8_t out[20])
{
    struct hmac_key hk;
    hmac_setkey(&hk, key, keylen);
    hmac_run(&hk, a, alen, b, blen, 0, 0, out);
}

void wpa_pbkdf2(const char *passphrase, const char *ssid, uint8_t pmk[32])
{
    struct hmac_key hk;
    uint8_t u[20], digest[20], counter[4];
    int done = 0;

    hmac_setkey(&hk, (const uint8_t *)passphrase, slen(passphrase));
    for (uint32_t block = 1; done < 32; block++) {
        counter[0] = (uint8_t)(block >> 24); counter[1] = (uint8_t)(block >> 16);
        counter[2] = (uint8_t)(block >> 8);  counter[3] = (uint8_t)block;
        hmac_run(&hk, ssid, slen(ssid), counter, 4, 0, 0, u);
        bcopy_(digest, u, 20);
        for (int it = 1; it < 4096; it++) {
            hmac_run(&hk, u, 20, 0, 0, 0, 0, u);
            for (int i = 0; i < 20; i++)
                digest[i] ^= u[i];
        }
        int n = 32 - done;
        if (n > 20)
            n = 20;
        bcopy_(pmk + done, digest, n);
        done += n;
    }
}

static int bytes_less(const uint8_t *a, const uint8_t *b, int n)
{
    for (int i = 0; i < n; i++) {
        if (a[i] < b[i]) return 1;
        if (a[i] > b[i]) return 0;
    }
    return 0;
}

void wpa_make_snonce(const uint8_t pmk[32], const uint8_t anonce[32],
                     uint64_t seed, uint8_t snonce[32])
{
    uint8_t material[40], digest[20];
    bcopy_(material, anonce, 32);
    for (int i = 0; i < 8; i++)
        material[32 + i] = (uint8_t)(seed >> (i * 8));
    wpa_hmac_sha1(pmk, 32, material, sizeof(material), 0, 0, digest);
    bcopy_(snonce, digest, 20);
    material[39] ^= 0xa5;
    wpa_hmac_sha1(pmk, 32, material, sizeof(material), 0, 0, digest);
    bcopy_(snonce + 20, digest, 12);
}

void wpa_derive_ptk(const uint8_t pmk[32], const uint8_t aa[6],
                    const uint8_t spa[6], const uint8_t anonce[32],
                    const uint8_t snonce[32], uint8_t ptk[64])
{
    static const char label[] = "Pairwise key expansion";   /* + NUL */
    struct hmac_key hk;
    uint8_t data[76], digest[20], counter;
    const uint8_t *mac1 = bytes_less(aa, spa, 6) ? aa : spa;
    const uint8_t *mac2 = mac1 == aa ? spa : aa;
    const uint8_t *n1 = bytes_less(anonce, snonce, 32) ? anonce : snonce;
    const uint8_t *n2 = n1 == anonce ? snonce : anonce;
    int done = 0;

    bcopy_(data, mac1, 6);
    bcopy_(data + 6, mac2, 6);
    bcopy_(data + 12, n1, 32);
    bcopy_(data + 44, n2, 32);
    hmac_setkey(&hk, pmk, 32);
    for (counter = 0; done < 64; counter++) {
        /* PRF-512: HMAC(PMK, label || 0 || data || counter) */
        hmac_run(&hk, label, sizeof(label), data, sizeof(data), &counter, 1,
                 digest);
        int n = 64 - done;
        if (n > 20)
            n = 20;
        bcopy_(ptk + done, digest, n);
        done += n;
    }
}

void wpa_eapol_mic(const uint8_t kck[16], const void *eapol, int length,
                   uint8_t mic[16])
{
    uint8_t digest[20];
    wpa_hmac_sha1(kck, 16, eapol, length, 0, 0, digest);
    bcopy_(mic, digest, 16);
}

/* ------------------------------------------------------------ AES-128 */

static uint8_t aes_inv_sbox[256], aes_sbox_tab[256];
static int aes_tables_ready;

static uint8_t aes_xtime(uint8_t x)
{
    return (uint8_t)((x << 1) ^ ((x & 0x80) ? 0x1b : 0));
}

static uint8_t aes_mul(uint8_t a, uint8_t b)
{
    uint8_t r = 0;
    while (b) {
        if (b & 1)
            r ^= a;
        a = aes_xtime(a);
        b >>= 1;
    }
    return r;
}

static uint8_t aes_sbox_calc(uint8_t x)
{
    uint8_t y = 1, p = x, inv, r;
    if (x == 0) {
        inv = 0;
    } else {
        for (int e = 254; e; e >>= 1) {         /* x^254 = x^-1 in GF(2^8) */
            if (e & 1)
                y = aes_mul(y, p);
            p = aes_mul(p, p);
        }
        inv = y;
    }
    r = inv;
    for (int i = 1; i <= 4; i++)
        r ^= (uint8_t)((inv << i) | (inv >> (8 - i)));
    return r ^ 0x63;
}

static void aes_tables(void)
{
    if (aes_tables_ready)
        return;
    for (int i = 0; i < 256; i++) {
        aes_sbox_tab[i] = aes_sbox_calc((uint8_t)i);
        aes_inv_sbox[aes_sbox_tab[i]] = (uint8_t)i;
    }
    aes_tables_ready = 1;
}

static void aes128_expand(const uint8_t *key, uint8_t *round)
{
    uint8_t t[4], rcon = 1;
    bcopy_(round, key, 16);
    for (int bytes = 16; bytes < 176;) {
        bcopy_(t, round + bytes - 4, 4);
        if ((bytes & 15) == 0) {
            uint8_t q = t[0];
            t[0] = aes_sbox_tab[t[1]] ^ rcon;
            t[1] = aes_sbox_tab[t[2]];
            t[2] = aes_sbox_tab[t[3]];
            t[3] = aes_sbox_tab[q];
            rcon = aes_xtime(rcon);
        }
        for (int i = 0; i < 4; i++, bytes++)
            round[bytes] = round[bytes - 16] ^ t[i];
    }
}

static void aes128_decrypt(const uint8_t *round, const uint8_t in[16],
                           uint8_t out[16])
{
    uint8_t s[16], t[16];
    for (int i = 0; i < 16; i++)
        s[i] = in[i] ^ round[160 + i];
    for (int rnd = 9; rnd >= 0; rnd--) {
        /* InvShiftRows + InvSubBytes + AddRoundKey */
        t[0] = s[0];   t[1] = s[13];  t[2] = s[10];  t[3] = s[7];
        t[4] = s[4];   t[5] = s[1];   t[6] = s[14];  t[7] = s[11];
        t[8] = s[8];   t[9] = s[5];   t[10] = s[2];  t[11] = s[15];
        t[12] = s[12]; t[13] = s[9];  t[14] = s[6];  t[15] = s[3];
        for (int i = 0; i < 16; i++)
            s[i] = aes_inv_sbox[t[i]] ^ round[rnd * 16 + i];
        if (rnd != 0) {
            for (int c = 0; c < 4; c++) {
                uint8_t *a = s + c * 4;
                t[c * 4]     = aes_mul(a[0], 14) ^ aes_mul(a[1], 11) ^ aes_mul(a[2], 13) ^ aes_mul(a[3], 9);
                t[c * 4 + 1] = aes_mul(a[0], 9) ^ aes_mul(a[1], 14) ^ aes_mul(a[2], 11) ^ aes_mul(a[3], 13);
                t[c * 4 + 2] = aes_mul(a[0], 13) ^ aes_mul(a[1], 9) ^ aes_mul(a[2], 14) ^ aes_mul(a[3], 11);
                t[c * 4 + 3] = aes_mul(a[0], 11) ^ aes_mul(a[1], 13) ^ aes_mul(a[2], 9) ^ aes_mul(a[3], 14);
            }
            bcopy_(s, t, 16);
        }
    }
    bcopy_(out, s, 16);
}

/* RFC 3394: input A || R[1..n], output R[1..n]; returns n*8 or -1. */
int wpa_aes_unwrap(const uint8_t kek[16], const uint8_t *cipher,
                   int cipher_len, uint8_t *plain)
{
    uint8_t a[8], block[16], dec[16], round[176];
    int n;
    if (cipher_len < 24 || (cipher_len & 7))
        return -1;
    aes_tables();
    aes128_expand(kek, round);
    n = cipher_len / 8 - 1;
    bcopy_(a, cipher, 8);
    bcopy_(plain, cipher + 8, n * 8);
    for (int j = 5; j >= 0; j--) {
        for (int i = n; i >= 1; i--) {
            uint64_t v = (uint64_t)(n * j + i);
            bcopy_(block, a, 8);
            for (int k = 0; k < 8; k++)
                block[7 - k] ^= (uint8_t)(v >> (k * 8));
            bcopy_(block + 8, plain + (i - 1) * 8, 8);
            aes128_decrypt(round, block, dec);
            bcopy_(a, dec, 8);
            bcopy_(plain + (i - 1) * 8, dec + 8, 8);
        }
    }
    for (int i = 0; i < 8; i++)
        if (a[i] != 0xa6)
            return -1;
    return n * 8;
}
