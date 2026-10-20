/*
 * Key management, after Linux net/mac80211/key.c: one pairwise and one
 * group key, programmed into the hardware through ops->set_key.  The
 * hardware does all encryption and decryption.
 */
#include "platform.h"
#include "device.h"
#include "net/netutil.h"
#include "ieee80211_i.h"

int ieee80211_add_key(struct ieee80211_local *local, uint8_t key_index,
                      int pairwise, const uint8_t *mac_addr,
                      struct key_params *params)
{
    if (!local->joined || !params->key || params->key_len > 32u)
        return -EINVAL;
    struct ieee80211_key_conf *conf = pairwise ? &local->ptk : &local->gtk;
    net_memset(conf, 0, sizeof(*conf));
    conf->cipher = params->cipher;
    conf->keyidx = key_index;
    conf->pairwise = pairwise != 0;
    conf->keylen = (uint8_t)params->key_len;
    net_memcpy(conf->key, params->key, params->key_len);
    net_memcpy(conf->peer, mac_addr ? mac_addr : local->bss_conf.bssid, ETH_ALEN);
    if (params->seq)
        net_memcpy(conf->rsc, params->seq, 8);
    int r = local->hw.ops->set_key(&local->hw, SET_KEY, conf);
    net_memset(conf->key, 0, sizeof(conf->key));      /* hardware has it */
    if (r) {
        t113_uart_puts(pairwise ? "wlan0: pairwise key rejected "
                                : "wlan0: group key rejected ");
        t113_uart_puthex((uint32_t)r);
        t113_uart_putc('\n');
        return r < 0 ? r : -EIO;
    }
    if (pairwise)
        local->ptk_set = 1;
    else
        local->gtk_set = 1;
    return 0;
}

void ieee80211_free_keys(struct ieee80211_local *local)
{
    if (local->ptk_set)
        local->hw.ops->set_key(&local->hw, DISABLE_KEY, &local->ptk);
    if (local->gtk_set)
        local->hw.ops->set_key(&local->hw, DISABLE_KEY, &local->gtk);
    local->ptk_set = 0;
    local->gtk_set = 0;
}
