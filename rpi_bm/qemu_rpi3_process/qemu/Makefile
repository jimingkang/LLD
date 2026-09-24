ARMGNU ?= $(shell if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then printf aarch64-linux-gnu; elif command -v aarch64-elf-gcc >/dev/null 2>&1; then printf aarch64-elf; fi)

.DEFAULT_GOAL := all

ifeq ($(strip $(ARMGNU)),)
$(error No AArch64 cross-toolchain found. Install aarch64-linux-gnu-gcc or aarch64-elf-gcc, or set ARMGNU)
endif

CC      := $(ARMGNU)-gcc
LD      := $(ARMGNU)-ld
AR      := $(ARMGNU)-ar
OBJCOPY := $(ARMGNU)-objcopy

BOOTMNT ?= /Volumes/bootfs

CFLAGS  := -g -O0 -Wall -MMD -MP -fno-omit-frame-pointer -std=c99 -ffreestanding -mgeneral-regs-only
ASFLAGS := -g -O0 -fno-omit-frame-pointer

KERNEL_C_SRCS := main.c uart.c print.c debug.c handler.c memory.c file.c process.c syscall.c lib.c
KERNEL_C_OBJS := $(KERNEL_C_SRCS:.c=.o)
# boot.o must be first: Raspberry Pi firmware starts at the first byte of
# kernel8.img; an ELF entry point is not present in the raw binary.
KERNEL_OBJS   := boot.o main.o liba.o lib.o uart.o print.o debug.o \
		 handlera.o handler.o mmu.o memory.o file.o process.o syscall.o

-include $(KERNEL_C_OBJS:.o=.d)

.PHONY: all clean rpi

all: kernel8.img

rpi: all
	@test -d "$(BOOTMNT)" || { echo "Boot volume not found: $(BOOTMNT)"; exit 1; }
	cp kernel8.img config.txt "$(BOOTMNT)/"
	sync
	@echo "Installed kernel8.img and config.txt to $(BOOTMNT)"

kernel8.img: kernel.elf os.img
	$(OBJCOPY) -O binary kernel.elf $@
	dd if=os.img >> $@

kernel.elf: link.lds user_blob.o init_blob.o $(KERNEL_OBJS)
	$(LD) -nostdlib -T link.lds -o $@ user_blob.o init_blob.o $(KERNEL_OBJS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

boot.o: boot.s
	$(CC) $(ASFLAGS) -c $< -o $@

liba.o: lib.s
	$(CC) $(ASFLAGS) -c $< -o $@

handlera.o: handler.s
	$(CC) $(ASFLAGS) -c $< -o $@

mmu.o: mmu.s
	$(CC) $(ASFLAGS) -c $< -o $@

lib/lib.a: lib/print.c lib/syscall.s lib/lib.h
	$(CC) $(CFLAGS) -c lib/print.c -o lib/print.o
	$(CC) $(ASFLAGS) -c lib/syscall.s -o lib/syscall.o
	$(AR) rcs $@ lib/print.o lib/syscall.o

init/user.bin: init/start.s init/main.c init/link.lds lib/lib.a
	$(CC) $(ASFLAGS) -c init/start.s -o init/start.o
	$(CC) $(CFLAGS) -c init/main.c -o init/main.o
	$(LD) -nostdlib -T init/link.lds -o init/init init/start.o init/main.o lib/lib.a
	$(OBJCOPY) -O binary init/init $@

user_blob.o: init/user.bin
	cd init && $(LD) -r -b binary user.bin -o ../$@

myinit/init.bin: init/start.s myinit/main.c myinit/link.lds lib/lib.a
	$(CC) $(ASFLAGS) -c init/start.s -o myinit/start.o
	$(CC) $(CFLAGS) -c myinit/main.c -o myinit/main.o
	$(LD) -nostdlib -T myinit/link.lds -o myinit/init myinit/start.o myinit/main.o lib/lib.a
	$(OBJCOPY) -O binary myinit/init $@

init_blob.o: myinit/init.bin
	cd myinit && $(LD) -r -b binary init.bin -o ../$@

clean:
	rm -f $(KERNEL_OBJS) $(KERNEL_C_OBJS:.o=.d) user_blob.o init_blob.o kernel.elf kernel8.img
	rm -f lib/print.o lib/syscall.o lib/lib.a
	rm -f init/start.o init/main.o init/init init/user.bin
	rm -f myinit/start.o myinit/main.o myinit/init myinit/init.bin
