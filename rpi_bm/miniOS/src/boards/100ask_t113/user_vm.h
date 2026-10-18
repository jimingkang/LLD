#ifndef MINIOS_100ASK_T113_USER_VM_H
#define MINIOS_100ASK_T113_USER_VM_H

#include <stdint.h>

#define USER_CODE_VA   0x00100000u
#define USER_STACK_VA  0x008ff000u
#define USER_STACK_TOP 0x00900000u

struct t113_user_vm {
    uint32_t *l1;
    uint32_t *code_l2;
    uint32_t *stack_l2;
    void *code_page;
    void *stack_page;
};

struct t113_user_vm *t113_user_vm_create(const void *image,
                                         uint32_t image_size);
void t113_switch_user_vm(struct t113_user_vm *vm);
void t113_switch_kernel_vm(void);

#endif
