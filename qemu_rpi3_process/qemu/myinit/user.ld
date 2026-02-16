ENTRY(main)
SECTIONS {
  . = 0x400000;
  .text : { *(.text*) }
}

