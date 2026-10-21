/*
 * mkbootpack: build the miniOS SD boot pack (see bootpack.h).
 *   mkbootpack OUT NAME=FILE@LOADADDR [NAME=FILE@LOADADDR ...]
 * e.g. mkbootpack bootpack.bin kernel=minios-kernel.bin@0x40200000
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include "../src/boards/100ask_t113/bootpack.h"

static uint8_t *slurp(const char *path, uint32_t *len)
{
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); exit(1); }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    rewind(f);
    uint8_t *b = malloc(n ? (size_t)n : 1);
    if (!b || fread(b, 1, (size_t)n, f) != (size_t)n) { perror(path); exit(1); }
    fclose(f);
    *len = (uint32_t)n;
    return b;
}

int main(int argc, char **argv)
{
    if (argc < 3 || argc - 2 > (int)BOOTPACK_MAX_ENTRIES) {
        fprintf(stderr, "usage: %s OUT NAME=FILE@LOADADDR ... (max %u)\n",
                argv[0], BOOTPACK_MAX_ENTRIES);
        return 1;
    }
    struct bootpack_header h;
    memset(&h, 0, sizeof h);
    h.magic = BOOTPACK_MAGIC;
    h.version = BOOTPACK_VERSION;

    uint8_t *data[BOOTPACK_MAX_ENTRIES];
    uint32_t off = 512;
    for (int i = 2; i < argc; ++i) {
        char *spec = strdup(argv[i]);
        char *eq = strchr(spec, '='), *at = strrchr(spec, '@');
        if (!eq || !at || at < eq) { fprintf(stderr, "bad spec %s\n", argv[i]); return 1; }
        *eq = *at = 0;
        struct bootpack_entry *e = &h.entry[h.count];
        if (strlen(spec) >= BOOTPACK_NAME_LEN) { fprintf(stderr, "name too long: %s\n", spec); return 1; }
        strncpy(e->name, spec, BOOTPACK_NAME_LEN - 1);
        data[h.count] = slurp(eq + 1, &e->size);
        e->load_addr = (uint32_t)strtoul(at + 1, 0, 0);
        if (e->load_addr & 3u) { fprintf(stderr, "%s: load addr not 4-byte aligned\n", spec); return 1; }
        if (strcmp(e->name, "kernel") ? (e->load_addr < BOOTPACK_AUX_BASE ||
                                         e->load_addr + e->size > BOOTPACK_AUX_END)
                                      : e->load_addr != BOOTPACK_KERNEL_ADDR) {
            fprintf(stderr, "%s: load range %#x+%u outside allowed window "
                    "(kernel @%#x, others in [%#x,%#x))\n", spec, e->load_addr, e->size,
                    BOOTPACK_KERNEL_ADDR, BOOTPACK_AUX_BASE, BOOTPACK_AUX_END);
            return 1;
        }
        e->offset = off;
        e->crc32 = bootpack_crc32(0, data[h.count], e->size);
        off += (e->size + 511u) & ~511u;
        printf("  %-15s %7u bytes  @%#010x  crc %08x\n", e->name, e->size, e->load_addr, e->crc32);
        h.count++;
    }
    h.total_size = off;
    if (off > BOOTPACK_MAX_SIZE) {
        fprintf(stderr, "bootpack %u bytes > %u (would overlap 1 MiB partition start)\n",
                off, BOOTPACK_MAX_SIZE);
        return 1;
    }
    h.header_crc32 = bootpack_crc32(0, &h, (uint32_t)offsetof(struct bootpack_header, header_crc32));

    uint8_t *img = calloc(1, off);
    memcpy(img, &h, sizeof h);
    for (uint32_t i = 0; i < h.count; ++i)
        memcpy(img + h.entry[i].offset, data[i], h.entry[i].size);
    FILE *o = fopen(argv[1], "wb");
    if (!o || fwrite(img, 1, off, o) != off) { perror(argv[1]); return 1; }
    fclose(o);
    printf("bootpack %s: %u entries, %u bytes (SD offset %u KiB)\n",
           argv[1], h.count, off, BOOTPACK_SD_OFFSET / 1024u);
    return 0;
}
