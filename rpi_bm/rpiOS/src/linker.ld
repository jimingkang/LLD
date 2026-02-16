ENTRY(_start)

SECTIONS
{
    . = 0x80000;
    
    .text.boot : {
        *(.text.boot)
    }
    
    .text : {
        *(.text)
    }
    
    .rodata : {
        *(.rodata)
    }
    
    .data : {
        *(.data)
    }
    
    . = ALIGN(8);
    __bss_start = .;
    .bss : {
        *(.bss*)
    }
    __bss_end = .;
    __bss_size = (__bss_end - __bss_start) >> 3;
    
    . = ALIGN(4096);
    __page_table_start = .;
    . = . + 4096;
    __page_table_end = .;
    
    . = ALIGN(8);
    . = . + 0x8000;
    __stack_top = .;
}
