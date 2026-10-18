OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

SECTIONS
{
    . = 0x00100000;
    .text : {
        KEEP(*(.text.start))
        *(.text .text.*)
    }
    .rodata : { *(.rodata .rodata.*) }
    .data : { *(.data .data.*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.ARM.attributes) *(.bss .bss.*) }
    ASSERT(. <= 0x00101000, "T113 init user program exceeds one page")
}
