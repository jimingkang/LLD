#ifndef MINIOS_NET_EAPOL_H
#define MINIOS_NET_EAPOL_H

#include <stdint.h>

/*
 * WPA2-PSK supplicant key handshake (IEEE 802.11i 4-way and group key
 * handshakes, key descriptor version 2: HMAC-SHA1 MIC, AES key wrap).
 * Frames are 802.1X EAPOL frames without any 802.11 or LLC header.
 */

#define EAPOL_PTK_READY  1u      /* tk/tk_len valid: install pairwise key */
#define EAPOL_GTK_READY  2u      /* gtk valid: install group key */

struct eapol_ctx {
    uint8_t pmk[32];
    uint8_t aa[6];               /* authenticator (BSSID) */
    uint8_t spa[6];              /* our address */
    uint8_t rsn_ie[64];          /* exactly as sent in the association */
    uint8_t rsn_len;
    uint8_t anonce[32];
    uint8_t snonce[32];
    uint8_t ptk[64];             /* KCK | KEK | TK */
    uint8_t replay[8];
    uint8_t have_replay;
    uint8_t have_ptk;
    uint8_t group_cipher;        /* RSN suite type: 2 TKIP, 4 CCMP */
    uint8_t gtk[32];
    uint8_t gtk_len;
    uint8_t gtk_index;
    uint8_t gtk_rsc[8];
    uint32_t ready;              /* EAPOL_*_READY flags, cleared by caller */
    uint32_t done;               /* 4-way handshake completed */
};

void eapol_init(struct eapol_ctx *c, const uint8_t pmk[32],
                const uint8_t aa[6], const uint8_t spa[6],
                const uint8_t *rsn_ie, uint32_t rsn_len,
                uint8_t group_cipher);

/*
 * Consume one received EAPOL frame.  Returns the length of the reply
 * written to out (send it, then look at c->ready), 0 when nothing is to be
 * sent, or <0 when the frame is rejected.
 */
int eapol_input(struct eapol_ctx *c, const uint8_t *frame, uint32_t len,
                uint8_t *out, uint32_t capacity);

/* Temporal key for the pairwise CCMP key (16 bytes). */
static inline const uint8_t *eapol_tk(const struct eapol_ctx *c)
{
    return c->ptk + 32;
}

#endif
