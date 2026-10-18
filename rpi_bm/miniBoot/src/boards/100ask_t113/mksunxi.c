/* Minimal Allwinner Boot0 checksum fixer, based on SyterKit v0.3.0.0. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    uint32_t instruction;
    uint8_t magic[8];
    uint32_t checksum;
    uint32_t length;
} boot_head_prefix_t;

static unsigned int align_up(unsigned int value, unsigned int alignment)
{
    return (value + alignment - 1u) & ~(alignment - 1u);
}

int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr, "usage: %s <boot0.bin> <512|8192>\n", argv[0]);
        return 1;
    }

    unsigned int padding = (unsigned int)strtoul(argv[2], 0, 0);
    if (padding != 512 && padding != 8192)
        return 1;

    FILE *file = fopen(argv[1], "r+b");
    if (!file)
        return 1;
    fseek(file, 0, SEEK_END);
    long raw_size = ftell(file);
    rewind(file);
    if (raw_size < (long)sizeof(boot_head_prefix_t)) {
        fclose(file);
        return 1;
    }

    unsigned int size = align_up((unsigned int)raw_size, padding);
    uint8_t *buffer = calloc(1, size);
    if (!buffer || fread(buffer, 1, (size_t)raw_size, file) != (size_t)raw_size) {
        free(buffer);
        fclose(file);
        return 1;
    }

    boot_head_prefix_t *head = (boot_head_prefix_t *)buffer;
    head->length = size;
    head->checksum = 0x5f0a6c39u;
    uint32_t sum = 0;
    for (unsigned int i = 0; i < size / sizeof(uint32_t); ++i)
        sum += ((uint32_t *)buffer)[i];
    head->checksum = sum;

    rewind(file);
    int ok = fwrite(buffer, 1, size, file) == size;
    fclose(file);
    free(buffer);
    return ok ? 0 : 1;
}
