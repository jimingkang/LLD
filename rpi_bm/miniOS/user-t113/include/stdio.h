#ifndef MINIOS_STDIO_H
#define MINIOS_STDIO_H

#include <stdarg.h>
#include <stddef.h>

#define EOF (-1)

int putchar(int character);
int puts(const char *text);
int printf(const char *format, ...);
int vprintf(const char *format, va_list args);
int snprintf(char *buffer, size_t size, const char *format, ...);
int vsnprintf(char *buffer, size_t size, const char *format, va_list args);

#endif
