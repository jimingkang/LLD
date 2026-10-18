OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY
{
    sram (rwx) : ORIGIN = 0x00020000, LENGTH = 128K
}

SECTIONS
{
    .text ORIGIN(sram) : {
        __spl_start = .;
        KEEP(*head.o(.boot0_head))
        KEEP(*start.o(.text.start))
        *(.text .text.* .rodata .rodata.*)
    } > sram

    .data : {
        *(EXCLUDE_FILE (*kernel_payload.o) .data .data.*)
    } > sram

    .kernel_payload : ALIGN(16) {
        __kernel_load_start = .;
        *kernel_payload.o(.data)
        __kernel_load_end = .;
    } > sram

    .bss (NOLOAD) : {
        . = ALIGN(8);
        __spl_bss_start = .;
        *(.bss .bss.* COMMON)
        __spl_bss_end = .;
    } > sram

    .stack (NOLOAD) : {
        . = ALIGN(8);
        . += 0x2000;
        __spl_stack_svc_end = .;
        . += 0x0400;
        __spl_stack_irq_end = .;
        __spl_reserved_end = .;
    } > sram

    __kernel_start = 0x40200000;
    __spl_size = __kernel_load_end - __spl_start;
    __spl_end = __kernel_load_end;
    __code_start_address = ORIGIN(sram);

    /DISCARD/ : { *(.comment) *(.note*) *(.ARM.attributes) }

    ASSERT(__spl_reserved_end <= ORIGIN(sram) + LENGTH(sram),
           "miniBoot SPL + miniOS payload exceeds T113 SRAM")
}
