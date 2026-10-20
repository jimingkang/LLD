/*
 * XRadio station operations, after the xradio driver's sta.c: the
 * ieee80211_ops that mac80211 calls to start the MAC, join and
 * associate, program keys and poll the device.
 *
 * The firmware joins the BSS, retries frames and does CCMP/TKIP itself;
 * frames and the 802.11 state machine live in mac80211.
 */
#include "platform.h"
#include "device.h"
#include "net/netutil.h"
#include "xradio.h"

#define KEY_INDEX_PAIRWISE 0u
#define KEY_INDEX_GROUP    1u

static void say(const char *s)
{
    t113_uart_puts("xradio: ");
    t113_uart_puts(s);
}

static void say_hex(const char *s, uint32_t v)
{
    say(s);
    t113_uart_puthex(v);
    t113_uart_putc('\n');
}

/* One-time MAC setup (main.c / vif_setup in the vendor driver). */
static int xradio_start(struct ieee80211_hw *hw)
{
    int ret = wsm_mib32(WSM_MIB_OPERATIONAL_POWER_MODE, 0x12);
    if (!ret)
        ret = wsm_set_probe_request_template(hw->wiphy->perm_addr);
    if (!ret)
        ret = wsm_set_edca_default();
    if (!ret)
        ret = wsm_set_tx_policies();
    if (ret)
        say_hex("initial firmware setup failed, status ", (uint32_t)ret);
    else
        say("probe-request template installed\n");
    if (ret)
        return ret < 0 ? ret : -EIO;
    return 0;
}

/* xradio_join_work: pre-join MIBs, JOIN, then update_filtering. */
static int xradio_do_join(struct ieee80211_bss_conf *conf)
{
    wsm_mib32(WSM_MIB_OPERATIONAL_POWER_MODE, 0x12);
    wsm_mib32(WSM_MIB_BLOCK_ACK_POLICY, 0);
    wsm_mib32(WSM_MIB_PROTECTED_MGMT_POLICY, 0x06);

    struct wsm_join join;
    join.phy_mode = 0x0007;             /* 2.4 GHz b/g/n, 20 MHz, long preamble */
    join.channel = conf->channel;
    join.ssid = conf->ssid;
    join.ssid_len = conf->ssid_len;
    join.dtim_period = conf->dtim_period;
    join.beacon_interval = conf->beacon_int;
    /* Vendor join_work uses 1/2/5.5 Mbps for a 2.4 GHz JOIN.  The complete
     * AP basic-rate mask is installed after association. */
    join.basic_rates = 0x00000007u;
    net_memcpy(join.bssid, conf->bssid, ETH_ALEN);
    int ret = wsm_join(&join);
    if (ret)
        return ret;

    /*
     * The vendor driver temporarily disables beacon filtering while JOIN is
     * settling, then enables its automatic ERP/HT filter after association.
     * Keeping it disabled forever can fill the polled host RX path with every
     * beacon.  Upload the table here, but do not enable it yet.
     */
    static const uint8_t beacon_table[20] = {
        0x02, 0x00, 0x00, 0x00,
        0xdd, 0x07, 0x50, 0x6f, 0x9a, 0x00, 0x00, 0x00,
        0x3d, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };
    if ((ret = wsm_mib32(WSM_MIB_RX_FILTER, 0)) != 0 ||
        (ret = wsm_write_mib(WSM_MIB_BEACON_FILTER_TABLE, beacon_table,
                             sizeof(beacon_table))) != 0 ||
        (ret = wsm_set_beacon_filter(0, 1)) != 0 ||
        (ret = wsm_mib32(WSM_MIB_DISABLE_BSSID_FILTER, 0)) != 0)
        say_hex("filtering setup failed, status ", (uint32_t)ret);
    return ret;
}

/*
 * bss_info_changed(ASSOC) for the current legacy b/g association request.
 * This is intentionally the ARM32 ABI layout used verbatim by the vendor
 * driver, not a packed structure: flags @0, pad @1, PhyModeCfg @2,
 * mpduStartSpacing @4, pad @5..7 and basicRateSet @8; total 12 bytes.
 * PhyModeCfg=0x0003 is b/g because mac80211 does not yet send an HT
 * capability IE.  JOIN's earlier 0x0007 merely permits firmware probing.
 */
static int xradio_set_assoc(struct ieee80211_bss_conf *conf)
{
    uint16_t phy_mode = 0x0003u;        /* b/g, 20 MHz, primary channel 1 */
    if (conf->use_short_preamble)
        phy_mode |= 1u << 12;           /* PreambleCfg = SHORT */
    uint8_t assoc_mode[12] = { 0x07, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    put_unaligned_le16(phy_mode, assoc_mode + 2);
    put_unaligned_le32(conf->basic_rates, assoc_mode + 8);
    int ret;
    if ((ret = wsm_mib32(WSM_MIB_SET_HT_PROTECTION, 0)) != 0 ||
        (ret = wsm_write_mib(WSM_MIB_SET_ASSOCIATION_MODE, assoc_mode,
                             sizeof(assoc_mode))) != 0 ||
        (ret = wsm_mib32(WSM_MIB_KEEP_ALIVE_PERIOD, 28)) != 0 ||
        (ret = wsm_set_bss_params(conf->aid, 50, conf->supp_rates)) != 0) {
        say_hex("association parameters failed, status ", (uint32_t)ret);
        return ret;
    }
    uint32_t wake = (uint32_t)conf->beacon_int * conf->dtim_period > 1000u
                  ? 1u : conf->dtim_period;
    if ((ret = wsm_set_beacon_wakeup_period((uint8_t)(wake ? wake : 1u), 0)) != 0 ||
        (ret = wsm_set_pm(0)) != 0 ||
        (ret = wsm_mib32(WSM_MIB_DOT11_SLOT_TIME,
                         conf->use_short_slot ? 9u : 20u)) != 0 ||
        (ret = wsm_set_beacon_filter(1, 1)) != 0) {
        say_hex("post-association setup failed, status ", (uint32_t)ret);
        return ret;
    }
    return 0;
}

static int xradio_bss_info_changed(struct ieee80211_hw *hw,
                                   struct ieee80211_bss_conf *info,
                                   uint32_t changed)
{
    (void)hw;
    if (changed & BSS_CHANGED_BSSID) {
        int ret = xradio_do_join(info);
        if (ret) {
            say_hex("WSM JOIN failed, status ", (uint32_t)ret);
            return ret < 0 ? ret : -EIO;
        }
    }
    if ((changed & BSS_CHANGED_ASSOC) && info->assoc) {
        int ret = xradio_set_assoc(info);
        if (ret)
            return ret < 0 ? ret : -EIO;
    }
    return 0;
}

static int xradio_set_key(struct ieee80211_hw *hw, enum set_key_cmd cmd,
                          struct ieee80211_key_conf *key)
{
    (void)hw;
    if (cmd == DISABLE_KEY)
        return wsm_remove_key(key->hw_key_idx);

    if (key->pairwise) {
        if (key->cipher != WLAN_CIPHER_SUITE_CCMP || key->keylen < 16u)
            return -EINVAL;
        key->hw_key_idx = KEY_INDEX_PAIRWISE;
        return wsm_add_key_pairwise(KEY_INDEX_PAIRWISE, key->peer, key->key);
    }

    /* Group key.  TKIP keys come in the nl80211 layout: key | tx MIC |
     * rx MIC; the firmware wants key | rx MIC. */
    uint8_t k[24];
    uint8_t type;
    if (key->cipher == WLAN_CIPHER_SUITE_CCMP && key->keylen >= 16u) {
        type = WSM_KEY_TYPE_AES_GROUP;
        net_memcpy(k, key->key, 16);
    } else if (key->cipher == WLAN_CIPHER_SUITE_TKIP && key->keylen >= 32u) {
        type = WSM_KEY_TYPE_TKIP_GROUP;
        net_memcpy(k, key->key, 16);
        net_memcpy(k + 16, key->key + 24, 8);
    } else {
        return -EINVAL;
    }
    key->hw_key_idx = KEY_INDEX_GROUP;
    int ret = wsm_add_key_group(type, KEY_INDEX_GROUP, k, key->keyidx, key->rsc);
    net_memset(k, 0, sizeof(k));
    return ret;
}

static int xradio_poll(struct ieee80211_hw *hw, int timeout_ms)
{
    (void)hw;
    return xradio_bh_poll(timeout_ms);
}

/* WSM EVENT indication (from the bottom half). */
void xradio_event_cb(uint32_t event_id, uint32_t event_data)
{
    if (event_id == WSM_EVENT_BSS_LOST && xradio_priv.hw) {
        say("BSS_LOST beacon-miss=");
        t113_uart_puthex((event_data >> 8) & 0xffu);
        t113_uart_puts(" reason=");
        t113_uart_puthex(event_data & 0xffu);
        t113_uart_putc('\n');
        ieee80211_beacon_loss(xradio_priv.hw);
    } else if (event_id == WSM_EVENT_BSS_REGAINED) {
        say("BSS_REGAINED\n");
    }
}

const struct ieee80211_ops xradio_ops = {
    .start = xradio_start,
    .tx = xradio_tx,
    .hw_scan = xradio_hw_scan,
    .bss_info_changed = xradio_bss_info_changed,
    .set_key = xradio_set_key,
    .poll = xradio_poll,
};
