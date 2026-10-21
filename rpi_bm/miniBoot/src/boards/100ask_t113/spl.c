#include "platform.h"
#include "sd.h"
#include "bootpack.h"
#include "fat32.h"

extern uint8_t __kernel_load_start[];
extern uint8_t __kernel_load_end[];
extern uint8_t __kernel_start[];

static void copy_kernel_payload(void)
{
    uint32_t *src = (uint32_t *)(uintptr_t)__kernel_load_start;
    uint32_t *end = (uint32_t *)(uintptr_t)__kernel_load_end;
    uint32_t *dst = (uint32_t *)(uintptr_t)__kernel_start;
    while (src < end)
        *dst++ = *src++;
}

static void jump_to_kernel(uint32_t dram_size) __attribute__((noreturn));
static void jump_to_kernel(uint32_t dram_size)
{
    void (*entry)(uint32_t) = (void (*)(uint32_t))(uintptr_t)__kernel_start;
    __asm__ volatile(
        "dsb sy\n\t"
        "mov r1, #0\n\t"
        "mcr p15, 0, r1, c8, c7, 0\n\t"  /* invalidate TLB */
        "mcr p15, 0, r1, c7, c5, 0\n\t"  /* invalidate I-cache */
        "mcr p15, 0, r1, c7, c5, 6\n\t"  /* invalidate branch predictor */
        "dsb sy\n\t"
        "isb"
        : : : "r1", "memory");
    entry(dram_size);
    for (;;)
        __asm__ volatile("wfi");
}

static void hang(const char *why)
{
    t113_early_uart_puts("SPL PANIC: ");
    t113_early_uart_puts(why);
    t113_early_uart_putc('\n');
    for (;;)
        __asm__ volatile("wfi");
}

static int name_is(const struct bootpack_entry *e, const char *n)
{
    for (uint32_t i = 0; i < BOOTPACK_NAME_LEN; ++i) {
        if (e->name[i] != n[i])
            return 0;
        if (!n[i])
            return 1;
    }
    return 1;
}

static struct bootpack_entry *bootpack_slot(struct bootpack_header *h,
                                             const char *name)
{
    for (uint32_t i = 0; i < h->count; ++i)
        if (name_is(&h->entry[i], name))
            return &h->entry[i];
    if (h->count >= BOOTPACK_MAX_ENTRIES)
        return 0;
    struct bootpack_entry *e = &h->entry[h->count++];
    for (uint32_t i = 0; i < sizeof(*e); ++i) ((uint8_t *)e)[i] = 0;
    for (uint32_t i = 0; i + 1u < BOOTPACK_NAME_LEN && name[i]; ++i)
        e->name[i] = name[i];
    return e;
}

static void load_fat32_firmware(struct bootpack_header *h)
{
    static const struct {
        const char *file;
        const char *entry;
        uint32_t address;
        uint32_t capacity;
    } images[] = {
        { "boot_xr829.bin", "boot_xr829", 0x40100000u, 0x00010000u },
        { "fw_xr829.bin",   "fw_xr829",   0x40110000u, 0x00030000u },
        { "sdd_xr829.bin",  "sdd_xr829",  0x40140000u, 0x00010000u },
    };
    struct fat32_fs fs;
    if (fat32_mount(&fs) < 0) {
        t113_early_uart_puts("SPL: no FAT32 partition; using packed firmware\n");
        return;
    }
    t113_early_uart_puts("SPL: FAT32 partition LBA=");
    t113_early_uart_puthex(fs.partition_lba);
    t113_early_uart_putc('\n');
    for (uint32_t i = 0; i < sizeof(images) / sizeof(images[0]); ++i) {
        uint32_t size;
        if (fat32_load_root(&fs, images[i].file,
                            (void *)(uintptr_t)images[i].address,
                            images[i].capacity, &size) < 0) {
            t113_early_uart_puts("SPL: FAT32 missing ");
            t113_early_uart_puts(images[i].file);
            t113_early_uart_putc('\n');
            continue;
        }
        struct bootpack_entry *e = bootpack_slot(h, images[i].entry);
        if (!e) {
            t113_early_uart_puts("SPL: bootpack metadata full\n");
            break;
        }
        e->offset = 0;                 /* resident image, not pack-relative */
        e->size = size;
        e->load_addr = images[i].address;
        e->crc32 = bootpack_crc32(0, (const void *)(uintptr_t)e->load_addr,
                                  e->size);
        t113_early_uart_puts("SPL: FAT32 load ");
        t113_early_uart_puts(images[i].file);
        t113_early_uart_puts(" bytes=");
        t113_early_uart_puthex(size);
        t113_early_uart_putc('\n');
    }
    h->header_crc32 = bootpack_crc32(
        0, h, (uint32_t)((uint8_t *)&h->header_crc32 - (uint8_t *)h));
}

/*
 * A kernel in the FAT32 partition (e.g. updated by miniOS "tftp") wins
 * over the one in the bootpack.  Delete or rename the file to fall back.
 */
#define FAT32_KERNEL_NAME  "kernel_minios.img"
#define FAT32_KERNEL_MAX   (8u * 1024u * 1024u)

static uint32_t load_fat32_kernel(void)
{
    struct fat32_fs fs;
    uint32_t size = 0;
    if (fat32_mount(&fs) < 0 ||
        fat32_load_root(&fs, FAT32_KERNEL_NAME,
                        (void *)(uintptr_t)BOOTPACK_KERNEL_ADDR,
                        FAT32_KERNEL_MAX, &size) < 0)
        return 0;
    t113_early_uart_puts("SPL: FAT32 kernel " FAT32_KERNEL_NAME " bytes=");
    t113_early_uart_puthex(size);
    t113_early_uart_puts(" crc32=");
    t113_early_uart_puthex(bootpack_crc32(
        0, (const void *)(uintptr_t)BOOTPACK_KERNEL_ADDR, size));
    t113_early_uart_putc('\n');
    return size;
}

/*
 * Load the boot pack from SD into DDR. Returns the kernel load address
 * (0 on failure). Every image is CRC-checked; the header is copied to
 * BOOTPACK_DDR_ADDR so the kernel can locate the other images.
 */
static uint32_t load_bootpack(void)
{
    static uint32_t sector[128];
    struct bootpack_header *h = (struct bootpack_header *)sector;
    uint32_t kernel = 0;

    int type = t113_sd_init();
    if (type < 0) {
        t113_early_uart_puts("SPL: SD init failed ");
        t113_early_uart_puthex((uint32_t)type);
        t113_early_uart_putc('\n');
        return 0;
    }
    t113_early_uart_puts(type == 2 ? "SPL: SDHC card ready\n"
                                   : "SPL: SDSC card ready\n");
    uint32_t fat_kernel = load_fat32_kernel();
    if (fat_kernel)
        kernel = BOOTPACK_KERNEL_ADDR;
    if (t113_sd_read(BOOTPACK_SD_SECTOR, 1, sector) < 0) {
        t113_early_uart_puts("SPL: cannot read bootpack header\n");
        return kernel;
    }
    if (h->magic != BOOTPACK_MAGIC || h->count > BOOTPACK_MAX_ENTRIES ||
        bootpack_crc32(0, h, (uint32_t)((uint8_t *)&h->header_crc32 -
                                        (uint8_t *)h)) != h->header_crc32) {
        t113_early_uart_puts("SPL: no valid bootpack at SD 128 KiB\n");
        return kernel;
    }

    for (uint32_t i = 0; i < h->count; ++i) {
        const struct bootpack_entry *e = &h->entry[i];
        uint32_t blocks = (e->size + 511u) / 512u;
        if (fat_kernel && name_is(e, "kernel")) {
            t113_early_uart_puts("SPL: skip bootpack kernel (FAT32 kernel used)\n");
            continue;
        }
        t113_early_uart_puts("SPL: load ");
        t113_early_uart_puts(e->name);
        t113_early_uart_puts(" -> ");
        t113_early_uart_puthex(e->load_addr);
        t113_early_uart_puts(" bytes=");
        t113_early_uart_puthex(e->size);
        if ((e->offset & 511u) || (e->load_addr & 3u) ||
            t113_sd_read(BOOTPACK_SD_SECTOR + e->offset / 512u, blocks,
                         (void *)(uintptr_t)e->load_addr) < 0) {
            t113_early_uart_puts(" READ FAILED\n");
            return 0;
        }
        if (bootpack_crc32(0, (const void *)(uintptr_t)e->load_addr,
                           e->size) != e->crc32) {
            t113_early_uart_puts(" CRC MISMATCH\n");
            return 0;
        }
        t113_early_uart_puts(" ok\n");
        if (name_is(e, "kernel"))
            kernel = e->load_addr;
    }

    uint32_t *dst = (uint32_t *)(uintptr_t)BOOTPACK_DDR_ADDR;
    for (uint32_t i = 0; i < 128; ++i)
        dst[i] = sector[i];
    load_fat32_firmware((struct bootpack_header *)(uintptr_t)BOOTPACK_DDR_ADDR);
    return kernel;
}

void spl_main(void)
{
    t113_early_uart_init();
    t113_early_uart_puts("\nminiOS SPL: 100ASK T113-S3\n");
    t113_early_uart_puts("SPL: running from SRAM, DDR/MMU/cache off\n");

    uint32_t dram_size = t113_dram_init();
    if (!dram_size)
        hang("DDR unavailable");

    /* Clear the header slot so a stale pack is never mistaken for ours. */
    *(volatile uint32_t *)(uintptr_t)BOOTPACK_DDR_ADDR = 0;

    uint32_t embedded = (uint32_t)((uintptr_t)__kernel_load_end -
                                   (uintptr_t)__kernel_load_start);
    if (embedded > 64u) {           /* <= 64: Makefile placeholder, no kernel */
        /* FEL / legacy build: kernel embedded in the SPL image. */
        t113_early_uart_puts("SPL: copy kernel SRAM ");
        t113_early_uart_puthex((uint32_t)(uintptr_t)__kernel_load_start);
        t113_early_uart_puts(" -> DDR ");
        t113_early_uart_puthex((uint32_t)(uintptr_t)__kernel_start);
        t113_early_uart_puts(" bytes=");
        t113_early_uart_puthex((uint32_t)(__kernel_load_end - __kernel_load_start));
        t113_early_uart_putc('\n');
        copy_kernel_payload();
    } else {
        uint32_t kernel = load_bootpack();
        if (!kernel)
            hang("no kernel (embedded payload empty, SD bootpack unusable)");
        if (kernel != (uint32_t)(uintptr_t)__kernel_start)
            hang("bootpack kernel load_addr != 0x40200000");
    }
    t113_early_uart_puts("SPL: jump kernel_entry @ 0x40200000\n");
    jump_to_kernel(dram_size);
}
