#ifndef MINIOS_STDLIB_H
#define MINIOS_STDLIB_H

#include <stddef.h>

void exit(int status) __attribute__((noreturn));
void *malloc(size_t size);
void free(void *pointer);
void *calloc(size_t count, size_t size);
void *realloc(void *pointer, size_t size);
int abs(int value);
long labs(long value);
int atoi(const char *text);
long atol(const char *text);
long strtol(const char *text, char **end, int base);
unsigned long strtoul(const char *text, char **end, int base);

#endif
