aarch64-linux-gnu-gcc -c start.s -o start.o
aarch64-linux-gnu-gcc -std=c99 -ffreestanding -mgeneral-regs-only  -c main.c
aarch64-linux-gnu-ld -nostdlib -T link.lds -o init start.o main.o ../lib/lib.a
aarch64-linux-gnu-objcopy -O binary init init.bin
aarch64-linux-gnu-ld -r -b binary init.bin -o init_blob.o