/*
 * Buffer cache, after xv6 kernel/bio.c.
 *
 * A doubly linked list of buffers ordered by how recently they were
 * released: head.next is the most recent, head.prev the least.  A cache
 * miss recycles the least recently used buffer with no references.
 * Writes go straight through to the SD card.
 */
#include "platform.h"
#include "mutex.h"
#include "fs/bio.h"
#include "t113/sd.h"

#define NBUF 24u

static struct {
    struct mutex lock;
    struct buf buf[NBUF];
    struct buf head;
} bcache;

void binit(void)
{
    mutex_init(&bcache.lock);
    bcache.head.prev = &bcache.head;
    bcache.head.next = &bcache.head;
    for (struct buf *b = bcache.buf; b < bcache.buf + NBUF; ++b) {
        b->valid = 0;
        b->refcnt = 0;
        b->next = bcache.head.next;
        b->prev = &bcache.head;
        bcache.head.next->prev = b;
        bcache.head.next = b;
    }
}

/* Look through the cache for blockno; otherwise recycle an unused buffer.
 * Returns a referenced buffer, or 0 if every buffer is in use. */
static struct buf *bget(uint32_t blockno)
{
    struct buf *b;
    mutex_lock(&bcache.lock);
    for (b = bcache.head.next; b != &bcache.head; b = b->next) {
        if (b->valid && b->blockno == blockno) {
            ++b->refcnt;
            mutex_unlock(&bcache.lock);
            return b;
        }
    }
    for (b = bcache.head.prev; b != &bcache.head; b = b->prev) {
        if (b->refcnt == 0) {
            b->blockno = blockno;
            b->valid = 0;
            b->refcnt = 1;
            mutex_unlock(&bcache.lock);
            return b;
        }
    }
    mutex_unlock(&bcache.lock);
    t113_uart_puts("bio: no free buffers\n");
    return 0;
}

struct buf *bread(uint32_t blockno)
{
    struct buf *b = bget(blockno);
    if (b && !b->valid) {
        if (t113_sd_read(blockno, 1, b->data) < 0) {
            brelse(b);
            return 0;
        }
        b->valid = 1;
    }
    return b;
}

struct buf *bget_blank(uint32_t blockno)
{
    struct buf *b = bget(blockno);
    if (b)
        b->valid = 1;
    return b;
}

int bwrite(struct buf *b)
{
    if (!b || t113_sd_write(b->blockno, 1, b->data) < 0) {
        if (b)
            b->valid = 0;   /* card contents unknown: force a re-read */
        return -1;
    }
    return 0;
}

void brelse(struct buf *b)
{
    if (!b)
        return;
    mutex_lock(&bcache.lock);
    if (--b->refcnt == 0) {
        /* Move to the head: most recently used. */
        b->next->prev = b->prev;
        b->prev->next = b->next;
        b->next = bcache.head.next;
        b->prev = &bcache.head;
        bcache.head.next->prev = b;
        bcache.head.next = b;
    }
    mutex_unlock(&bcache.lock);
}
