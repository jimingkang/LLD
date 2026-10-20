/*
 * Socket buffer pool, after Linux net/core/skbuff.c.  miniOS has no
 * general-purpose allocator, so skbs come from a fixed array; callers
 * hold the network lock (or run in the device bottom half under it).
 */
#include "net/skbuff.h"

static struct sk_buff skb_pool[SKB_POOL_SIZE];

struct sk_buff *alloc_skb(uint32_t size)
{
    if (size > SKB_DATA_SIZE - NET_SKB_PAD)
        return 0;
    for (uint32_t i = 0; i < SKB_POOL_SIZE; ++i) {
        struct sk_buff *skb = &skb_pool[i];
        if (skb->in_use)
            continue;
        skb->in_use = 1;
        skb->next = 0;
        skb->dev = 0;
        skb->data = skb->head + NET_SKB_PAD;
        skb->len = 0;
        skb->protocol = 0;
        skb->pkt_type = 0;
        for (uint32_t k = 0; k < sizeof(skb->cb); ++k)
            skb->cb[k] = 0;
        return skb;
    }
    return 0;
}

void kfree_skb(struct sk_buff *skb)
{
    if (skb)
        skb->in_use = 0;
}

void skb_queue_head_init(struct sk_buff_head *q)
{
    q->first = q->last = 0;
    q->qlen = 0;
}

void skb_queue_tail(struct sk_buff_head *q, struct sk_buff *skb)
{
    skb->next = 0;
    if (q->last)
        q->last->next = skb;
    else
        q->first = skb;
    q->last = skb;
    ++q->qlen;
}

struct sk_buff *skb_dequeue(struct sk_buff_head *q)
{
    struct sk_buff *skb = q->first;
    if (!skb)
        return 0;
    q->first = skb->next;
    if (!q->first)
        q->last = 0;
    skb->next = 0;
    --q->qlen;
    return skb;
}

void skb_queue_purge(struct sk_buff_head *q)
{
    struct sk_buff *skb;
    while ((skb = skb_dequeue(q)))
        kfree_skb(skb);
}
