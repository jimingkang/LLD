#ifndef MINIOS_XRADIO_XRADIO_H
#define MINIOS_XRADIO_XRADIO_H

/*
 * XRadio XR829 driver private state, after the xradio driver's xradio.h.
 * The driver is a mac80211 driver; its files follow the Linux driver:
 *
 *   sdio.c   SDIO function driver: probe, CMD53 check, bus clock
 *   hwio.c   HIF registers and indirect device memory access
 *   fwio.c   bootloader + firmware download, SDD (DPLL) handling
 *   bh.c     bottom half: message transport over the HIF queue
 *   wsm.c    WSM commands, confirms and indications
 *   main.c   core probe: firmware, WSM start, register with mac80211
 *   sta.c    ieee80211_ops: start, join/assoc settings, keys, poll
 *   scan.c   hardware scan
 *   txrx.c   802.11 frames to/from WSM, TX confirms
 *
 * One device; everything is polled (no SDIO interrupt yet).
 */
#include <stdint.h>
#include "net/mac80211.h"
#include "hwio.h"
#include "wsm.h"

struct sdio_func;

struct xradio_common {
    struct sdio_func *func;
    struct ieee80211_hw *hw;
    uint8_t mac_addr[ETH_ALEN];
    uint32_t hif_config;         /* CONFIG at probe (self test) */
    const void *sdd;             /* SDD image, kept for CONFIGURATION */
    uint32_t sdd_len;
};

extern struct xradio_common xradio_priv;

/* fwio.c */
int xradio_load_firmware(struct xradio_common *hw_priv);

/* bh.c */
void xradio_bh_init(struct sdio_func *func);
/* Firmware input buffers, from the startup indication. */
void xradio_bh_set_caps(uint32_t num_bufs, uint32_t buf_size);
/* Firmware exception: stop moving messages. */
void xradio_bh_halt(void);
int xradio_bh_halted(void);
/* Write one WSM message (header included, room for padding up to the
 * SDIO transfer size) to the device queue; waits for a free buffer. */
int xradio_bh_tx(uint8_t *msg, uint32_t len, uint32_t cap);
/* Read and dispatch pending messages to wsm_handle_rx(); waits up to
 * timeout_ms for the first one.  Returns the number handled or <0. */
int xradio_bh_poll(int timeout_ms);
/* Print CONTROL when the firmware never talked (bring-up diagnostic). */
void xradio_bh_diag(void);

/* main.c */
int xradio_core_probe(struct sdio_func *func);

/* sta.c */
extern const struct ieee80211_ops xradio_ops;
void xradio_event_cb(uint32_t event_id, uint32_t event_data);

/* scan.c */
int xradio_hw_scan(struct ieee80211_hw *hw, struct cfg80211_scan_request *req);
void xradio_scan_complete_cb(const uint8_t *msg, uint32_t len);

/* txrx.c */
int xradio_tx(struct ieee80211_hw *hw, struct sk_buff *skb);
void xradio_rx_cb(const uint8_t *msg, uint32_t len);
void xradio_tx_confirm_cb(uint32_t packet_id, uint32_t status);

#endif
