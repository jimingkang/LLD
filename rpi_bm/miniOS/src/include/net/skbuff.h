#ifndef MINIOS_NET_SKBUFF_H
#define MINIOS_NET_SKBUFF_H

#include <stdint.h>

/*
 * Socket buffers, after Linux include/linux/skbuff.h, cut down to one
 * linear buffer per skb taken from a fixed pool (no kmalloc in miniOS).
 *
 *   head            data            data+len              head+SKB_DATA_SIZE
 *    |<- headroom ->|<---- len ----->|<----- tailroom ----->|
 *
 * Every layer adds its header with skb_push() and removes it with
 * skb_pull(), so a UDP payload becomes an Ethernet frame and then an
 * 802.11 frame in place, without copies.  alloc_skb() leaves NET_SKB_PAD
 * bytes of headroom, enough for UDP + IPv4 + 802.11 + CCMP + LLC/SNAP.
 */

#define NET_SKB_PAD      128u
#define SKB_DATA_SIZE    1792u
#define SKB_POOL_SIZE    32u

#define PACKET_HOST      0u      /* to us */
#define PACKET_BROADCAST 1u
#define PACKET_MULTICAST 2u
#define PACKET_OTHERHOST 3u      /* to someone else */

struct net_device;

struct sk_buff {
    struct sk_buff *next;        /* in an sk_buff_head */
    struct net_device *dev;
    uint8_t *data;
    uint32_t len;
    uint16_t protocol;           /* ETH_P_*, host order (eth_type_trans) */
    uint8_t pkt_type;            /* PACKET_* */
    uint8_t in_use;
    /* Per-layer scratch: mac80211 keeps ieee80211_rx_status / tx_info here. */
    uint8_t cb[24] __attribute__((aligned(4)));
    uint8_t head[SKB_DATA_SIZE] __attribute__((aligned(4)));
};

struct sk_buff_head {
    struct sk_buff *first;
    struct sk_buff *last;
    uint32_t qlen;
};

/* size: largest payload the caller will skb_put(); 0 if none is free. */
struct sk_buff *alloc_skb(uint32_t size);
void kfree_skb(struct sk_buff *skb);

static inline uint32_t skb_headroom(const struct sk_buff *skb)
{
    return (uint32_t)(skb->data - skb->head);
}

static inline uint32_t skb_tailroom(const struct sk_buff *skb)
{
    return SKB_DATA_SIZE - skb_headroom(skb) - skb->len;
}

/* Extend the data at the end; returns the old tail, 0 if it does not fit. */
static inline uint8_t *skb_put(struct sk_buff *skb, uint32_t n)
{
    if (n > skb_tailroom(skb))
        return 0;
    uint8_t *tail = skb->data + skb->len;
    skb->len += n;
    return tail;
}

/* Prepend n bytes; returns the new data pointer, 0 without headroom. */
static inline uint8_t *skb_push(struct sk_buff *skb, uint32_t n)
{
    if (n > skb_headroom(skb))
        return 0;
    skb->data -= n;
    skb->len += n;
    return skb->data;
}

/* Remove n bytes from the front; returns the new data pointer or 0. */
static inline uint8_t *skb_pull(struct sk_buff *skb, uint32_t n)
{
    if (n > skb->len)
        return 0;
    skb->data += n;
    skb->len -= n;
    return skb->data;
}

static inline void skb_trim(struct sk_buff *skb, uint32_t len)
{
    if (len < skb->len)
        skb->len = len;
}

static inline void skb_reserve(struct sk_buff *skb, uint32_t n)
{
    skb->data += n;
}

void skb_queue_head_init(struct sk_buff_head *q);
void skb_queue_tail(struct sk_buff_head *q, struct sk_buff *skb);
struct sk_buff *skb_dequeue(struct sk_buff_head *q);
void skb_queue_purge(struct sk_buff_head *q);

#endif
