aarch64-elf-gcc -c syscall.s -o syscall.o
aarch64-elf-gcc -std=c99 -ffreestanding -mgeneral-regs-only  -c print.c
aarch64-elf-ar rcs lib.a print.o syscall.o