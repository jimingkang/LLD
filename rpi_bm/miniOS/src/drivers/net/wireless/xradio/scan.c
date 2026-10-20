/*
 * XRadio hardware scan, after the xradio driver's scan.c.  The scan is
 * passive (no probe-request template); every beacon the firmware hears
 * comes back as an RX indication and goes to mac80211 like any frame.
 */
#include "platform.h"
#include "device.h"
#include "net/netutil.h"
#include "xradio.h"

int xradio_hw_scan(struct ieee80211_hw *hw, struct cfg80211_scan_request *req)
{
    (void)hw;
    struct wsm_scan_channel channels[CFG80211_MAX_CHANNELS];
    uint32_t n = req->n_channels;
    if (!n || n > CFG80211_MAX_CHANNELS)
        return -EINVAL;
    for (uint32_t i = 0; i < n; ++i) {
        channels[i].number = req->channels[i];
        channels[i].min_time_ms = req->min_dwell_ms;
        channels[i].max_time_ms = req->max_dwell_ms;
    }
    int ret = wsm_scan(channels, (uint8_t)n, 0, 0);
    if (ret) {
        t113_uart_puts("xradio: scan command failed ");
        t113_uart_puthex((uint32_t)ret);
        t113_uart_putc('\n');
        return ret < 0 ? ret : -EIO;
    }
    return 0;
}

/* SCAN_COMPLETE indication (from the bottom half). */
void xradio_scan_complete_cb(const uint8_t *msg, uint32_t len)
{
    uint32_t status = len >= 8u ? get_unaligned_le32(msg + 4) : 0;
    if (status) {
        t113_uart_puts("xradio: scan complete status=");
        t113_uart_puthex(status);
        t113_uart_putc('\n');
    }
    if (xradio_priv.hw)
        ieee80211_scan_completed(xradio_priv.hw, status != 0);
}
