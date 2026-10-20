#ifndef MINIOS_CRYPTO_WPA_CRYPTO_H
#define MINIOS_CRYPTO_WPA_CRYPTO_H

#include <stdint.h>

/*
 * WPA2-PSK host crypto (ported from xv6-aarch64 kernel/wpa_crypto.c):
 * SHA-1, HMAC-SHA1, PBKDF2 (PSK -> PMK), 802.11i PRF-512 (PTK),
 * EAPOL-Key MIC (HMAC-SHA1-128, key descriptor version 2) and
 * RFC 3394 AES key unwrap for the GTK in EAPOL M3.
 * CCMP itself runs in the XR829 firmware.
 */

void wpa_hmac_sha1(const uint8_t *key, int keylen, const void *a, int alen,
                   const void *b, int blen, uint8_t out[20]);
void wpa_pbkdf2(const char *passphrase, const char *ssid, uint8_t pmk[32]);
void wpa_make_snonce(const uint8_t pmk[32], const uint8_t anonce[32],
                     uint64_t seed, uint8_t snonce[32]);
void wpa_derive_ptk(const uint8_t pmk[32], const uint8_t aa[6],
                    const uint8_t spa[6], const uint8_t anonce[32],
                    const uint8_t snonce[32], uint8_t ptk[64]);
void wpa_eapol_mic(const uint8_t kck[16], const void *eapol, int length,
                   uint8_t mic[16]);
/* Returns plaintext length, or -1 (bad length / integrity check). */
int wpa_aes_unwrap(const uint8_t kek[16], const uint8_t *cipher,
                   int cipher_len, uint8_t *plain);

#endif
