#ifndef MINIOS_FS_BIO_H
#define MINIOS_FS_BIO_H

#include <stdint.h>

/*
 * Block buffer cache over the boot SD card, after xv6 bio.c.
 * Block numbers are absolute 512-byte LBAs on SD0.
 *
 * bread()   returns a referenced buffer holding the block's contents.
 * bget_blank() returns a referenced buffer whose old contents are not
 *           read, for callers that overwrite the whole block.
 * bwrite()  writes the buffer through to the card.
 * brelse()  drops the reference; the buffer stays cached (LRU).
 *
 * Callers serialise access to a given block themselves (fat32 holds its
 * filesystem lock around every operation).
 */
#define BSIZE 512u

struct buf {
    uint32_t valid;
    uint32_t refcnt;
    uint32_t blockno;
    struct buf *prev;     /* LRU list */
    struct buf *next;
    uint8_t data[BSIZE] __attribute__((aligned(4)));
};

void binit(void);
struct buf *bread(uint32_t blockno);
struct buf *bget_blank(uint32_t blockno);
int bwrite(struct buf *b);
void brelse(struct buf *b);

#endif
