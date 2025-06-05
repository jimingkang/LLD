KERNEL_VIRT_BASE =0xFFFFFF8000000000;   /* 0xffff000000000000;  高半内核虚拟基址 */
KERNEL_PHYS_BASE = 0x80000;           /* 物理加载地址（例如树莓派默认） */
 SECTIONS
{
   . = KERNEL_VIRT_BASE +KERNEL_PHYS_BASE ;

    .text : AT(ADDR(.text) - KERNEL_VIRT_BASE) {
        KERNEL_CODE_START = .;
        *(.text.boot)        /* 启动代码（必须放在最前面）    .text.boot : { *(.text.boot) }*/
        *(.text .text.*)
        KERNEL_CODE_END = .;
    }
      .rodata : {
        *(.rodata .rodata.*) 
    }
       . = ALIGN(4096);         /* 数据段按4KB对齐 */
    .data
     : {
         KERNEL_DATA_START = .;
         *(.data .data.*)
         . = ALIGN(4096);
         id_pgd = .;
            . += 24576;
         
         . = ALIGN(4096);
         pg_dir = .;
            . += 12288;
         
         KERNEL_DATA_END = .;
    }
    . = ALIGN(0x8);
    .bss : {
        . = ALIGN(4096);
        KERNEL_BSS_START = .;
        *(.bss .bss.*)
        *(COMMON)
        KERNEL_BSS_END = .;
    }
   .rodata : { *(.rodata) }

. = ALIGN(0x00001000);

/* 用户代码段（用户模式执行） */
    . = 0x400000; /* 用户空间起始地址（如4MB处） */
    user_begin = .;
    .user.text : { 
          *(.user.text)         /* 明确包含 .user.text 段 */
    }
    .user.rodata : { 
          *(.user.rodata)
    }
      .user.data : { 
          *(.user.data)
    }
    . = ALIGN(0x1000);  /* 页对齐 */
    user_data_begin = .;
    .user.data : { *(.user.data) }
    .user.bss : { *(.user.bss) *(COMMON) }
    user_data_end = .;
    user_end = .;





   /* 定义物理地址符号（可选）
    PHYS_CODE_START = KERNEL_CODE_START - KERNEL_VIRT_BASE;
    PHYS_DATA_START = KERNEL_DATA_START - KERNEL_VIRT_BASE;
 */
}
