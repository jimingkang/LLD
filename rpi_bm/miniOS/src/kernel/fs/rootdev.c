/* T113 boot-SD root device: MBR partition 2, 512-byte sectors. */
#include "platform.h"
#include "fs/rootdev.h"
#include "t113/sd.h"

static uint8_t mbr[512] __attribute__((aligned(4)));
static uint32_t root_lba;
static uint32_t root_sectors_count;

static uint32_t le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

int t113_rootdev_init(void)
{
    int type = t113_sd_init();
    if (type < 0 || t113_sd_read(0, 1, mbr) < 0 ||
        mbr[510] != 0x55 || mbr[511] != 0xaa)
        return -1;
    const uint8_t *partition = mbr + 446u + 16u; /* second MBR entry */
    root_lba = le32(partition + 8);
    root_sectors_count = le32(partition + 12);
    if (!partition[4] || !root_lba || root_sectors_count < 4u)
        return -1;
    t113_uart_puts("rootdev: MBR partition 2 type=");
    t113_uart_puthex(partition[4]);
    t113_uart_puts(" lba="); t113_uart_puthex(root_lba);
    t113_uart_puts(" sectors="); t113_uart_puthex(root_sectors_count);
    t113_uart_putc('\n');
    return 0;
}

int t113_rootdev_read(uint32_t sector, uint32_t count, void *destination)
{
    if (!destination || sector > root_sectors_count ||
        count > root_sectors_count - sector)
        return -1;
    return t113_sd_read(root_lba + sector, count, destination);
}

uint32_t t113_rootdev_sectors(void)
{
    return root_sectors_count;
}
