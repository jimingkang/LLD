#include "platform.h"

#define PAGE_SIZE 4096u

static uint8_t *page_bitmap;
static uintptr_t pool_start;
static uint32_t pool_pages;

static uint32_t page_is_used(uint32_t page)
{
    return (page_bitmap[page >> 3] >> (page & 7u)) & 1u;
}

static void page_mark(uint32_t page, uint32_t used)
{
    uint8_t mask = (uint8_t)(1u << (page & 7u));
    if (used)
        page_bitmap[page >> 3] |= mask;
    else
        page_bitmap[page >> 3] &= (uint8_t)~mask;
}

static void zero_pages(void *address, uint32_t count)
{
    uint32_t *word = (uint32_t *)address;
    for (uint32_t i = 0; i < count * PAGE_SIZE / sizeof(uint32_t); ++i)
        word[i] = 0;
}

void t113_page_alloc_init(uint32_t base, uint32_t size)
{
    pool_start = (base + PAGE_SIZE - 1u) & ~(PAGE_SIZE - 1u);
    pool_pages = (size - (uint32_t)(pool_start - base)) / PAGE_SIZE;
    page_bitmap = (uint8_t *)pool_start;

    uint32_t bitmap_bytes = (pool_pages + 7u) / 8u;
    uint32_t bitmap_pages = (bitmap_bytes + PAGE_SIZE - 1u) / PAGE_SIZE;
    for (uint32_t i = 0; i < bitmap_pages * PAGE_SIZE; ++i)
        page_bitmap[i] = 0;
    for (uint32_t i = 0; i < bitmap_pages; ++i)
        page_mark(i, 1);

    t113_uart_puts("page allocator: pool=[");
    t113_uart_puthex((uint32_t)pool_start);
    t113_uart_puts(", ");
    t113_uart_puthex((uint32_t)(pool_start + pool_pages * PAGE_SIZE));
    t113_uart_puts(") pages=");
    t113_uart_puthex(pool_pages);
    t113_uart_puts(" bitmap-pages=");
    t113_uart_puthex(bitmap_pages);
    t113_uart_putc('\n');
}

void *t113_alloc_pages(uint32_t count, uint32_t align_pages)
{
    if (!count || count > pool_pages)
        return 0;
    if (!align_pages)
        align_pages = 1;

    for (uint32_t i = 0; i + count <= pool_pages; ++i) {
        uintptr_t address = pool_start + i * PAGE_SIZE;
        if (((address / PAGE_SIZE) % align_pages) != 0)
            continue;

        uint32_t j;
        for (j = 0; j < count && !page_is_used(i + j); ++j) { }
        if (j != count) {
            i += j;
            continue;
        }

        for (j = 0; j < count; ++j)
            page_mark(i + j, 1);
        zero_pages((void *)address, count);
        return (void *)address;
    }
    return 0;
}

void *t113_alloc_page(void)
{
    return t113_alloc_pages(1, 1);
}

void t113_free_pages(void *address, uint32_t count)
{
    uintptr_t value = (uintptr_t)address;

    if (value < pool_start || (value & (PAGE_SIZE - 1u)) || !count)
        return;
    uint32_t index = (uint32_t)((value - pool_start) / PAGE_SIZE);
    if (index + count > pool_pages)
        return;
    for (uint32_t i = 0; i < count; ++i)
        page_mark(index + i, 0);
}

uint32_t t113_page_free_count(void)
{
    uint32_t free = 0;
    for (uint32_t i = 0; i < pool_pages; ++i)
        free += page_is_used(i) == 0;
    return free;
}
