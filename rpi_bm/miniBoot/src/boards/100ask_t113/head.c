/* Boot0/eGON header layout derived from SyterKit v0.3.0.0. */
#include <stdint.h>

typedef struct {
    uint32_t jump_instruction;
    uint8_t magic[8];
    uint32_t checksum;
    uint32_t length;
    uint32_t pub_head_size;
    uint8_t pub_head_version[4];
    uint32_t return_address;
    uint32_t run_address;
    uint32_t boot_cpu;
    uint8_t platform[8];
} boot0_header_t;

#define HEADER_WORDS ((sizeof(boot0_header_t) + sizeof(uint32_t)) / sizeof(uint32_t) + 1u)
#define ARM_B_ALWAYS(offset_words) (0xea000000u | (offset_words))
#define BOOT0_STAMP 0x12345678u

extern uint32_t __spl_size[];
extern uint32_t __code_start_address[];

__attribute__((section(".boot0_head"), used))
const boot0_header_t t113_boot_header = {
    .jump_instruction = ARM_B_ALWAYS(HEADER_WORDS),
    .magic = {'e', 'G', 'O', 'N', '.', 'B', 'T', '0'},
    .checksum = BOOT0_STAMP,
    .length = (uint32_t)__spl_size,
    .pub_head_size = sizeof(boot0_header_t),
    .pub_head_version = {'3', '0', '0', '0'},
    .return_address = (uint32_t)__code_start_address,
    .run_address = (uint32_t)__code_start_address,
    .boot_cpu = 0,
    .platform = {0, 0, '3', '.', '0', '.', '0', 0},
};
