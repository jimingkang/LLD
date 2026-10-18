#ifndef MINIOS_100ASK_T113_USER_VM_H
#define MINIOS_100ASK_T113_USER_VM_H

#include <stdint.h>

#define USER_CODE_VA   0x00100000u
#define USER_STACK_VA  0x008ff000u
#define USER_STACK_TOP 0x00900000u

#define T113_MAX_USER_L2    8u
#define T113_MAX_USER_PAGES 32u

struct t113_user_page {
    uint32_t va;
    void *pa;
    uint32_t writable;
    uint32_t executable;
};

struct t113_user_vm {
    uint32_t *l1;
    uint32_t *l2[T113_MAX_USER_L2];
    uint32_t l2_index[T113_MAX_USER_L2];
    uint32_t l2_count;
    struct t113_user_page pages[T113_MAX_USER_PAGES];
    uint32_t page_count;
};

struct t113_user_vm *t113_user_vm_create_elf(const void *image,
                                             uint32_t image_size,
                                             uint32_t *entry);
struct t113_user_vm *t113_user_vm_clone(const struct t113_user_vm *source);
void t113_switch_user_vm(struct t113_user_vm *vm);
void t113_switch_kernel_vm(void);

#endif
