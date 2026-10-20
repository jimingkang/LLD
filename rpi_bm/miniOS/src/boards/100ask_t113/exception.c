/*
 * Undefined instruction / prefetch abort / data abort / FIQ reporting.
 *
 * kernel_entry.S hands us the full register state; we print it together
 * with the fault status/address registers, the current task and a hardware
 * translation of the interesting addresses, then halt.  Nothing here
 * allocates, takes locks or relies on IRQs: the UART is polled.
 */
#include "platform.h"
#include "sched.h"
#include "user_vm.h"
#include "exception.h"

extern uint8_t __kernel_start[];
extern uint8_t __kernel_reserved_end[];

#define DDR_BASE 0x40000000u
#define DDR_END  0x48000000u            /* 128 MiB on the 100ASK T113-S3 */

static void puts_(const char *s) { t113_uart_puts(s); }
static void hex(uint32_t v) { t113_uart_puthex(v); }

static void putdec(uint32_t v)
{
    char b[11];
    int i = 10;
    b[i] = '\0';
    do {
        b[--i] = (char)('0' + v % 10u);
        v /= 10u;
    } while (v && i);
    puts_(b + i);
}

static uint32_t read_dfsr(void)
{
    uint32_t v;
    __asm__ volatile("mrc p15, 0, %0, c5, c0, 0" : "=r"(v));
    return v;
}

static uint32_t read_dfar(void)
{
    uint32_t v;
    __asm__ volatile("mrc p15, 0, %0, c6, c0, 0" : "=r"(v));
    return v;
}

static uint32_t read_ifsr(void)
{
    uint32_t v;
    __asm__ volatile("mrc p15, 0, %0, c5, c0, 1" : "=r"(v));
    return v;
}

static uint32_t read_ifar(void)
{
    uint32_t v;
    __asm__ volatile("mrc p15, 0, %0, c6, c0, 2" : "=r"(v));
    return v;
}

static uint32_t read_sctlr(void)
{
    uint32_t v;
    __asm__ volatile("mrc p15, 0, %0, c1, c0, 0" : "=r"(v));
    return v;
}

static uint32_t read_ttbr0(void)
{
    uint32_t v;
    __asm__ volatile("mrc p15, 0, %0, c2, c0, 0" : "=r"(v));
    return v;
}

uint32_t t113_mmu_probe(uint32_t va, int user, int write)
{
    uint32_t par;
    if (user && write)
        __asm__ volatile("mcr p15, 0, %0, c7, c8, 3" :: "r"(va));
    else if (user)
        __asm__ volatile("mcr p15, 0, %0, c7, c8, 2" :: "r"(va));
    else if (write)
        __asm__ volatile("mcr p15, 0, %0, c7, c8, 1" :: "r"(va));
    else
        __asm__ volatile("mcr p15, 0, %0, c7, c8, 0" :: "r"(va));
    __asm__ volatile("isb\n\tmrc p15, 0, %0, c7, c4, 0" : "=r"(par) :: "memory");
    return par;
}

/* Short-descriptor FS[4:0] = FSR bit 10 : bits 3..0. */
static uint32_t fsr_status(uint32_t fsr)
{
    return ((fsr >> 6) & 0x10u) | (fsr & 0xfu);
}

static const char *fault_name(uint32_t fs)
{
    switch (fs) {
    case 0x01: return "alignment fault";
    case 0x02: return "debug event (BKPT)";
    case 0x03: return "access flag fault, section";
    case 0x06: return "access flag fault, page";
    case 0x04: return "instruction cache maintenance fault";
    case 0x05: return "translation fault, section (no L1 entry)";
    case 0x07: return "translation fault, page (no L2 entry)";
    case 0x08: return "synchronous external abort";
    case 0x09: return "domain fault, section";
    case 0x0b: return "domain fault, page";
    case 0x0c: return "external abort on translation walk, L1";
    case 0x0e: return "external abort on translation walk, L2";
    case 0x0d: return "permission fault, section";
    case 0x0f: return "permission fault, page";
    case 0x16: return "asynchronous external abort";
    case 0x18: return "asynchronous parity error";
    case 0x19: return "synchronous parity error";
    default:   return "unknown fault status";
    }
}

void t113_mmu_probe_print(uint32_t par)
{
    if (par & 1u) {
        puts_("FAULT ");
        puts_(fault_name((par >> 1) & 0x1fu));
        puts_(" (PAR ");
        hex(par);
        puts_(")");
    } else {
        puts_("ok PA=");
        hex(par & 0xfffff000u);
    }
}

static const char *mode_name(uint32_t mode)
{
    switch (mode & 0x1fu) {
    case 0x10: return "USR";
    case 0x11: return "FIQ";
    case 0x12: return "IRQ";
    case 0x13: return "SVC";
    case 0x17: return "ABT";
    case 0x1b: return "UND";
    case 0x1f: return "SYS";
    default:   return "???";
    }
}

static const char *exc_name(uint32_t type)
{
    switch (type) {
    case T113_EXC_UNDEF:          return "UNDEFINED INSTRUCTION";
    case T113_EXC_PREFETCH_ABORT: return "PREFETCH ABORT";
    case T113_EXC_DATA_ABORT:     return "DATA ABORT";
    case T113_EXC_FIQ:            return "UNEXPECTED FIQ";
    default:                      return "UNKNOWN EXCEPTION";
    }
}

/*
 * Can we read size bytes at va from here without faulting again?  User
 * addresses go through the hardware walk of the current TTBR0; kernel
 * addresses are the identity-mapped DDR.
 */
static int readable(uint32_t va, uint32_t size, int from_user)
{
    if (va & (size - 1u))
        return 0;
    if (va >= DDR_BASE && va + size <= DDR_END && va + size > va)
        return 1;
    if (!from_user)
        return 0;
    return !(t113_mmu_probe(va, 1, 0) & 1u);
}

static void dump_words(const char *what, uint32_t va, uint32_t count,
                       int from_user)
{
    puts_(what);
    puts_(" @");
    hex(va);
    puts_(":");
    for (uint32_t i = 0; i < count; ++i) {
        uint32_t a = va + i * 4u;
        if (!readable(a, 4, from_user)) {
            puts_(" <unmapped>");
            break;
        }
        puts_(" ");
        hex(*(volatile const uint32_t *)(uintptr_t)a);
    }
    puts_("\n");
}

static void probe_line(const char *what, uint32_t va, int user, int write)
{
    puts_("  ");
    puts_(what);
    puts_(" ");
    hex(va);
    puts_(user ? (write ? " user-write: " : " user-read: ")
               : (write ? " kernel-write: " : " kernel-read: "));
    t113_mmu_probe_print(t113_mmu_probe(va, user, write));
    puts_("\n");
}

static volatile uint32_t exception_depth;

void t113_exception_report(uint32_t type, struct t113_exception_frame *f)
{
    __asm__ volatile("cpsid if" ::: "memory");
    if (++exception_depth > 1u) {
        /* Faulted while reporting: print the bare minimum and stop. */
        puts_("\n*** NESTED ");
        puts_(exc_name(type));
        puts_(" pc=");
        hex(f->pc);
        puts_(" ***\n");
        for (;;)
            __asm__ volatile("wfi");
    }

    uint32_t mode = f->spsr & 0x1fu;
    int from_user = mode == 0x10u;
    int thumb = (f->spsr >> 5) & 1u;
    if (type == T113_EXC_UNDEF && thumb)
        f->pc += 2u;                    /* LR_und = insn + 2 in Thumb */

    puts_("\n\n*** ");
    puts_(exc_name(type));
    puts_(" in ");
    puts_(mode_name(mode));
    puts_(" mode");
    puts_(thumb ? " (Thumb)" : " (ARM)");
    puts_(" ***\n");

    if (t113_current) {
        puts_("task pid=");
        putdec(t113_current->pid);
        puts_(" name=");
        puts_(t113_current->name ? t113_current->name : "?");
        puts_(" mm=");
        hex((uint32_t)(uintptr_t)t113_current->mm);
        puts_(" kstack=");
        hex((uint32_t)(uintptr_t)t113_current->kernel_stack);
        puts_("\n");
    } else {
        puts_("task: none (before scheduler start)\n");
    }

    puts_("pc  ");
    hex(f->pc);
    puts_("  spsr ");
    hex(f->spsr);
    puts_(" [");
    puts_(f->spsr & (1u << 31) ? "N" : "n");
    puts_(f->spsr & (1u << 30) ? "Z" : "z");
    puts_(f->spsr & (1u << 29) ? "C" : "c");
    puts_(f->spsr & (1u << 28) ? "V" : "v");
    puts_(f->spsr & (1u << 7) ? " I" : " i");
    puts_(f->spsr & (1u << 6) ? "F" : "f");
    puts_("]\n");
    for (uint32_t i = 0; i < 13u; ++i) {
        puts_("r");
        putdec(i);
        puts_(i < 10u ? "  " : " ");
        hex(f->r[i]);
        puts_((i % 4u) == 3u ? "\n" : "  ");
    }
    puts_("  sp  ");
    hex(f->sp);
    puts_("  lr  ");
    hex(f->lr);
    puts_("  (");
    puts_(mode_name(mode));
    puts_(" bank)\n");

    if (type == T113_EXC_DATA_ABORT) {
        uint32_t fsr = read_dfsr(), far = read_dfar();
        puts_("DFSR ");
        hex(fsr);
        puts_(" -> ");
        puts_(fault_name(fsr_status(fsr)));
        puts_((fsr & (1u << 11)) ? ", on WRITE" : ", on READ");
        puts_("\nDFAR ");
        hex(far);
        puts_("  (faulting data address)\n");
    } else if (type == T113_EXC_PREFETCH_ABORT) {
        uint32_t fsr = read_ifsr(), far = read_ifar();
        puts_("IFSR ");
        hex(fsr);
        puts_(" -> ");
        puts_(fault_name(fsr_status(fsr)));
        puts_("\nIFAR ");
        hex(far);
        puts_("  (faulting instruction address)\n");
    }

    uint32_t sctlr = read_sctlr();
    puts_("SCTLR ");
    hex(sctlr);
    puts_(" (MMU ");
    puts_(sctlr & 1u ? "on" : "off");
    puts_(", A ");
    puts_(sctlr & 2u ? "on" : "off");
    puts_(", D$ ");
    puts_(sctlr & 4u ? "on" : "off");
    puts_(", I$ ");
    puts_(sctlr & (1u << 12) ? "on" : "off");
    puts_(")  TTBR0 ");
    hex(read_ttbr0());
    if (t113_current && t113_current->mm) {
        puts_(" (task L1 ");
        hex((uint32_t)(uintptr_t)t113_current->mm->l1);
        puts_(")");
    }
    puts_("\n");

    if (sctlr & 1u) {
        puts_("MMU walk:\n");
        probe_line("pc", f->pc, from_user, 0);
        if (type == T113_EXC_DATA_ABORT) {
            uint32_t fsr = read_dfsr();
            probe_line("DFAR", read_dfar(), from_user, (fsr >> 11) & 1u);
        }
        probe_line("sp", f->sp, from_user, 1);
    }

    if (thumb)
        dump_words("insn (halfword pairs)", f->pc & ~3u, 2, from_user);
    else
        dump_words("insn", f->pc, 1, from_user);
    dump_words("code", (f->pc & ~3u) - 8u, 5, from_user);
    dump_words("stack", f->sp & ~3u, 8, from_user);

    puts_("*** system halted ***\n");
    for (;;)
        __asm__ volatile("wfi");
}
