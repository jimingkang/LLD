/*
 * XRadio core probe, after the xradio driver's main.c
 * (xradio_core_init / xradio_register_common): load the firmware, start
 * the WSM layer, configure the MAC and register with mac80211.
 */
#include "platform.h"
#include "device.h"
#include "mmc.h"
#include "net/netutil.h"
#include "xradio.h"

struct xradio_common xradio_priv;

/* Legacy 2.4 GHz rates; hw_value is the firmware rate index used in
 * rate retry policies and the join/assoc rate bitmaps. */
static const struct ieee80211_rate xradio_rates[] = {
    { 10, 0 }, { 20, 1 }, { 55, 2 }, { 110, 3 },
    { 60, 6 }, { 90, 7 }, { 120, 8 }, { 180, 9 },
    { 240, 10 }, { 360, 11 }, { 480, 12 }, { 540, 13 },
};

static void say(struct sdio_func *func, const char *msg)
{
    t113_uart_puts(func->dev_name);
    t113_uart_puts(": ");
    t113_uart_puts(msg);
}

static void say_hex(struct sdio_func *func, const char *msg, uint32_t v)
{
    say(func, msg);
    t113_uart_puthex(v);
    t113_uart_putc('\n');
}

/* CONFIGURATION must be the first normal WSM command after the startup
 * indication: it hands the SDD to the firmware (xradio_setup_mac). */
static int xradio_setup_mac(struct xradio_common *hw_priv)
{
    static const uint8_t requested_mac[6] = { 0x02, 0x0a, 0x9e, 0x22, 0x82, 0x01 };
    struct wsm_configuration wcfg;
    struct sdio_func *func = hw_priv->func;
    say_hex(func, "configure firmware, SDD bytes=", hw_priv->sdd_len);
    int ret = wsm_configuration(requested_mac, hw_priv->sdd, hw_priv->sdd_len,
                                &wcfg);
    if (ret) {
        say_hex(func, "WSM configuration failed ", (uint32_t)ret);
        return ret < 0 ? ret : -EIO;
    }
    net_memcpy(hw_priv->mac_addr, wcfg.station_id, ETH_ALEN);
    say(func, "configured MAC ");
    net_print_mac(hw_priv->mac_addr);
    t113_uart_puts(" bands=");
    t113_uart_puthex(wcfg.bands);
    t113_uart_puts(" rates=");
    t113_uart_puthex(wcfg.rate_mask);
    t113_uart_putc('\n');

    /* Harmless diagnostic query, only after the configuration so it
     * cannot perturb the startup state machine. */
    uint32_t tx_power = 0;
    uint32_t tx_power_len = sizeof(tx_power);
    int mib_ret = wsm_read_mib(WSM_MIB_DOT11_CURRENT_TX_POWER, &tx_power,
                               &tx_power_len);
    if (!mib_ret) {
        say(func, "WSM READ_MIB current TX power OK, len ");
        net_putdec(tx_power_len);
        t113_uart_puts(" data ");
        t113_uart_puthex(tx_power);
        t113_uart_putc('\n');
    } else {
        say_hex(func, "WSM READ_MIB current TX power failed ", (uint32_t)mib_ret);
    }
    return 0;
}

int xradio_core_probe(struct sdio_func *func)
{
    struct xradio_common *hw_priv = &xradio_priv;
    hw_priv->func = func;

    int ret = xradio_load_firmware(hw_priv);
    if (ret < 0) {
        say(func, "firmware load FAILED\n");
        return ret;
    }
    say(func, "firmware running\n");
    if ((ret = wsm_init(func, 2000)) < 0) {
        say(func, "WSM command layer init failed\n");
        xradio_bh_diag();
        return ret;
    }
    say(func, "WSM command layer ready\n");
    if ((ret = xradio_setup_mac(hw_priv)) < 0)
        return ret;

    hw_priv->hw = ieee80211_alloc_hw(&xradio_ops, hw_priv);
    if (!hw_priv->hw)
        return -EBUSY;
    ret = ieee80211_register_hw(hw_priv->hw, hw_priv->mac_addr, xradio_rates,
                                sizeof(xradio_rates) / sizeof(xradio_rates[0]));
    if (ret < 0)
        say_hex(func, "mac80211 registration failed ", (uint32_t)ret);
    return ret;
}
