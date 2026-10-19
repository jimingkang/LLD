#ifndef MINIOS_NET_XRADIO_WSM_H
#define MINIOS_NET_XRADIO_WSM_H

#include <stdint.h>

/*
 * XR829 WSM (wireless station management) host interface, after the
 * Allwinner xradio driver (wsm.c/bh.c, SUPPORT_HT40 layout).
 *
 * Every message starts with {u16 len, u16 id}; id bits 15:13 carry a
 * 3-bit sequence number (separate counters for each direction), bits
 * 9:6 the interface / link id. Requests are 0x00xx, confirms 0x04xx,
 * indications 0x08xx. Each request (commands and the 0x0004 TX) takes
 * one of the firmware's input buffers; every confirm frees one.
 *
 * Transport (hwio.c): write to IN_OUT_QUEUE with buf_id = tx id (0..31),
 * read with buf_id = rx id + 1 (rx id 0..3). CONTROL.NEXT_LEN gives the
 * next message length in 16-bit words; each read returns 2 extra bytes:
 * the next CONTROL value (piggyback).
 *
 * Everything is polled; there is no SDIO interrupt yet.
 */

struct sdio_func;

#define WSM_HDR_LEN         4u
#define WSM_MSG_ID(id)      ((id) & 0x0c3fu)      /* strip seq + link id */
#define WSM_LINK_ID(id)     (((id) >> 6) & 0x0fu)

/* Requests */
#define WSM_TX_REQ              0x0004u
#define WSM_READ_MIB_REQ        0x0005u
#define WSM_WRITE_MIB_REQ       0x0006u
#define WSM_START_SCAN_REQ      0x0007u
#define WSM_STOP_SCAN_REQ       0x0008u
#define WSM_CONFIGURATION_REQ   0x0009u
#define WSM_RESET_REQ           0x000au
#define WSM_JOIN_REQ            0x0013u       /* XR829 extended JOIN */
#define WSM_ADD_KEY_REQ         0x000cu
#define WSM_REMOVE_KEY_REQ      0x000du
#define WSM_SET_PM_REQ          0x0010u
#define WSM_SET_BSS_PARAMS_REQ  0x0011u
/* Indications */
#define WSM_EXCEPTION_IND       0x0800u
#define WSM_STARTUP_IND         0x0801u
#define WSM_RX_IND              0x0804u
#define WSM_EVENT_IND           0x0805u
#define WSM_SCAN_COMPLETE_IND   0x0806u
#define WSM_SET_PM_IND          0x0809u

/* MIB ids used here */
#define WSM_MIB_DOT11_CURRENT_TX_POWER  0x0006u
#define WSM_MIB_OPERATIONAL_POWER_MODE  0x1006u
#define WSM_MIB_TEMPLATE_FRAME          0x1002u
#define WSM_MIB_BLOCK_ACK_POLICY        0x100eu
#define WSM_MIB_SET_ASSOCIATION_MODE    0x1010u
#define WSM_MIB_SET_TX_RATE_RETRY_POLICY 0x1016u
#define WSM_MIB_PROTECTED_MGMT_POLICY   0x1020u
#define WSM_MIB_KEEP_ALIVE_PERIOD       0x1025u

#define WSM_QUEUE_BEST_EFFORT   0u
#define WSM_QUEUE_VOICE         3u

/* RX indication payload (after the 4-byte WSM header).
 * XR_C09...2GHZ HT40 adds a u32 HT-RX parameter after the standard fields:
 * status:u32, channel:u16, rate:u8, rcpi:u8, flags:u32, ht_rx:u32. */
#define WSM_RX_HDR_LEN          16u
#define WSM_RX_STATUS_ENCRYPTION(f) ((f) & 7u)
#define WSM_RX_ENC_AES          3u

struct wsm_caps {
    uint16_t num_bufs;          /* numInpChBufs */
    uint16_t buf_size;          /* sizeInpChBuf */
    uint16_t hw_id, hw_subid, fw_cap, fw_type, fw_api, fw_build, fw_version;
    char label[64];
};

struct wsm_configuration {
    uint8_t station_id[6];
    uint8_t bands;
    uint32_t rate_mask;
};

struct wsm_scan_channel {
    uint16_t number;
    uint32_t min_time_ms;
    uint32_t max_time_ms;
};

struct wsm_join {
    uint8_t band;
    uint16_t channel;
    uint8_t bssid[6];
    const uint8_t *ssid;
    uint8_t ssid_len;
    uint8_t dtim_period;
    uint32_t beacon_interval;
};

/* Indication / unsolicited message handler (RX frames, scan complete...). */
typedef void (*wsm_ind_handler)(uint16_t id, const uint8_t *msg, uint32_t len);

/* After firmware download: wait for the startup indication (consumes it). */
int wsm_init(struct sdio_func *func, int timeout_ms);
const struct wsm_caps *wsm_get_caps(void);
int wsm_ready(void);
void wsm_set_ind_handler(wsm_ind_handler h);

/*
 * Send a request and wait for its confirm (dispatching indications that
 * arrive meanwhile). The confirm payload (after the header, starting with
 * the u32 status) is copied to cfm (up to cfm_cap bytes). Returns the
 * WSM status (0 = success), or <0 on transport error / timeout.
 */
int wsm_cmd(uint16_t req, const void *payload, uint32_t len,
            void *cfm, uint32_t cfm_cap, int timeout_ms);
int wsm_read_mib(uint16_t mib_id, void *data, uint32_t *len);
int wsm_write_mib(uint16_t mib_id, const void *data, uint32_t len);
int wsm_configuration(const uint8_t station_id[6], const void *dpd,
                      uint32_t dpd_len, struct wsm_configuration *result);
int wsm_set_probe_request_template(const uint8_t station_id[6]);
int wsm_scan(const struct wsm_scan_channel *channels, uint8_t num_channels,
             const uint8_t *ssid, uint8_t ssid_len);
int wsm_join(const struct wsm_join *join);

/*
 * Queue an 802.11 frame (the 24-byte wsm_tx header is built here).
 * Returns the packet id (>0) or <0. The TX confirm (0x0404) is handled
 * internally; wsm_tx_status(id) returns its status once it arrived, or
 * -1 while pending.
 */
int wsm_tx_frame(const uint8_t *frame, uint32_t len, uint8_t queue,
                 uint8_t policy, uint16_t rate_entry, uint8_t epta_prio);
int wsm_tx_status(int packet_id);

/* Read and dispatch everything currently pending; waits up to timeout_ms
 * for the first message. Returns number of messages handled or <0. */
int wsm_poll(int timeout_ms);

/* Monotonic microseconds (CNTPCT). */
uint64_t t113_time_us(void);

#endif
