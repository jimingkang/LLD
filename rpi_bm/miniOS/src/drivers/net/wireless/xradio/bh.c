/*
 * XRadio bottom half, after the xradio driver's bh.c: moves WSM messages
 * through the HIF queue register.
 *
 * Write to IN_OUT_QUEUE with buf_id = tx id (0..31), read with
 * buf_id = rx id + 1 (rx id 0..3).  CONTROL.NEXT_LEN gives the next
 * message length in 16-bit words; each read returns 2 extra bytes: the
 * next CONTROL value (piggyback).  Every request takes one of the
 * firmware's input buffers and every confirm frees one.
 *
 * Linux runs this as a thread woken by the SDIO interrupt; here
 * xradio_bh_poll() is called from the mac80211 poll and while waiting
 * for confirms.  The handlers it calls (wsm_handle_rx and below) only
 * record or queue, so the bottom half is never re-entered.
 */
#include "platform.h"
#include "device.h"
#include "mmc.h"
#include "net/netutil.h"
#include "xradio.h"

#define BH_RX_BUF_SIZE  4096u

static struct {
    struct sdio_func *func;
    uint32_t num_bufs;           /* firmware input buffers */
    uint32_t buf_size;
    int hw_bufs_used;
    uint8_t tx_seq, rx_seq;
    uint8_t buf_id_tx, buf_id_rx;
    uint32_t next_ctrl;          /* piggybacked CONTROL, 0 = read register */
    int halted;
    int in_rx;
} bh;

static uint32_t rx_buf[BH_RX_BUF_SIZE / 4u];

static void bh_msg(const char *s)
{
    t113_uart_puts("xradio bh: ");
    t113_uart_puts(s);
}

void xradio_bh_init(struct sdio_func *func)
{
    net_memset(&bh, 0, sizeof(bh));
    bh.func = func;
    bh.num_bufs = 1;             /* until the startup indication */
}

void xradio_bh_set_caps(uint32_t num_bufs, uint32_t buf_size)
{
    bh.num_bufs = num_bufs ? num_bufs : 1u;
    bh.buf_size = buf_size;
}

void xradio_bh_halt(void) { bh.halted = 1; }
int xradio_bh_halted(void) { return bh.halted; }

/* Same rule as sdio_io_rw_extended: byte mode up to min(blksz, 512). */
static uint32_t align_len(uint32_t n)
{
    uint32_t bs = bh.func->blksz ? bh.func->blksz : 512u;
    uint32_t byte_max = bs < 512u ? bs : 512u;
    n = (n + 3u) & ~3u;
    if (n <= byte_max)
        return n;
    return (n + bs - 1u) / bs * bs;
}

/* A confirm frees input buffers: one, or one per TX in a multi confirm. */
static void release_buffers(const uint8_t *m, uint32_t len)
{
    uint16_t id = WSM_MSG_ID(get_unaligned_le16(m + 2));
    if (!(id & 0x0400u))
        return;
    uint32_t n = 1;
    if (id == 0x041eu && len >= 8u && get_unaligned_le32(m + 4))
        n = get_unaligned_le32(m + 4);
    bh.hw_bufs_used -= (int)n;
    if (bh.hw_bufs_used < 0)
        bh.hw_bufs_used = 0;
}

/* Read one queue transfer if CONTROL says something is pending. */
static int rx_one(void)
{
    struct sdio_func *f = bh.func;
    uint32_t ctrl = bh.next_ctrl;
    int ret;

    if (!(ctrl & HIF_CTRL_NEXT_LEN_MASK)) {
        if ((ret = xradio_reg_read_32(f, HIF_CONTROL_REG_ID, &ctrl)) < 0)
            return ret;
    }
    bh.next_ctrl = 0;
    uint32_t len = (ctrl & HIF_CTRL_NEXT_LEN_MASK) << 1;
    if (!len)
        return 0;
    uint32_t rd = align_len(len + 2u);
    if (len < WSM_HDR_LEN || rd > sizeof(rx_buf)) {
        bh_msg("bad rx length ");
        net_putdec(len);
        t113_uart_putc('\n');
        return -EIO;
    }
    uint8_t *b = (uint8_t *)rx_buf;
    uint32_t buf_id = bh.buf_id_rx + 1u;
    if ((ret = sdio_memcpy_fromio(f, b, HIF_ADDR(buf_id, HIF_IN_OUT_QUEUE_REG_ID), rd)) < 0) {
        bh_msg("queue read failed\n");
        return ret;
    }
    bh.buf_id_rx = (uint8_t)(buf_id & 3u);
    bh.next_ctrl = get_unaligned_le16(b + rd - 2u);     /* piggyback */

    uint8_t seq = (uint8_t)((get_unaligned_le16(b + 2) >> 13) & 7u);
    if (seq != bh.rx_seq) {
        bh_msg("rx seq ");
        net_putdec(seq);
        t113_uart_puts(" expected ");
        net_putdec(bh.rx_seq);
        t113_uart_putc('\n');
    }
    bh.rx_seq = (uint8_t)((seq + 1u) & 7u);

    /* One transfer may carry several RX indications (multi-rx). */
    for (uint32_t off = 0; off + WSM_HDR_LEN <= len;) {
        uint32_t mlen = get_unaligned_le16(b + off);
        if (mlen < WSM_HDR_LEN || off + mlen > len)
            break;
        release_buffers(b + off, mlen);
        wsm_handle_rx(b + off, mlen);
        off += (mlen + 3u) & ~3u;
    }
    return 1;
}

int xradio_bh_poll(int timeout_ms)
{
    if (!bh.func)
        return -ENODEV;
    if (bh.in_rx)
        return -EBUSY;          /* a handler tried to poll: not allowed */
    uint64_t end = t113_time_us() + (uint64_t)(timeout_ms > 0 ? timeout_ms : 0) * 1000u;
    int handled = 0;
    for (;;) {
        bh.in_rx = 1;
        int r = rx_one();
        bh.in_rx = 0;
        if (r < 0)
            return r;
        if (r > 0) {
            ++handled;
            continue;                   /* drain */
        }
        if (handled || t113_time_us() >= end || bh.halted)
            return handled;
        t113_udelay(200);
    }
}

int xradio_bh_tx(uint8_t *b, uint32_t len, uint32_t cap)
{
    struct sdio_func *f = bh.func;
    if (!f || bh.halted)
        return -ENODEV;
    uint64_t end = t113_time_us() + 2000000u;
    while (bh.hw_bufs_used >= (int)bh.num_bufs) {
        if (xradio_bh_poll(10) < 0 || t113_time_us() > end || bh.halted) {
            bh_msg("no free firmware input buffer\n");
            return -ETIMEDOUT;
        }
    }
    if (bh.buf_size && len > bh.buf_size) {
        bh_msg("message too long\n");
        return -EINVAL;
    }
    put_unaligned_le16(len, b);
    put_unaligned_le16((get_unaligned_le16(b + 2) & 0x1fffu) |
                       ((uint32_t)bh.tx_seq << 13), b + 2);
    uint32_t wlen = align_len(len <= 8u ? 16u : len);
    if (wlen > cap)
        return -EINVAL;
    net_memset(b + len, 0, wlen - len);
    int ret = sdio_memcpy_toio(f, HIF_ADDR(bh.buf_id_tx, HIF_IN_OUT_QUEUE_REG_ID), b, wlen);
    if (ret < 0) {
        bh_msg("queue write failed\n");
        return ret;
    }
    bh.buf_id_tx = (uint8_t)((bh.buf_id_tx + 1u) & 31u);
    bh.tx_seq = (uint8_t)((bh.tx_seq + 1u) & 7u);
    ++bh.hw_bufs_used;
    return 0;
}

void xradio_bh_diag(void)
{
    uint32_t ctrl = 0;
    if (!bh.func || xradio_reg_read_32(bh.func, HIF_CONTROL_REG_ID, &ctrl) < 0) {
        bh_msg("CONTROL unreadable\n");
        return;
    }
    bh_msg("CONTROL ");
    t113_uart_puthex(ctrl);
    t113_uart_puts(ctrl & HIF_CTRL_NEXT_LEN_MASK ? " (message pending)\n"
                                                 : " (queue empty)\n");
}
