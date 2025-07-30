#ifndef _LIB_H
#define _LIB_H

#include "stdint.h"

void delay(uint64_t value);
void out_word(uint64_t addr, uint32_t value);
uint32_t in_word(uint64_t addr);

void mem_set(void *dst, int value, unsigned int size);
void mem_cpy(void *dst, void *src, unsigned int size);
void mem_move(void *dst, void *src, unsigned int size);
int mem_cmp(void *src1, void *src2, unsigned int size);
unsigned char get_el(void);

#endif