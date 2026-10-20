#ifndef MINIOS_XRADIO_WSM_H
#define MINIOS_XRADIO_WSM_H

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
 * The transport (queue reads/writes, sequence numbers, buffer
 * accounting) is in bh.c; this file builds requests and decodes
 * confirms and indications.  Everything is polled; there is no SDIO
 * interrupt yet.
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
#define WSM_JOIN_REQ            0x000bu
#define WSM_SET_EDCA_REQ        0x0013u
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

/* EVENT indication ids */
#define WSM_EVENT_BSS_LOST      1u
#define WSM_EVENT_BSS_REGAINED  2u

/* MIB ids used here */
#define WSM_MIB_DOT11_CURRENT_TX_POWER  0x0006u
#define WSM_MIB_DOT11_SLOT_TIME         0x0003u
#define WSM_MIB_TEMPLATE_FRAME          0x1002u
#define WSM_MIB_RX_FILTER               0x1003u
#define WSM_MIB_BEACON_FILTER_TABLE     0x1004u
#define WSM_MIB_BEACON_FILTER_ENABLE    0x1005u
#define WSM_MIB_OPERATIONAL_POWER_MODE  0x1006u
#define WSM_MIB_BEACON_WAKEUP_PERIOD    0x1007u
#define WSM_MIB_BLOCK_ACK_POLICY        0x100eu
#define WSM_MIB_SET_ASSOCIATION_MODE    0x1010u
#define WSM_MIB_SET_TX_RATE_RETRY_POLICY 0x1016u
#define WSM_MIB_PROTECTED_MGMT_POLICY   0x1020u
#define WSM_MIB_SET_HT_PROTECTION       0x1021u
#define WSM_MIB_KEEP_ALIVE_PERIOD       0x1025u
#define WSM_MIB_DISABLE_BSSID_FILTER    0x1026u

/* WSM_MIB_BEACON_FILTER_ENABLE flags for SUPPORT_HT40 firmware. */
#define WSM_BEACON_FILTER_ENABLE        (1u << 0)
#define WSM_BEACON_FILTER_AUTO_ERP      (1u << 1)
#define WSM_BEACON_FILTER_AUTO_HT       (1u << 2)

/* WSM queue ids (wsm_queue_id_to_linux in the xradio driver). */
#define WSM_QUEUE_BEST_EFFORT   0u
#define WSM_QUEUE_BACKGROUND    1u
#define WSM_QUEUE_VIDEO         2u
#define WSM_QUEUE_VOICE         3u

/* RX indication payload (after the 4-byte WSM header), SUPPORT_HT40:
 * status:u32 @0, channel:u16 @4, rxedRateEntry:u16 @6, reserved[3] @8,
 * rcpiRssi:u8 @11, flags:u32 @12, then the 802.11 frame @16.  AES frames
 * arrive decrypted but keep the 8-byte CCMP header and 8-byte MIC. */
#define WSM_RX_HDR_LEN          16u
#define WSM_RX_RCPI_OFFSET      11u
#define WSM_RX_FLAGS_OFFSET     12u
#define WSM_RX_STATUS_ENCRYPTION(f) ((f) & 7u)
#define WSM_RX_ENC_NONE         0u
#define WSM_RX_ENC_TKIP         2u
#define WSM_RX_ENC_AES          3u

/* TX rate retry policies installed by wsm_set_tx_policies(). */
#define WSM_POLICY_MGMT         0u      /* 1 Mbps, 15 tries */
#define WSM_POLICY_DATA         1u      /* 24 / 11 / 1 Mbps fallback */
#define WSM_RATE_MGMT           0x000fu /* first rate entry of each */
#define WSM_RATE_DATA           0x00a4u

/* ADD_KEY types */
#define WSM_KEY_TYPE_TKIP_GROUP     2u
#define WSM_KEY_TYPE_AES_GROUP      4u
#define WSM_KEY_TYPE_AES_PAIRWISE   5u

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
    uint16_t phy_mode;          /* PhyModeCfg: 0x0007 = 2.4 GHz b/g/n, 20 MHz */
    uint16_t channel;
    uint8_t bssid[6];
    const uint8_t *ssid;
    uint8_t ssid_len;
    uint8_t dtim_period;
    uint32_t beacon_interval;
    uint32_t basic_rates;       /* BIT(hw rate index) */
};

/* After firmware download: wait for the startup indication (consumes it). */
int wsm_init(struct sdio_func *func, int timeout_ms);
const struct wsm_caps *wsm_get_caps(void);
int wsm_ready(void);

/* One message from the bottom half: confirms complete the pending
 * request or a TX; indications go to scan.c / sta.c / txrx.c. */
void wsm_handle_rx(const uint8_t *msg, uint32_t len);

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
int wsm_set_edca_default(void);
int wsm_set_tx_policies(void);
int wsm_mib32(uint16_t mib_id, uint32_t value);
int wsm_set_bss_params(uint16_t aid, uint8_t beacon_lost_count,
                       uint32_t operational_rates);
int wsm_set_beacon_wakeup_period(uint8_t beacon_periods,
                                 uint16_t listen_interval);
int wsm_set_beacon_filter(int enabled, uint32_t beacon_count);
/* SET_PM, then wait for the firmware's SET_PM indication. */
int wsm_set_pm(uint8_t mode);
int wsm_add_key_pairwise(uint8_t index, const uint8_t peer[6],
                         const uint8_t tk[16]);
int wsm_add_key_group(uint8_t type, uint8_t index, const uint8_t *gtk,
                      uint8_t key_id, const uint8_t rsc[8]);
int wsm_remove_key(uint8_t index);

/*
 * Queue an 802.11 frame (the 24-byte wsm_tx header is built here) with
 * the caller's packet id; its TX confirm (0x0404) is reported through
 * xradio_tx_confirm_cb().  Returns 0 or <0.
 */
int wsm_tx_frame(uint32_t packet_id, const uint8_t *frame, uint32_t len,
                 uint8_t queue, uint8_t policy, uint16_t rate_entry,
                 uint8_t epta_prio);

#endif
