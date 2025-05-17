
 SECTIONS
{
   . = 0x80000;
    .text.boot : { *(.text.boot) }
  .text : {
  __text_start = .;
  *(.text)
  __text_end = .;
}
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    . = ALIGN(0x8);
    bss_begin = .;
    .bss : { *(.bss*) }
    bss_end = .;
    . = ALIGN(0x00001000);
    id_pgd = .;
    .data.id_pgd : { . += (6 * (1 << 12)); }
}
