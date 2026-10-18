OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(kernel_entry)

MEMORY
{
    dram (rwx) : ORIGIN = 0x40200000, LENGTH = 126M
}

SECTIONS
{
    .kernel ORIGIN(dram) : {
        __kernel_start = .;
        KEEP(*kernel_entry.o(.text.kernel_entry))
        *(.text .text.* .rodata .rodata.*)
        . = ALIGN(16);
        *(.data .data.*)
        __kernel_load_end = .;
    } > dram

    .kernel_bss (NOLOAD) : {
        . = ALIGN(8);
        __kernel_bss_start = .;
        *(.bss .bss.* COMMON)
        __kernel_bss_end = .;
    } > dram

    .kernel_page_table (NOLOAD) : {
        . = ALIGN(0x4000);
        __kernel_l1_table = .;
        . += 0x4000;
        __kernel_l1_table_end = .;
    } > dram

    .kernel_stack (NOLOAD) : {
        . = ALIGN(8);
        . += 0x2000;
        __kernel_stack_svc_end = .;
        . += 0x0400;
        __kernel_stack_irq_end = .;
        . = ALIGN(0x1000);
        __kernel_reserved_end = .;
    } > dram

    /DISCARD/ : { *(.comment) *(.note*) *(.ARM.attributes) }

    ASSERT(__kernel_reserved_end <= ORIGIN(dram) + LENGTH(dram),
           "miniOS kernel reserved area exceeds DDR link window")
}
