#pragma once

//#if RPI_VERSION == 3
/* The kernel's TTBR1 direct map is VA = KERNEL_VIRT_BASE + PA.  Keep MMIO
 * independent of the per-process TTBR0 mappings. */
#define PBASE (0xFFFFFF8000000000UL + 0x3F000000UL)
#define DEVICE_START 0x3B400000



//#endif

#define CORE_CLOCK_SPEED 1500000000
