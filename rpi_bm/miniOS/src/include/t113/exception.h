#ifndef MINIOS_T113_EXCEPTION_H
#define MINIOS_T113_EXCEPTION_H

#include <stdint.h>

/* Vector numbers passed by kernel_entry.S (= vector table slot). */
#define T113_EXC_UNDEF          1u
#define T113_EXC_PREFETCH_ABORT 3u
#define T113_EXC_DATA_ABORT     4u
#define T113_EXC_FIQ            7u

/* Built on the UND/ABT stack by kernel_exception_common (kernel_entry.S). */
struct t113_exception_frame {
    uint32_t spsr;
    uint32_t sp;        /* banked SP of the interrupted mode */
    uint32_t lr;        /* banked LR of the interrupted mode */
    uint32_t r[13];
    uint32_t pc;        /* faulting instruction (ARM state) */
};

void t113_exception_report(uint32_t type, struct t113_exception_frame *f)
    __attribute__((noreturn));

/*
 * Hardware stage-1 translation of va through the current TTBR0/TTBR1
 * (ATS1C{P,U}{R,W}). Returns the PAR value: bit 0 set = the access would
 * fault, FS in bits [6:1]; otherwise PA[31:12] in bits [31:12].
 */
uint32_t t113_mmu_probe(uint32_t va, int user, int write);
/* Print "ok PA=..." or "FAULT <reason>" for a t113_mmu_probe() result. */
void t113_mmu_probe_print(uint32_t par);

#endif
