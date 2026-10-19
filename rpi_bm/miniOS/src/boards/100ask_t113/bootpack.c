/*
 * Kernel side of the SD boot pack: the SPL copies the pack header to
 * BOOTPACK_DDR_ADDR before jumping here; images are already in DDR.
 */
#include "platform.h"
#include "bootpack.h"

static const struct bootpack_header *header(void)
{
    const struct bootpack_header *h =
        (const struct bootpack_header *)(uintptr_t)BOOTPACK_DDR_ADDR;
    if (h->magic != BOOTPACK_MAGIC || h->count > BOOTPACK_MAX_ENTRIES)
        return 0;
    if (bootpack_crc32(0, h, (uint32_t)((const uint8_t *)&h->header_crc32 -
                                        (const uint8_t *)h)) != h->header_crc32)
        return 0;
    return h;
}

const struct bootpack_entry *t113_bootpack_find(const char *name)
{
    const struct bootpack_header *h = header();
    for (uint32_t i = 0; h && i < h->count; ++i) {
        const char *a = h->entry[i].name, *b = name;
        uint32_t k = 0;
        while (k < BOOTPACK_NAME_LEN && a[k] == b[k] && b[k])
            ++k;
        if (k < BOOTPACK_NAME_LEN && a[k] == b[k])
            return &h->entry[i];
    }
    return 0;
}

void t113_bootpack_dump(void)
{
    const struct bootpack_header *h = header();
    if (!h) {
        t113_uart_puts("bootpack: none (kernel was embedded in the SPL)\n");
        return;
    }
    for (uint32_t i = 0; i < h->count; ++i) {
        const struct bootpack_entry *e = &h->entry[i];
        t113_uart_puts("bootpack: ");
        t113_uart_puts(e->name);
        t113_uart_puts(" @");
        t113_uart_puthex(e->load_addr);
        t113_uart_puts(" bytes=");
        t113_uart_puthex(e->size);
        t113_uart_putc('\n');
    }
}
