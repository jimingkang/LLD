#ifndef MINIOS_BOOTPACK_H
#define MINIOS_BOOTPACK_H

/*
 * miniOS boot pack: a tiny container written to the SD card right after
 * Boot0, so the SPL can load images larger than SRAM into DDR.
 *
 *   SD byte 8 KiB    : Boot0 (miniBoot SPL, BootROM loads it to SRAM)
 *   SD byte 128 KiB  : bootpack header (512 bytes) + images, 512-aligned
 *
 * The SPL loads every entry to its load_addr, verifies CRC32, copies the
 * header to BOOTPACK_DDR_ADDR (just below the kernel) for the kernel to
 * find later images (e.g. WiFi firmware), then jumps to entry "kernel".
 * This header is shared verbatim by miniBoot, miniOS and tools/mkbootpack.
 */

#include <stdint.h>

#define BOOTPACK_MAGIC          0x4b41504du     /* "MPAK" little endian */
#define BOOTPACK_VERSION        1u
#define BOOTPACK_SD_OFFSET      (128u * 1024u)  /* bytes from card start */
#define BOOTPACK_SD_SECTOR      (BOOTPACK_SD_OFFSET / 512u)
#define BOOTPACK_MAX_SIZE       (896u * 1024u)  /* must end before 1 MiB */
#define BOOTPACK_MAX_ENTRIES    8u
#define BOOTPACK_NAME_LEN       16u
#define BOOTPACK_DDR_ADDR       0x401ff000u     /* header copy for the kernel */

/*
 * Where images may be loaded. The kernel lives at 0x40200000 and its page
 * allocator owns everything after it, so extra images (WiFi firmware, ...)
 * go in the 2 MiB below the kernel, which nothing else uses.
 */
#define BOOTPACK_KERNEL_ADDR    0x40200000u
#define BOOTPACK_AUX_BASE       0x40000000u
#define BOOTPACK_AUX_END        0x401ff000u     /* exclusive */

struct bootpack_entry {
    char name[BOOTPACK_NAME_LEN];   /* NUL padded, e.g. "kernel" */
    uint32_t offset;                /* bytes from pack start, 512-aligned */
    uint32_t size;                  /* bytes */
    uint32_t load_addr;             /* DDR address the SPL copies it to */
    uint32_t crc32;                 /* IEEE 802.3 CRC32 of the image */
};

struct bootpack_header {
    uint32_t magic;
    uint32_t version;
    uint32_t count;
    uint32_t total_size;            /* header + images, bytes */
    struct bootpack_entry entry[BOOTPACK_MAX_ENTRIES];
    uint32_t header_crc32;          /* CRC32 of everything above */
};

/* 4*4 + 8*32 + 4 = 276 bytes, fits one sector. */
typedef char bootpack_header_fits_sector[
    sizeof(struct bootpack_header) <= 512 ? 1 : -1];

static inline uint32_t bootpack_crc32(uint32_t crc, const void *data,
                                      uint32_t len)
{
    const uint8_t *p = (const uint8_t *)data;
    crc = ~crc;
    while (len--) {
        crc ^= *p++;
        for (int k = 0; k < 8; ++k)
            crc = (crc >> 1) ^ (0xedb88320u & (0u - (crc & 1u)));
    }
    return ~crc;
}

#endif
