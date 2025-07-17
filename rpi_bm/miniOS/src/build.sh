BOOTMNT = /media/rlk/bootfs
ARMGNU = aarch64-linux-gnu
INIT_MMU = 1
SRC_DIR=./
BUILD_DIR=../build
mkdir -p $BUILD_DIR

COPS="-g -std=c99 -DRPI_VERSION=3 -DINIT_MMU=1 -Wall -Wno-psabi -nostdlib -nostartfiles -ffreestanding \
	   -fno-exceptions -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector  -Iinclude -mgeneral-regs-only"


find ./ -name '*.c' | while read file; do
    # 只保留文件名部分，去除路径
    base=$(basename "$file" .c)
    objfile="$BUILD_DIR/${base}.o"
    aarch64-linux-gnu-gcc $COPS -I../include -c "$file" -o "$objfile"
done
find ./ -name '*.S' | while read file; do
    # 只保留文件名部分，去除路径
    base=$(basename "$file" .c)
    objfile="$BUILD_DIR/${base}.o"
    aarch64-linux-gnu-gcc $COPS -I../include -c "$file" -o "$objfile"
done
# 链接
OBJ_FILES=$(ls $BUILD_DIR/*.o)
aarch64-linux-gnu-ld  -nostdlib -T $SRC_DIR/linker.ld -I../include -o kernel8.elf $OBJ_FILES
#aarch64-linux-gnu-ld -g -nostdlib -T link.lds -Iinclude -o kernel8.elf boot.o main.o liba.o uart.o print.o debug.o handlera.o handler.o mmu.o process.o file.o liblist.o
aarch64-linux-gnu-objcopy -O binary kernel8.elf kernel8.img
#qemu-system-aarch64  -S -s -nographic -machine raspi3  -kernel kernel8.img
