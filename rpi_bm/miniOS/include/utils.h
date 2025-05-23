#pragma once

#include "common.h"

void delay(u64 ticks);
void put32(u64 address, u32 value);
u32 get32(u64 address);

extern unsigned long get_el ( void );
extern void set_pgd(unsigned long pgd);
extern unsigned long get_pgd();
