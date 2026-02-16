#pragma once

#include "common.h"

void delay(u64 ticks);
void put32(u64 address, u32 value);
u32 get32(u64 address);

// String functions
bool str_eq(char *a, char *b);
int strcat(char *dst, char *src);
int strcpy(char *dst, char *src);
char* strncpy(char* dest, const char* src, int n);
int strlen(char *s);
void* memset(void* ptr, int value, int num);
