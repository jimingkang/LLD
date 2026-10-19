/*
 * Microsecond busy-wait on the ARMv7 generic timer (CNTPCT), which runs from
 * the 24 MHz oscillator on T113. Safe with IRQs off (driver probe context).
 * If the counter is not ticking (not enabled by the boot loader) we fall
 * back to a rough spin loop so callers never hang.
 */
#include "platform.h"

#define FALLBACK_LOOPS_PER_US 200u      /* ~1 GHz Cortex-A7, generous */

static inline uint64_t read_cntpct(void)
{
    uint32_t lo, hi;
    __asm__ volatile("isb\n\tmrrc p15, 0, %0, %1, c14"
                     : "=r"(lo), "=r"(hi) :: "memory");
    return ((uint64_t)hi << 32) | lo;
}

static inline uint32_t read_cntfrq(void)
{
    uint32_t frq;
    __asm__ volatile("mrc p15, 0, %0, c14, c0, 0" : "=r"(frq));
    return frq;
}

uint64_t t113_time_us(void)
{
    /* T113's architectural counter is driven by the 24 MHz oscillator.
     * Keep the divisor constant: this freestanding kernel deliberately does
     * not link libgcc's __aeabi_uldivmod helper. */
    uint64_t ticks = read_cntpct();
    uint32_t hi = (uint32_t)(ticks >> 32);
    uint32_t lo = (uint32_t)ticks;
    uint32_t qhi = hi / 24u;
    uint32_t rem = hi - qhi * 24u;
    uint32_t qlo = 0;
    for (int bit = 31; bit >= 0; --bit) {
        rem = (rem << 1) | ((lo >> bit) & 1u);
        if (rem >= 24u) {
            rem -= 24u;
            qlo |= 1u << bit;
        }
    }
    return ((uint64_t)qhi << 32) | qlo;
}

void t113_udelay(uint32_t us)
{
    uint32_t frq = read_cntfrq();
    if (!frq)
        frq = 24000000u;

    uint64_t start = read_cntpct();
    uint32_t probe = 0;
    while (read_cntpct() == start) {
        if (++probe > 10000u) {         /* counter stopped: spin instead */
            for (volatile uint32_t i = 0; i < us * FALLBACK_LOOPS_PER_US; ++i) { }
            return;
        }
    }

    uint64_t ticks = (uint64_t)us * (frq / 1000000u);
    while (read_cntpct() - start < ticks) { }
}

void t113_mdelay(uint32_t ms)
{
    while (ms--)
        t113_udelay(1000u);
}
