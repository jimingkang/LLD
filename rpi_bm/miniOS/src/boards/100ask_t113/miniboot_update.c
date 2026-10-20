#include "device.h"
#include "miniboot_update.h"

#define BOOT0_CHECKSUM_STAMP 0x5f0a6c39u
#define BOOT0_PREFIX_BYTES   20u

static uint32_t load_le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

int miniboot_image_validate(const void *image, uint32_t received_size,
                            uint32_t *image_size)
{
    const uint8_t *p = image;
    uint32_t length, expected, sum = 0;

    if (!p || received_size < BOOT0_PREFIX_BYTES)
        return -EINVAL;
    if (p[4] != 'e' || p[5] != 'G' || p[6] != 'O' || p[7] != 'N' ||
        p[8] != '.' || p[9] != 'B' || p[10] != 'T' || p[11] != '0')
        return -EINVAL;

    expected = load_le32(p + 12);
    length = load_le32(p + 16);
    if (!length || (length & 511u) || length > received_size ||
        length > MINIBOOT_MAX_BYTES)
        return -EINVAL;

    for (uint32_t off = 0; off < length; off += 4u)
        sum += off == 12u ? BOOT0_CHECKSUM_STAMP : load_le32(p + off);
    if (sum != expected)
        return -EIO;

    if (image_size)
        *image_size = length;
    return 0;
}

int miniboot_image_commit(const void *image, uint32_t received_size,
                          miniboot_block_write_t write_blocks, void *opaque)
{
    uint32_t length;
    int ret;

    if (!write_blocks)
        return -EINVAL;
    ret = miniboot_image_validate(image, received_size, &length);
    if (ret)
        return ret;
    return write_blocks(MINIBOOT_SD_START_LBA, image, length / 512u, opaque);
}
