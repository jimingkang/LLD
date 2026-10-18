#pragma once

#include "common.h"

void delay(u64 ticks);
void put32(u64 address, u32 value);
u32 get32(u64 address);
bool str_eq(char *a, char *b);
int strcat(char *dst, char *src);
int strcpy(char *dst, char *src);
int strlen(char *s);

extern unsigned long get_el ( void );
u64 get_elr_el1(void);
u64 get_sp_el0(void);

extern unsigned long get_pgd();
