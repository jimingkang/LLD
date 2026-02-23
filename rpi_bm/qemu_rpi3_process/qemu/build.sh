aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -c boot.s -o boot.o
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -c lib.s -o liba.o
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -c handler.s -o handlera.o
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -c mmu.s -o mmu.o
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c main.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c uart.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c print.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c debug.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c handler.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c memory.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c file.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c process.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c syscall.c
aarch64-linux-gnu-gcc -g -O0 -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only  -c lib.c
aarch64-linux-gnu-ld -nostdlib -T link.lds -o kernel.elf user_blob.o init_blob.o boot.o main.o liba.o lib.o uart.o print.o debug.o handlera.o handler.o mmu.o  memory.o file.o process.o syscall.o 
aarch64-linux-gnu-objcopy -O binary kernel.elf kernel8.img
dd if=os.img >> kernel8.img
