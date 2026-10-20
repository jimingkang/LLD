/*
 * FAT32 filesystem on the boot SD card's first FAT32 MBR partition,
 * mounted read/write at /boot.
 *
 * Layered like xv6: bio.c caches 512-byte sectors, this file maps paths to
 * directory entries and file offsets to cluster chains.  An in-memory
 * inode table (fat_inode) stands in for xv6's inode cache: it remembers
 * where each open file's short directory entry lives so its size and first
 * cluster can be written back on close.
 *
 * Supported: long and short names (read and create), subdirectories
 * (read), create/truncate/read/write of regular files.  Not supported:
 * mkdir, unlink, rename, timestamps beyond a fixed creation date.
 */
#include "platform.h"
#include "mutex.h"
#include "fs/bio.h"
#include "fs/vfs.h"
#include "fs/fat32.h"
#include "t113/sd.h"

#define FAT32_MOUNT       "/boot"
#define FAT_NAME_MAX      127u
#define FAT_NINODE        16u
#define FAT_EOC           0x0ffffff8u
#define FAT_EOC_MARK      0x0fffffffu
#define FAT_MASK          0x0fffffffu

#define ATTR_HIDDEN       0x02u
#define ATTR_VOLUME       0x08u
#define ATTR_DIR          0x10u
#define ATTR_ARCHIVE      0x20u
#define ATTR_LFN          0x0fu

#define CASE_LOWER_BASE   0x08u      /* NT byte 12: base name is lowercase */
#define CASE_LOWER_EXT    0x10u
#define FAT_DATE_2026     0x5c21u    /* 2026-01-01, for created entries */

#define FAT_T_DIR         1u         /* same values as minifs/ls */
#define FAT_T_FILE        2u

struct fat_inode {
    uint32_t ref;
    uint32_t dir;          /* 1 for a directory */
    uint32_t first;        /* first cluster, 0 for an empty file */
    uint32_t size;
    uint32_t ent_lba;      /* sector of the short entry, 0 for the root */
    uint32_t ent_off;      /* byte offset of that entry in the sector */
    uint32_t dirty;        /* first/size changed: rewrite the entry */
    uint32_t cur_index;    /* last cluster looked up: index in chain... */
    uint32_t cur_cluster;  /* ...and its number (0 = none) */
};

struct fat_dirent {
    char name[FAT_NAME_MAX + 1u];
    uint8_t attr;
    uint32_t first;
    uint32_t size;
    uint32_t lba;          /* where the short entry lives */
    uint32_t off;
};

struct dir_iter {
    uint32_t cluster;
    uint32_t index;        /* entry index within the cluster */
    uint32_t lfn_ok;
    uint8_t lfn_sum;
    char lfn[FAT_NAME_MAX + 1u];
};

static struct {
    struct mutex lock;
    uint32_t mounted;
    uint32_t part_lba;
    uint32_t fat_lba;
    uint32_t data_lba;
    uint32_t sectors_per_fat;
    uint32_t root_cluster;
    uint32_t clusters;     /* data clusters: valid numbers are 2..clusters+1 */
    uint32_t spc;          /* sectors per cluster */
    uint32_t fats;
    uint32_t fsinfo_lba;
    uint32_t free_hint;
    uint32_t fsinfo_stale;
    struct fat_inode inode[FAT_NINODE];
} fs;

static uint16_t le16(const uint8_t *p)
{
    return (uint16_t)(p[0] | (p[1] << 8));
}

static uint32_t le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static void put16(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8);
}

static void put32(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8);
    p[2] = (uint8_t)(v >> 16); p[3] = (uint8_t)(v >> 24);
}

static void copy(void *d, const void *s, uint32_t n)
{
    uint8_t *dst = d;
    const uint8_t *src = s;
    while (n--) *dst++ = *src++;
}

static void zero(void *d, uint32_t n)
{
    uint8_t *dst = d;
    while (n--) *dst++ = 0;
}

static char upper(char c)
{
    return c >= 'a' && c <= 'z' ? (char)(c - ('a' - 'A')) : c;
}

static char lower(char c)
{
    return c >= 'A' && c <= 'Z' ? (char)(c + ('a' - 'A')) : c;
}

static int name_equal(const char *a, const char *b)
{
    while (*a && *b && upper(*a) == upper(*b)) { ++a; ++b; }
    return !*a && !*b;
}

static uint32_t cluster_lba(uint32_t cluster)
{
    return fs.data_lba + (cluster - 2u) * fs.spc;
}

static int cluster_valid(uint32_t cluster)
{
    return cluster >= 2u && cluster < fs.clusters + 2u;
}

/* ------------------------------------------------------------ FAT */

static uint32_t fat_get(uint32_t cluster)
{
    uint32_t off = cluster * 4u;
    struct buf *b = bread(fs.fat_lba + off / BSIZE);
    if (!b)
        return FAT_EOC_MARK;
    uint32_t v = le32(b->data + (off % BSIZE)) & FAT_MASK;
    brelse(b);
    return v;
}

/* Write an entry into every FAT copy. */
static int fat_set(uint32_t cluster, uint32_t value)
{
    uint32_t off = cluster * 4u;
    for (uint32_t i = 0; i < fs.fats; ++i) {
        struct buf *b = bread(fs.fat_lba + i * fs.sectors_per_fat + off / BSIZE);
        if (!b)
            return -1;
        uint8_t *p = b->data + (off % BSIZE);
        put32(p, (le32(p) & ~FAT_MASK) | (value & FAT_MASK));
        int r = bwrite(b);
        brelse(b);
        if (r < 0)
            return -1;
    }
    return 0;
}

/* Our free-cluster bookkeeping is not kept in FSInfo: mark its counters
 * unknown once, so other systems recompute them. */
static void fsinfo_invalidate(void)
{
    if (!fs.fsinfo_stale || !fs.fsinfo_lba)
        return;
    struct buf *b = bread(fs.fsinfo_lba);
    if (!b)
        return;
    if (le32(b->data) == 0x41615252u && le32(b->data + 484) == 0x61417272u) {
        put32(b->data + 488, 0xffffffffu);
        put32(b->data + 492, 0xffffffffu);
        bwrite(b);
    }
    brelse(b);
    fs.fsinfo_stale = 0;
}

/* Allocate a free cluster, mark it end-of-chain and link it after prev. */
static uint32_t fat_alloc(uint32_t prev)
{
    fsinfo_invalidate();
    for (uint32_t n = 0; n < fs.clusters; ++n) {
        uint32_t c = fs.free_hint + n;
        if (c >= fs.clusters + 2u)
            c -= fs.clusters;
        if (fat_get(c) != 0)
            continue;
        if (fat_set(c, FAT_EOC_MARK) < 0 || (prev && fat_set(prev, c) < 0))
            return 0;
        fs.free_hint = c + 1u < fs.clusters + 2u ? c + 1u : 2u;
        return c;
    }
    t113_uart_puts("fat32: filesystem full\n");
    return 0;
}

static void fat_free_chain(uint32_t c)
{
    while (cluster_valid(c)) {
        uint32_t next = fat_get(c);
        if (fat_set(c, 0) < 0)
            return;
        if (c < fs.free_hint)
            fs.free_hint = c;
        c = next;
    }
}

static int zero_cluster(uint32_t c)
{
    for (uint32_t s = 0; s < fs.spc; ++s) {
        struct buf *b = bget_blank(cluster_lba(c) + s);
        if (!b)
            return -1;
        zero(b->data, BSIZE);
        int r = bwrite(b);
        brelse(b);
        if (r < 0)
            return -1;
    }
    return 0;
}

/* ---------------------------------------------------------- inodes */

static struct fat_inode *iget(uint32_t dir, uint32_t first, uint32_t size,
                              uint32_t lba, uint32_t off)
{
    struct fat_inode *empty = 0;
    for (uint32_t i = 0; i < FAT_NINODE; ++i) {
        struct fat_inode *ip = &fs.inode[i];
        if (ip->ref && ip->ent_lba == lba && ip->ent_off == off) {
            ++ip->ref;
            return ip;
        }
        if (!ip->ref && !empty)
            empty = ip;
    }
    if (!empty)
        return 0;
    empty->ref = 1;
    empty->dir = dir;
    empty->first = first;
    empty->size = size;
    empty->ent_lba = lba;
    empty->ent_off = off;
    empty->dirty = 0;
    empty->cur_cluster = 0;
    return empty;
}

/* Write first cluster and size back into the short directory entry. */
static int iupdate(struct fat_inode *ip)
{
    if (!ip->ent_lba)
        return 0;
    struct buf *b = bread(ip->ent_lba);
    if (!b)
        return -1;
    uint8_t *e = b->data + ip->ent_off;
    put16(e + 20, ip->first >> 16);
    put16(e + 26, ip->first & 0xffffu);
    put32(e + 28, ip->dir ? 0 : ip->size);
    int r = bwrite(b);
    brelse(b);
    if (r == 0)
        ip->dirty = 0;
    return r;
}

/* Cluster number holding chain position index, optionally growing the
 * chain.  Returns 0 past the end (or when allocation fails). */
static uint32_t ibmap(struct fat_inode *ip, uint32_t index, int alloc)
{
    if (!ip->first) {
        if (!alloc || !(ip->first = fat_alloc(0)))
            return 0;
        ip->dirty = 1;
        ip->cur_cluster = 0;
    }
    uint32_t c = ip->first, i = 0;
    if (ip->cur_cluster && ip->cur_index <= index) {
        c = ip->cur_cluster;
        i = ip->cur_index;
    }
    while (i < index) {
        uint32_t next = fat_get(c);
        if (!cluster_valid(next)) {
            if (next < FAT_EOC || !alloc || !(next = fat_alloc(c)))
                return 0;
        }
        c = next;
        ++i;
    }
    ip->cur_index = index;
    ip->cur_cluster = c;
    return c;
}

/* ------------------------------------------------------ directories */

static uint8_t short_checksum(const uint8_t *name11)
{
    uint8_t sum = 0;
    for (uint32_t i = 0; i < 11u; ++i)
        sum = (uint8_t)(((sum & 1u) << 7) + (sum >> 1) + name11[i]);
    return sum;
}

static const uint8_t lfn_pos[13] = { 1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30 };

static void lfn_piece(struct dir_iter *it, const uint8_t *e)
{
    uint32_t ord = e[0] & 0x1fu;
    if (e[0] & 0x40u) {
        zero(it->lfn, sizeof(it->lfn));
        it->lfn_ok = 1;
        it->lfn_sum = e[13];
    } else if (!it->lfn_ok || e[13] != it->lfn_sum) {
        it->lfn_ok = 0;
        return;
    }
    if (!ord || ord * 13u > FAT_NAME_MAX) {
        it->lfn_ok = 0;
        return;
    }
    uint32_t base = (ord - 1u) * 13u;
    for (uint32_t i = 0; i < 13u; ++i) {
        uint16_t c = le16(e + lfn_pos[i]);
        if (c == 0 || c == 0xffffu)
            break;
        it->lfn[base + i] = c < 128u ? (char)c : '?';
    }
}

static void short_name(char *out, const uint8_t *e)
{
    uint32_t n = 0, end = 8;
    while (end && e[end - 1u] == ' ') --end;
    for (uint32_t i = 0; i < end; ++i) {
        char c = (char)(i == 0 && e[0] == 0x05 ? 0xe5 : e[i]);
        out[n++] = (e[12] & CASE_LOWER_BASE) ? lower(c) : c;
    }
    end = 3;
    while (end && e[8 + end - 1u] == ' ') --end;
    if (end) out[n++] = '.';
    for (uint32_t i = 0; i < end; ++i)
        out[n++] = (e[12] & CASE_LOWER_EXT) ? lower((char)e[8 + i])
                                             : (char)e[8 + i];
    out[n] = 0;
}

static void dir_open(struct dir_iter *it, uint32_t cluster)
{
    it->cluster = cluster;
    it->index = 0;
    it->lfn_ok = 0;
}

/* Next live entry (file or directory).  1 = found, 0 = end, -1 = error. */
static int dir_next(struct dir_iter *it, struct fat_dirent *d)
{
    uint32_t per_cluster = fs.spc * (BSIZE / 32u);
    for (;;) {
        if (!cluster_valid(it->cluster))
            return 0;
        if (it->index >= per_cluster) {
            it->cluster = fat_get(it->cluster);
            it->index = 0;
            continue;
        }
        uint32_t lba = cluster_lba(it->cluster) + it->index / (BSIZE / 32u);
        uint32_t off = (it->index % (BSIZE / 32u)) * 32u;
        uint8_t e[32];
        struct buf *b = bread(lba);
        if (!b)
            return -1;
        copy(e, b->data + off, sizeof(e));
        brelse(b);
        ++it->index;
        if (e[0] == 0)
            return 0;
        if (e[0] == 0xe5u) {
            it->lfn_ok = 0;
            continue;
        }
        if ((e[11] & 0x3fu) == ATTR_LFN) {
            lfn_piece(it, e);
            continue;
        }
        if (e[11] & ATTR_VOLUME) {
            it->lfn_ok = 0;
            continue;
        }
        if (it->lfn_ok && it->lfn_sum == short_checksum(e) && it->lfn[0]) {
            copy(d->name, it->lfn, sizeof(d->name));
            d->name[FAT_NAME_MAX] = 0;
        } else {
            short_name(d->name, e);
        }
        it->lfn_ok = 0;
        d->attr = e[11];
        d->first = ((uint32_t)le16(e + 20) << 16) | le16(e + 26);
        d->size = le32(e + 28);
        d->lba = lba;
        d->off = off;
        return 1;
    }
}

static int dir_find(uint32_t cluster, const char *name, uint32_t len,
                    struct fat_dirent *d)
{
    char want[FAT_NAME_MAX + 1u];
    struct dir_iter it;
    if (!len || len > FAT_NAME_MAX)
        return -1;
    copy(want, name, len);
    want[len] = 0;
    dir_open(&it, cluster);
    int r;
    while ((r = dir_next(&it, d)) > 0)
        if (name_equal(d->name, want))
            return 0;
    return -1;
}

/* Path below the mount point, without leading slashes. */
static const char *mount_relative(const char *path)
{
    const char *m = FAT32_MOUNT;
    while (*m && *path == *m) { ++m; ++path; }
    if (*m || (*path && *path != '/'))
        return 0;
    while (*path == '/') ++path;
    return path;
}

/*
 * Resolve path.  With parent set, stop before the last component and
 * return it in *last / *last_len.  The result describes a directory entry;
 * the root is reported with lba 0 and ATTR_DIR.
 */
static int resolve(const char *path, struct fat_dirent *d, int parent,
                   const char **last, uint32_t *last_len)
{
    const char *p = mount_relative(path);
    if (!p)
        return -1;
    d->attr = ATTR_DIR;
    d->first = fs.root_cluster;
    d->size = 0;
    d->lba = 0;
    d->off = 0;
    d->name[0] = 0;
    for (;;) {
        const char *start = p;
        while (*p && *p != '/') ++p;
        uint32_t len = (uint32_t)(p - start);
        while (*p == '/') ++p;
        if (!len)
            return parent ? -1 : 0;
        if (parent && !*p) {
            *last = start;
            *last_len = len;
            return (d->attr & ATTR_DIR) ? 0 : -1;
        }
        if (!(d->attr & ATTR_DIR))
            return -1;
        uint32_t dir_cluster = d->first ? d->first : fs.root_cluster;
        if (dir_find(dir_cluster, start, len, d) < 0)
            return -1;
        if ((d->attr & ATTR_DIR) && !d->first)
            d->first = fs.root_cluster;   /* ".." of a top-level dir */
    }
}

/* ------------------------------------------------------- create */

static int short_char_ok(char c)
{
    if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'))
        return 1;
    const char *special = "!#$%&'()-@^_`{}~";
    while (*special)
        if (*special++ == c)
            return 1;
    return 0;
}

static int long_char_ok(char c)
{
    const char *bad = "\\/:*?\"<>|";
    if ((uint8_t)c < 32u)
        return 0;
    while (*bad)
        if (*bad++ == c)
            return 0;
    return 1;
}

/* Fill an 8.3 entry name.  Returns 1 when the name is exactly
 * representable (no long entries needed), setting the NT case flags. */
static int fit_short(const char *name, uint32_t len, uint8_t sn[11],
                     uint8_t *case_flags)
{
    int dot = -1;
    for (uint32_t i = 0; i < len; ++i)
        if (name[i] == '.') {
            if (dot >= 0)
                return 0;
            dot = (int)i;
        }
    uint32_t base_len = dot < 0 ? len : (uint32_t)dot;
    uint32_t ext_len = dot < 0 ? 0 : len - (uint32_t)dot - 1u;
    if (!base_len || base_len > 8u || ext_len > 3u || (dot >= 0 && !ext_len))
        return 0;
    uint32_t has_lower[2] = { 0, 0 }, has_upper[2] = { 0, 0 };
    for (uint32_t i = 0; i < 11u; ++i) sn[i] = ' ';
    for (uint32_t i = 0; i < len; ++i) {
        if ((int)i == dot)
            continue;
        uint32_t part = dot >= 0 && (int)i > dot;
        char c = name[i];
        if (c >= 'a' && c <= 'z') has_lower[part] = 1;
        if (c >= 'A' && c <= 'Z') has_upper[part] = 1;
        c = upper(c);
        if (!short_char_ok(c))
            return 0;
        sn[part ? 8u + (i - (uint32_t)dot - 1u) : i] = (uint8_t)c;
    }
    if ((has_lower[0] && has_upper[0]) || (has_lower[1] && has_upper[1]))
        return 0;
    *case_flags = (uint8_t)((has_lower[0] ? CASE_LOWER_BASE : 0) |
                            (has_lower[1] ? CASE_LOWER_EXT : 0));
    return 1;
}

static int short_exists(uint32_t dir_cluster, const uint8_t sn[11])
{
    uint32_t per_cluster = fs.spc * (BSIZE / 32u);
    for (uint32_t c = dir_cluster; cluster_valid(c); c = fat_get(c)) {
        for (uint32_t i = 0; i < per_cluster; ++i) {
            struct buf *b = bread(cluster_lba(c) + i / (BSIZE / 32u));
            if (!b)
                return 1;
            const uint8_t *e = b->data + (i % (BSIZE / 32u)) * 32u;
            int end = e[0] == 0;
            int same = e[0] != 0xe5u && (e[11] & 0x3fu) != ATTR_LFN;
            for (uint32_t k = 0; same && k < 11u; ++k)
                if (e[k] != sn[k]) same = 0;
            brelse(b);
            if (end)
                return 0;
            if (same)
                return 1;
        }
    }
    return 0;
}

/* "NAME~N.EXT" basis for a long name. */
static int make_alias(uint32_t dir_cluster, const char *name, uint32_t len,
                      uint8_t sn[11])
{
    int dot = -1;
    for (uint32_t i = 0; i < len; ++i)
        if (name[i] == '.') dot = (int)i;
    if (dot == 0) dot = -1;           /* ".profile" has no extension */
    char base[8];
    uint32_t nb = 0;
    for (uint32_t i = 0; i < len && (dot < 0 || (int)i < dot) && nb < 8u; ++i) {
        char c = upper(name[i]);
        if (c == '.' || c == ' ') continue;
        base[nb++] = short_char_ok(c) ? c : '_';
    }
    if (!nb) base[nb++] = '_';
    for (uint32_t i = 0; i < 11u; ++i) sn[i] = ' ';
    if (dot >= 0)
        for (uint32_t i = (uint32_t)dot + 1u, n = 0; i < len && n < 3u; ++i) {
            char c = upper(name[i]);
            if (c == ' ') continue;
            sn[8 + n++] = (uint8_t)(short_char_ok(c) ? c : '_');
        }
    for (uint32_t tail = 1; tail < 1000u; ++tail) {
        char digits[4];
        uint32_t nd = 0;
        for (uint32_t t = tail; t; t /= 10u) digits[nd++] = (char)('0' + t % 10u);
        uint32_t keep = nb;
        if (keep > 7u - nd) keep = 7u - nd;
        uint32_t k = 0;
        for (; k < keep; ++k) sn[k] = (uint8_t)base[k];
        sn[k++] = '~';
        while (nd) sn[k++] = (uint8_t)digits[--nd];
        while (k < 8u) sn[k++] = ' ';
        if (!short_exists(dir_cluster, sn))
            return 0;
    }
    return -1;
}

/* Find need consecutive free entry slots, growing the directory. */
static int find_slots(uint32_t dir_cluster, uint32_t need,
                      uint32_t lba[], uint32_t off[])
{
    uint32_t per_cluster = fs.spc * (BSIZE / 32u);
    uint32_t run = 0, c = dir_cluster, last = dir_cluster;
    while (run < need) {
        if (!cluster_valid(c)) {
            if (!(c = fat_alloc(last)) || zero_cluster(c) < 0)
                return -1;
        }
        for (uint32_t i = 0; i < per_cluster && run < need; ++i) {
            uint32_t sector = cluster_lba(c) + i / (BSIZE / 32u);
            uint32_t o = (i % (BSIZE / 32u)) * 32u;
            struct buf *b = bread(sector);
            if (!b)
                return -1;
            uint8_t first = b->data[o];
            brelse(b);
            if (first == 0 || first == 0xe5u) {
                lba[run] = sector;
                off[run] = o;
                ++run;
            } else {
                run = 0;
            }
        }
        last = c;
        c = fat_get(c);
    }
    return 0;
}

static int write_entry(uint32_t lba, uint32_t off, const uint8_t e[32])
{
    struct buf *b = bread(lba);
    if (!b)
        return -1;
    copy(b->data + off, e, 32);
    int r = bwrite(b);
    brelse(b);
    return r;
}

static int create_entry(uint32_t dir_cluster, const char *name, uint32_t len,
                        struct fat_dirent *d)
{
    uint8_t sn[11], case_flags = 0;
    for (uint32_t i = 0; i < len; ++i)
        if (!long_char_ok(name[i]))
            return -1;
    if (len > FAT_NAME_MAX || (name[0] == '.' && (len == 1u ||
                               (len == 2u && name[1] == '.'))))
        return -1;
    int need_lfn = !fit_short(name, len, sn, &case_flags);
    if (need_lfn && make_alias(dir_cluster, name, len, sn) < 0)
        return -1;
    if (sn[0] == 0xe5u)
        sn[0] = 0x05;

    uint32_t pieces = need_lfn ? (len + 12u) / 13u : 0;
    uint32_t lba[FAT_NAME_MAX / 13u + 2u], off[FAT_NAME_MAX / 13u + 2u];
    if (find_slots(dir_cluster, pieces + 1u, lba, off) < 0)
        return -1;

    uint8_t e[32];
    uint8_t sum = short_checksum(sn);
    for (uint32_t s = 0; s < pieces; ++s) {
        uint32_t ord = pieces - s;     /* last piece is written first */
        zero(e, sizeof(e));
        e[0] = (uint8_t)(ord | (s == 0 ? 0x40u : 0));
        e[11] = ATTR_LFN;
        e[13] = sum;
        for (uint32_t i = 0; i < 13u; ++i) {
            uint32_t at = (ord - 1u) * 13u + i;
            uint32_t ch = at < len ? (uint8_t)name[at] : at == len ? 0 : 0xffffu;
            put16(e + lfn_pos[i], ch);
        }
        if (write_entry(lba[s], off[s], e) < 0)
            return -1;
    }
    zero(e, sizeof(e));
    copy(e, sn, 11);
    e[11] = ATTR_ARCHIVE;
    e[12] = case_flags;
    put16(e + 16, FAT_DATE_2026);      /* creation date */
    put16(e + 18, FAT_DATE_2026);      /* access date */
    put16(e + 24, FAT_DATE_2026);      /* write date */
    if (write_entry(lba[pieces], off[pieces], e) < 0)
        return -1;

    copy(d->name, name, len);
    d->name[len] = 0;
    d->attr = ATTR_ARCHIVE;
    d->first = 0;
    d->size = 0;
    d->lba = lba[pieces];
    d->off = off[pieces];
    return 0;
}

/* ------------------------------------------------------ native VFS ops */

static const struct super_operations fat32_sops;
static const struct inode_operations fat32_iops;
static const struct file_operations fat32_file_fops;
static const struct file_operations fat32_dir_fops;

static int fat32_bind(struct dentry *dentry, struct fat_inode *ip)
{
    if (!ip)
        return -1;
    const struct file_operations *fops = ip->dir ? &fat32_dir_fops
                                                 : &fat32_file_fops;
    return t113_vfs_bind_inode(dentry, (uint32_t)(uintptr_t)ip,
                               ip->dir ? 0 : ip->size,
                               ip->dir ? FAT_T_DIR : FAT_T_FILE,
                               0, ip, &fat32_iops, fops);
}

static int fat32_lookup(struct inode *directory, struct dentry *child)
{
    (void)directory;
    struct fat_dirent d;
    mutex_lock(&fs.lock);
    struct fat_inode *ip = 0;
    if (resolve(child->d_path, &d, 0, 0, 0) == 0)
        ip = iget((d.attr & ATTR_DIR) != 0, d.first, d.size, d.lba, d.off);
    mutex_unlock(&fs.lock);
    return fat32_bind(child, ip);
}

static int fat32_create(struct inode *directory, struct dentry *child)
{
    (void)directory;
    struct fat_dirent d;
    const char *name = 0;
    uint32_t len = 0;
    struct fat_inode *ip = 0;
    mutex_lock(&fs.lock);
    if (resolve(child->d_path, &d, 1, &name, &len) == 0) {
        uint32_t dir_cluster = d.first ? d.first : fs.root_cluster;
        if (dir_find(dir_cluster, name, len, &d) < 0 &&
            create_entry(dir_cluster, name, len, &d) == 0)
            ip = iget(0, 0, 0, d.lba, d.off);
    }
    mutex_unlock(&fs.lock);
    return fat32_bind(child, ip);
}

static int fat32_read(struct file *file, void *destination, uint32_t count)
{
    struct fat_inode *ip = file && file->f_inode
                         ? file->f_inode->i_private : 0;
    uint32_t offset = file ? file->f_pos : 0;
    if (!ip || ip->dir || !destination)
        return -1;
    mutex_lock(&fs.lock);
    if (offset >= ip->size) {
        mutex_unlock(&fs.lock);
        return 0;
    }
    if (count > ip->size - offset)
        count = ip->size - offset;
    uint32_t cbytes = fs.spc * BSIZE, done = 0;
    uint8_t *dst = destination;
    while (done < count) {
        uint32_t pos = offset + done;
        uint32_t c = ibmap(ip, pos / cbytes, 0);
        if (!c)
            break;
        uint32_t in_cluster = pos % cbytes;
        uint32_t lba = cluster_lba(c) + in_cluster / BSIZE;
        uint32_t in_sector = pos % BSIZE;
        uint32_t left = count - done;
        if (!in_sector && left >= BSIZE && !(((uintptr_t)(dst + done)) & 3u)) {
            /* Whole sectors straight into the caller (cache is write-through,
             * so the card is never older than the cache). */
            uint32_t n = (cbytes - in_cluster) / BSIZE;
            if (n > left / BSIZE)
                n = left / BSIZE;
            if (t113_sd_read(lba, n, dst + done) < 0)
                break;
            done += n * BSIZE;
            continue;
        }
        struct buf *b = bread(lba);
        if (!b)
            break;
        uint32_t n = BSIZE - in_sector;
        if (n > left)
            n = left;
        copy(dst + done, b->data + in_sector, n);
        brelse(b);
        done += n;
    }
    mutex_unlock(&fs.lock);
    return done ? (int)done : -1;
}

static int fat32_write(struct file *file, const void *source, uint32_t count)
{
    struct fat_inode *ip = file && file->f_inode
                         ? file->f_inode->i_private : 0;
    uint32_t offset = file ? file->f_pos : 0;
    if (!ip || ip->dir || !source)
        return -1;
    mutex_lock(&fs.lock);
    if (offset > ip->size) {            /* no sparse files */
        mutex_unlock(&fs.lock);
        return -1;
    }
    uint32_t cbytes = fs.spc * BSIZE, done = 0;
    const uint8_t *src = source;
    while (done < count) {
        uint32_t pos = offset + done;
        uint32_t c = ibmap(ip, pos / cbytes, 1);
        if (!c)
            break;
        uint32_t lba = cluster_lba(c) + (pos % cbytes) / BSIZE;
        uint32_t in_sector = pos % BSIZE;
        uint32_t n = BSIZE - in_sector;
        if (n > count - done)
            n = count - done;
        struct buf *b = (!in_sector && n == BSIZE) ? bget_blank(lba)
                                                   : bread(lba);
        if (!b)
            break;
        copy(b->data + in_sector, src + done, n);
        int r = bwrite(b);
        brelse(b);
        if (r < 0)
            break;
        done += n;
    }
    if (offset + done > ip->size) {
        ip->size = offset + done;
        ip->dirty = 1;
    }
    mutex_unlock(&fs.lock);
    return done ? (int)done : -1;
}

static int fat32_truncate(struct inode *inode)
{
    struct fat_inode *ip = inode ? inode->i_private : 0;
    if (!ip || ip->dir)
        return -1;
    mutex_lock(&fs.lock);
    uint32_t first = ip->first;
    ip->first = 0;
    ip->size = 0;
    ip->cur_cluster = 0;
    int r = iupdate(ip);               /* entry first, then free the chain */
    if (r == 0)
        fat_free_chain(first);
    mutex_unlock(&fs.lock);
    if (r == 0)
        inode->i_size = 0;
    return r;
}

static void fat32_evict_inode(struct inode *inode)
{
    struct fat_inode *ip = inode ? inode->i_private : 0;
    if (!ip)
        return;
    mutex_lock(&fs.lock);
    if (ip->dirty && iupdate(ip) < 0)
        t113_uart_puts("fat32: cannot update directory entry\n");
    if (ip->ref)
        --ip->ref;
    mutex_unlock(&fs.lock);
}

static int fat32_readdir(struct inode *inode, const char *path, uint32_t index,
                         struct vfs_dirent *entry)
{
    (void)inode;
    struct fat_dirent d;
    struct dir_iter it;
    mutex_lock(&fs.lock);
    if (resolve(path, &d, 0, 0, 0) < 0 || !(d.attr & ATTR_DIR)) {
        mutex_unlock(&fs.lock);
        return -1;
    }
    dir_open(&it, d.first ? d.first : fs.root_cluster);
    uint32_t seen = 0;
    int r;
    while ((r = dir_next(&it, &d)) > 0) {
        if ((d.attr & ATTR_HIDDEN) || (d.name[0] == '.' &&
            (!d.name[1] || (d.name[1] == '.' && !d.name[2]))))
            continue;
        if (seen++ != index)
            continue;
        entry->id = d.first;
        entry->type = (d.attr & ATTR_DIR) ? FAT_T_DIR : FAT_T_FILE;
        entry->size = (d.attr & ATTR_DIR) ? 0 : d.size;
        uint32_t i = 0;
        for (; i + 1u < sizeof(entry->name) && d.name[i]; ++i)
            entry->name[i] = d.name[i];
        entry->name[i] = 0;
        mutex_unlock(&fs.lock);
        return 1;
    }
    mutex_unlock(&fs.lock);
    return r < 0 ? -1 : 0;
}

static const struct super_operations fat32_sops = {
    .evict_inode = fat32_evict_inode,
};

static const struct inode_operations fat32_iops = {
    .lookup = fat32_lookup,
    .create = fat32_create,
    .truncate = fat32_truncate,
};

static const struct file_operations fat32_file_fops = {
    .read = fat32_read,
    .write = fat32_write,
};

static const struct file_operations fat32_dir_fops = {
    .readdir = fat32_readdir,
};

static int is_fat32_type(uint8_t type)
{
    return type == 0x0bu || type == 0x0cu || type == 0x1bu || type == 0x1cu;
}

int t113_fat32_mount_vfs(void)
{
    mutex_init(&fs.lock);
    binit();
    struct buf *b = bread(0);
    if (!b)
        return -1;
    uint32_t part = 0;
    if (b->data[510] == 0x55 && b->data[511] == 0xaa)
        for (uint32_t i = 0; i < 4u; ++i) {
            const uint8_t *e = b->data + 446u + i * 16u;
            if (is_fat32_type(e[4])) {
                part = le32(e + 8);
                break;
            }
        }
    brelse(b);
    if (!part || !(b = bread(part)))
        return -1;
    const uint8_t *s = b->data;
    int ok = s[510] == 0x55 && s[511] == 0xaa && le16(s + 11) == BSIZE &&
             s[13] && s[16] && le16(s + 17) == 0 && le32(s + 36) &&
             le32(s + 32);
    if (ok) {
        fs.part_lba = part;
        fs.spc = s[13];
        fs.fats = s[16];
        fs.sectors_per_fat = le32(s + 36);
        fs.root_cluster = le32(s + 44);
        fs.fat_lba = part + le16(s + 14);
        fs.data_lba = fs.fat_lba + fs.fats * fs.sectors_per_fat;
        fs.fsinfo_lba = le16(s + 48) ? part + le16(s + 48) : 0;
        uint32_t total = le32(s + 32);
        uint32_t used = fs.data_lba - part;
        fs.clusters = total > used ? (total - used) / fs.spc : 0;
        /* The FAT itself bounds the cluster numbers it can describe. */
        if (fs.clusters > fs.sectors_per_fat * (BSIZE / 4u) - 2u)
            fs.clusters = fs.sectors_per_fat * (BSIZE / 4u) - 2u;
        fs.free_hint = 2;
        fs.fsinfo_stale = 1;
        ok = cluster_valid(fs.root_cluster);
    }
    brelse(b);
    if (!ok)
        return -1;
    for (uint32_t i = 0; i < FAT_NINODE; ++i)
        fs.inode[i].ref = 0;
    if (t113_vfs_mount_fs(FAT32_MOUNT, 0x4d44u, &fs, &fat32_sops,
                          &fat32_iops, &fat32_dir_fops) < 0)
        return -1;
    fs.mounted = 1;
    t113_uart_puts("fat32: /boot mounted rw, partition lba=");
    t113_uart_puthex(part);
    t113_uart_puts(" clusters=");
    t113_uart_puthex(fs.clusters);
    t113_uart_puts(" cluster-bytes=");
    t113_uart_puthex(fs.spc * BSIZE);
    t113_uart_putc('\n');
    return 0;
}
