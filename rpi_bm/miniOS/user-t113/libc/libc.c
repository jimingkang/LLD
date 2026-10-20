#include <stdarg.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int __sys_write(int fd, const void *buffer, size_t count);
int __sys_getpid(void);
int __sys_yield(void);
int __sys_fork(void);
int __sys_vfork(void);
int __sys_sleep(unsigned int seconds);
int __sys_wait(int *status);
void __sys_exit(int status) __attribute__((noreturn));
int __sys_open(const char *path, int flags);
int __sys_read(int fd, void *buffer, size_t count);
int __sys_close(int fd);
int __sys_uptime(void);
int __sys_exec(const char *path, char *const argv[]);
void *__sys_sbrk(ptrdiff_t increment);
int __sys_readdir(const char *path, unsigned int index, struct dirent *entry);
char *__sys_getcwd(char *buffer, size_t size);

int errno;

static int syscall_result(int result)
{
    if (result >= 0)
        return result;
    errno = -result;
    return -1;
}

ssize_t write(int fd, const void *buffer, size_t count)
{
    if (fd < 0 || !buffer)
        return -1;
    return syscall_result(__sys_write(fd, buffer, count));
}

int open(const char *path, int flags)
{
    if (!path) {
        errno = EFAULT;
        return -1;
    }
    return syscall_result(__sys_open(path, flags));
}

ssize_t read(int fd, void *buffer, size_t count)
{
    if (!buffer && count) {
        errno = EFAULT;
        return -1;
    }
    return syscall_result(__sys_read(fd, buffer, count));
}

int readdir(const char *path, unsigned int index, struct dirent *entry)
{
    if (!path || !entry) {
        errno = EFAULT;
        return -1;
    }
    return syscall_result(__sys_readdir(path, index, entry));
}

char *getcwd(char *buffer, size_t size)
{
    if (!buffer || size < 2u) {
        errno = EINVAL;
        return NULL;
    }
    char *result = __sys_getcwd(buffer, size);
    if ((intptr_t)result < 0) {
        errno = EINVAL;
        return NULL;
    }
    return result;
}

int close(int fd) { return syscall_result(__sys_close(fd)); }
unsigned int uptime(void) { return (unsigned int)__sys_uptime(); }
int exec(const char *path, char *const argv[])
{
    if (!path) {
        errno = EFAULT;
        return -1;
    }
    return syscall_result(__sys_exec(path, argv));
}

void *sbrk(ptrdiff_t increment)
{
    void *result = __sys_sbrk(increment);
    if ((intptr_t)result < 0) {
        errno = ENOMEM;
        return (void *)-1;
    }
    return result;
}

struct heap_block {
    size_t size;
    struct heap_block *next;
    int free;
};

static struct heap_block *heap_blocks;

static size_t heap_align(size_t size)
{
    return (size + 7u) & ~7u;
}

void *malloc(size_t size)
{
    if (!size)
        return NULL;
    size = heap_align(size);
    for (struct heap_block *block = heap_blocks; block; block = block->next) {
        if (block->free && block->size >= size) {
            block->free = 0;
            return block + 1;
        }
    }
    size_t total = sizeof(struct heap_block) + size;
    struct heap_block *block = sbrk((ptrdiff_t)total);
    if (block == (void *)-1)
        return NULL;
    block->size = size;
    block->free = 0;
    block->next = NULL;
    if (!heap_blocks) {
        heap_blocks = block;
    } else {
        struct heap_block *tail = heap_blocks;
        while (tail->next) tail = tail->next;
        tail->next = block;
    }
    return block + 1;
}

void free(void *pointer)
{
    if (pointer)
        ((struct heap_block *)pointer - 1)->free = 1;
}

void *calloc(size_t count, size_t size)
{
    if (size && count > (size_t)-1 / size) {
        errno = ENOMEM;
        return NULL;
    }
    size_t bytes = count * size;
    void *memory = malloc(bytes);
    if (memory)
        memset(memory, 0, bytes);
    return memory;
}

void *realloc(void *pointer, size_t size)
{
    if (!pointer)
        return malloc(size);
    if (!size) {
        free(pointer);
        return NULL;
    }
    struct heap_block *block = (struct heap_block *)pointer - 1;
    if (block->size >= size)
        return pointer;
    void *replacement = malloc(size);
    if (!replacement)
        return NULL;
    memcpy(replacement, pointer, block->size);
    free(pointer);
    return replacement;
}

pid_t getpid(void) { return syscall_result(__sys_getpid()); }
int yield(void) { return syscall_result(__sys_yield()); }
pid_t fork(void) { return syscall_result(__sys_fork()); }
pid_t vfork(void) { return syscall_result(__sys_vfork()); }
unsigned int sleep(unsigned int seconds)
{
    int result = syscall_result(__sys_sleep(seconds));
    return result < 0 ? seconds : (unsigned int)result;
}

pid_t wait(int *status)
{
    return syscall_result(__sys_wait(status));
}

void exit(int status)
{
    __sys_exit(status);
}

size_t strlen(const char *text)
{
    size_t length = 0;
    while (text[length])
        ++length;
    return length;
}

size_t strnlen(const char *text, size_t maximum)
{
    size_t length = 0;
    while (length < maximum && text[length])
        ++length;
    return length;
}

void *memcpy(void *destination, const void *source, size_t count)
{
    unsigned char *dst = destination;
    const unsigned char *src = source;
    while (count--)
        *dst++ = *src++;
    return destination;
}

void *memmove(void *destination, const void *source, size_t count)
{
    unsigned char *dst = destination;
    const unsigned char *src = source;
    if (dst < src) {
        for (size_t i = 0; i < count; ++i)
            dst[i] = src[i];
    } else if (dst > src) {
        while (count)
            dst[count - 1] = src[count - 1], --count;
    }
    return destination;
}

void *memset(void *destination, int value, size_t count)
{
    unsigned char *dst = destination;
    while (count--)
        *dst++ = (unsigned char)value;
    return destination;
}

int memcmp(const void *left, const void *right, size_t count)
{
    const unsigned char *a = left;
    const unsigned char *b = right;
    for (size_t i = 0; i < count; ++i)
        if (a[i] != b[i])
            return a[i] - b[i];
    return 0;
}

void *memchr(const void *memory, int value, size_t count)
{
    const unsigned char *p = memory;
    for (size_t i = 0; i < count; ++i)
        if (p[i] == (unsigned char)value)
            return (void *)(p + i);
    return NULL;
}

char *strcpy(char *destination, const char *source)
{
    char *result = destination;
    while ((*destination++ = *source++) != '\0') { }
    return result;
}

char *strncpy(char *destination, const char *source, size_t count)
{
    char *result = destination;
    while (count && *source) {
        *destination++ = *source++;
        --count;
    }
    while (count--) *destination++ = '\0';
    return result;
}

char *strcat(char *destination, const char *source)
{
    strcpy(destination + strlen(destination), source);
    return destination;
}

char *strncat(char *destination, const char *source, size_t count)
{
    char *end = destination + strlen(destination);
    while (count-- && *source)
        *end++ = *source++;
    *end = '\0';
    return destination;
}

int strcmp(const char *left, const char *right)
{
    while (*left && *left == *right) {
        ++left;
        ++right;
    }
    return (unsigned char)*left - (unsigned char)*right;
}

int strncmp(const char *left, const char *right, size_t count)
{
    while (count && *left && *left == *right) {
        ++left; ++right; --count;
    }
    return count ? (unsigned char)*left - (unsigned char)*right : 0;
}

char *strchr(const char *text, int character)
{
    char target = (char)character;
    do {
        if (*text == target)
            return (char *)text;
    } while (*text++);
    return NULL;
}

char *strrchr(const char *text, int character)
{
    const char *last = NULL;
    char target = (char)character;
    do {
        if (*text == target)
            last = text;
    } while (*text++);
    return (char *)last;
}

char *strstr(const char *text, const char *needle)
{
    if (!*needle)
        return (char *)text;
    size_t length = strlen(needle);
    for (; *text; ++text)
        if (*text == *needle && strncmp(text, needle, length) == 0)
            return (char *)text;
    return NULL;
}

int isdigit(int c) { return c >= '0' && c <= '9'; }
int islower(int c) { return c >= 'a' && c <= 'z'; }
int isupper(int c) { return c >= 'A' && c <= 'Z'; }
int isalpha(int c) { return islower(c) || isupper(c); }
int isalnum(int c) { return isalpha(c) || isdigit(c); }
int isascii(int c) { return (unsigned int)c <= 0x7fu; }
int isblank(int c) { return c == ' ' || c == '\t'; }
int iscntrl(int c) { return (unsigned int)c < 0x20u || c == 0x7f; }
int isgraph(int c) { return c >= 0x21 && c <= 0x7e; }
int isprint(int c) { return c >= 0x20 && c <= 0x7e; }
int isspace(int c) { return c == ' ' || (c >= '\t' && c <= '\r'); }
int isxdigit(int c)
{
    return isdigit(c) || (c >= 'a' && c <= 'f') ||
           (c >= 'A' && c <= 'F');
}
int ispunct(int c) { return isgraph(c) && !isalnum(c); }
int tolower(int c) { return isupper(c) ? c + ('a' - 'A') : c; }
int toupper(int c) { return islower(c) ? c - ('a' - 'A') : c; }

int abs(int value) { return value < 0 ? -value : value; }
long labs(long value) { return value < 0 ? -value : value; }

static int digit_value(int c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'z') return c - 'a' + 10;
    if (c >= 'A' && c <= 'Z') return c - 'A' + 10;
    return -1;
}

unsigned long strtoul(const char *text, char **end, int base)
{
    const char *start = text;
    unsigned long value = 0;
    while (isspace(*text)) ++text;
    int negative = *text == '-';
    if (*text == '+' || *text == '-') ++text;
    if ((base == 0 || base == 16) && text[0] == '0' &&
        (text[1] == 'x' || text[1] == 'X')) {
        base = 16; text += 2;
    } else if (base == 0) {
        base = text[0] == '0' ? 8 : 10;
    }
    if (base < 2 || base > 36) {
        errno = EINVAL;
        if (end) *end = (char *)start;
        return 0;
    }
    const char *digits = text;
    int digit;
    while ((digit = digit_value(*text)) >= 0 && digit < base) {
        value = value * (unsigned int)base + (unsigned int)digit;
        ++text;
    }
    if (end) *end = (char *)(text == digits ? start : text);
    return negative ? 0ul - value : value;
}

long strtol(const char *text, char **end, int base)
{
    return (long)strtoul(text, end, base);
}

int atoi(const char *text) { return (int)strtol(text, NULL, 10); }
long atol(const char *text) { return strtol(text, NULL, 10); }

int putchar(int character)
{
    char byte = (char)character;
    return write(STDOUT_FILENO, &byte, 1) == 1 ? character : -1;
}

int puts(const char *text)
{
    size_t length = strlen(text);
    if (write(STDOUT_FILENO, text, length) != (ssize_t)length ||
        write(STDOUT_FILENO, "\n", 1) != 1)
        return -1;
    return 0;
}

static void append_char(char *buffer, size_t capacity, size_t *length, char c)
{
    if (capacity && *length + 1 < capacity)
        buffer[*length] = c;
    ++*length;
}

static void append_number(char *buffer, size_t capacity, size_t *length,
                          unsigned int value, unsigned int base)
{
    static const char digits[] = "0123456789abcdef";
    char reverse[16];
    size_t count = 0;
    do {
        reverse[count++] = digits[value % base];
        value /= base;
    } while (value && count < sizeof(reverse));
    while (count)
        append_char(buffer, capacity, length, reverse[--count]);
}

int vsnprintf(char *buffer, size_t size, const char *format, va_list args)
{
    size_t length = 0;
    while (*format) {
        if (*format++ != '%') {
            append_char(buffer, size, &length, format[-1]);
            continue;
        }
        char specifier = *format++;
        if (specifier == 's') {
            const char *text = va_arg(args, const char *);
            if (!text)
                text = "(null)";
            while (*text)
                append_char(buffer, size, &length, *text++);
        } else if (specifier == 'c') {
            append_char(buffer, size, &length,
                        (char)va_arg(args, int));
        } else if (specifier == 'd') {
            int value = va_arg(args, int);
            unsigned int magnitude;
            if (value < 0) {
                append_char(buffer, size, &length, '-');
                magnitude = 0u - (unsigned int)value;
            } else {
                magnitude = (unsigned int)value;
            }
            append_number(buffer, size, &length, magnitude, 10);
        } else if (specifier == 'u') {
            append_number(buffer, size, &length,
                          va_arg(args, unsigned int), 10);
        } else if (specifier == 'x') {
            append_number(buffer, size, &length,
                          va_arg(args, unsigned int), 16);
        } else if (specifier == '%') {
            append_char(buffer, size, &length, '%');
        } else {
            append_char(buffer, size, &length, '%');
            append_char(buffer, size, &length, specifier);
        }
    }
    if (size)
        buffer[length < size ? length : size - 1] = '\0';
    return (int)length;
}

int snprintf(char *buffer, size_t size, const char *format, ...)
{
    va_list args;
    va_start(args, format);
    int result = vsnprintf(buffer, size, format, args);
    va_end(args);
    return result;
}

int vprintf(const char *format, va_list args)
{
    char buffer[192];
    va_list copy;
    va_copy(copy, args);
    int length = vsnprintf(buffer, sizeof(buffer), format, copy);
    va_end(copy);
    size_t output = (size_t)length;
    if (output >= sizeof(buffer))
        output = sizeof(buffer) - 1;
    if (write(STDOUT_FILENO, buffer, output) < 0)
        return -1;
    return length;
}

int printf(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    int result = vprintf(format, args);
    va_end(args);
    return result;
}
