aarch64-elf-gcc -g -O0 -fno-omit-frame-pointer -c start.s -o start.o
aarch64-elf-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c main.c
aarch64-elf-ld -nostdlib -T link.lds -o init start.o main.o ../lib/lib.a
aarch64-elf-objcopy -O binary init user.bin
aarch64-elf-ld -r -b binary user.bin -o user_blob.o