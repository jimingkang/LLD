/* Minimal read-only MBR + FAT32 loader for miniBoot. */
#include "fat32.h"
#include "sd.h"

static uint8_t sector[512] __attribute__((aligned(4)));

static uint16_t le16(const uint8_t *p)
{
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

static uint32_t le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static char lower(char c)
{
    return c >= 'A' && c <= 'Z' ? (char)(c + ('a' - 'A')) : c;
}

static int name_equal(const char *a, const char *b)
{
    while (*a && *b && lower(*a) == lower(*b)) { ++a; ++b; }
    return !*a && !*b;
}

static int is_fat32_type(uint8_t type)
{
    return type == 0x0bu || type == 0x0cu || type == 0x1bu || type == 0x1cu;
}

int fat32_mount(struct fat32_fs *fs)
{
    if (!fs || t113_sd_read(0, 1, sector) < 0 ||
        sector[510] != 0x55 || sector[511] != 0xaa)
        return -1;

    uint32_t part = 0;
    for (uint32_t i = 0; i < 4u; ++i) {
        const uint8_t *e = sector + 446u + i * 16u;
        if (is_fat32_type(e[4])) { part = le32(e + 8); break; }
    }
    if (t113_sd_read(part, 1, sector) < 0 ||
        sector[510] != 0x55 || sector[511] != 0xaa ||
        le16(sector + 11) != 512u || !sector[13] ||
        le16(sector + 17) != 0 || !le32(sector + 36))
        return -1;

    fs->partition_lba = part;
    fs->sectors_per_cluster = sector[13];
    fs->fats = sector[16];
    fs->sectors_per_fat = le32(sector + 36);
    fs->root_cluster = le32(sector + 44);
    fs->fat_lba = part + le16(sector + 14);
    fs->data_lba = fs->fat_lba + fs->fats * fs->sectors_per_fat;
    return fs->root_cluster >= 2u ? 0 : -1;
}

static uint32_t next_cluster(const struct fat32_fs *fs, uint32_t cluster)
{
    uint32_t off = cluster * 4u;
    if (t113_sd_read(fs->fat_lba + off / 512u, 1, sector) < 0)
        return 0x0fffffffu;
    return le32(sector + (off & 511u)) & 0x0fffffffu;
}

static uint32_t cluster_lba(const struct fat32_fs *fs, uint32_t cluster)
{
    return fs->data_lba + (cluster - 2u) * fs->sectors_per_cluster;
}

static void lfn_piece(char *lfn, const uint8_t *e)
{
    static const uint8_t pos[13] = {1,3,5,7,9,14,16,18,20,22,24,28,30};
    uint32_t ord = (e[0] & 0x1fu);
    if (!ord || ord > 20u) return;
    if (e[0] & 0x40u)
        for (uint32_t i = 0; i < sizeof(char) * 261u; ++i) lfn[i] = 0;
    uint32_t base = (ord - 1u) * 13u;
    for (uint32_t i = 0; i < 13u; ++i) {
        uint16_t c = le16(e + pos[i]);
        if (c == 0 || c == 0xffffu) { lfn[base + i] = 0; break; }
        lfn[base + i] = c < 128u ? (char)c : '?';
    }
}

static void short_name(char out[13], const uint8_t *e)
{
    uint32_t n = 0, end = 8;
    while (end && e[end - 1] == ' ') --end;
    for (uint32_t i = 0; i < end; ++i) out[n++] = (char)e[i];
    end = 3;
    while (end && e[8 + end - 1] == ' ') --end;
    if (end) out[n++] = '.';
    for (uint32_t i = 0; i < end; ++i) out[n++] = (char)e[8 + i];
    out[n] = 0;
}

static int find_root(struct fat32_fs *fs, const char *name,
                     uint32_t *first, uint32_t *size)
{
    uint32_t cluster = fs->root_cluster;
    char lfn[261];
    lfn[0] = 0;
    while (cluster >= 2u && cluster < 0x0ffffff8u) {
        uint32_t base = cluster_lba(fs, cluster);
        for (uint32_t s = 0; s < fs->sectors_per_cluster; ++s) {
            if (t113_sd_read(base + s, 1, sector) < 0) return -1;
            for (uint32_t off = 0; off < 512u; off += 32u) {
                const uint8_t *e = sector + off;
                if (e[0] == 0) return -1;
                if (e[0] == 0xe5) { lfn[0] = 0; continue; }
                if (e[11] == 0x0f) { lfn_piece(lfn, e); continue; }
                char sn[13]; short_name(sn, e);
                if (!(e[11] & 0x18u) &&
                    ((lfn[0] && name_equal(lfn, name)) || name_equal(sn, name))) {
                    *first = ((uint32_t)le16(e + 20) << 16) | le16(e + 26);
                    *size = le32(e + 28);
                    return 0;
                }
                lfn[0] = 0;
            }
        }
        cluster = next_cluster(fs, cluster);
    }
    return -1;
}

int fat32_load_root(struct fat32_fs *fs, const char *name, void *dst,
                    uint32_t capacity, uint32_t *size_out)
{
    uint32_t cluster, size;
    if (!fs || !name || !dst || ((uintptr_t)dst & 3u) ||
        find_root(fs, name, &cluster, &size) < 0 || !size ||
        ((size + 511u) & ~511u) > capacity)
        return -1;
    uint8_t *out = dst;
    uint32_t left = size;
    while (left && cluster >= 2u && cluster < 0x0ffffff8u) {
        uint32_t sectors = (left + 511u) / 512u;
        if (sectors > fs->sectors_per_cluster) sectors = fs->sectors_per_cluster;
        if (t113_sd_read(cluster_lba(fs, cluster), sectors, out) < 0) return -1;
        uint32_t bytes = sectors * 512u;
        if (bytes > left) bytes = left;
        out += bytes;
        left -= bytes;
        if (left) cluster = next_cluster(fs, cluster);
    }
    if (left) return -1;
    if (size_out) *size_out = size;
    return 0;
}
