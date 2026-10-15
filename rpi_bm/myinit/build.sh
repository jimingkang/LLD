aarch64-elf-gcc -c start.s -o start.o
aarch64-elf-gcc -std=c99 -ffreestanding -mgeneral-regs-only  -c main.c
aarch64-elf-ld -nostdlib -T link.lds -o init start.o main.o ../lib/lib.a
aarch64-elf-objcopy -O binary init init.bin
aarch64-elf-ld -r -b binary init.bin -o init_blob.o