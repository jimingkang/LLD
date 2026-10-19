#ifndef MINIOS_T113_SPINLOCK_H
#define MINIOS_T113_SPINLOCK_H

#include <stdint.h>

typedef struct {
    volatile uint32_t value;
} spinlock_t;

#define SPINLOCK_INIT { 0u }

static inline void spin_lock_init(spinlock_t *lock)
{
    lock->value = 0;
}

static inline uint32_t local_irq_save(void)
{
    uint32_t flags;
    __asm__ volatile("mrs %0, cpsr\n\tcpsid i"
                     : "=r"(flags) : : "memory", "cc");
    return flags;
}

static inline void local_irq_restore(uint32_t flags)
{
    if (!(flags & (1u << 7)))
        __asm__ volatile("cpsie i" ::: "memory", "cc");
}

static inline void spin_lock(spinlock_t *lock)
{
    uint32_t busy, failed;
    do {
        do {
            __asm__ volatile("ldrex %0, [%1]"
                             : "=&r"(busy) : "r"(&lock->value) : "memory");
        } while (busy);
        __asm__ volatile("strex %0, %2, [%1]"
                         : "=&r"(failed)
                         : "r"(&lock->value), "r"(1u)
                         : "memory", "cc");
    } while (failed);
    __asm__ volatile("dmb ish" ::: "memory");
}

static inline int spin_trylock(spinlock_t *lock)
{
    uint32_t busy, failed;
    __asm__ volatile("ldrex %0, [%2]\n\t"
                     "cmp %0, #0\n\t"
                     "strexeq %1, %3, [%2]\n\t"
                     "movne %1, #1"
                     : "=&r"(busy), "=&r"(failed)
                     : "r"(&lock->value), "r"(1u)
                     : "memory", "cc");
    if (failed)
        return 0;
    __asm__ volatile("dmb ish" ::: "memory");
    return 1;
}

static inline void spin_unlock(spinlock_t *lock)
{
    __asm__ volatile("dmb ish" ::: "memory");
    lock->value = 0;
    __asm__ volatile("sev" ::: "memory");
}

static inline uint32_t spin_lock_irqsave(spinlock_t *lock)
{
    uint32_t flags = local_irq_save();
    spin_lock(lock);
    return flags;
}

static inline void spin_unlock_irqrestore(spinlock_t *lock, uint32_t flags)
{
    spin_unlock(lock);
    local_irq_restore(flags);
}

#endif
