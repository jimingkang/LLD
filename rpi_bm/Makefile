.DEFAULT_GOAL := all

ifndef TOOLPREFIX
TOOLPREFIX := $(shell if command -v aarch64-elf-gcc >/dev/null 2>&1; then \
	printf 'aarch64-elf-'; \
	elif command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then \
	printf 'aarch64-linux-gnu-'; \
	else \
	echo '*** Error: no AArch64 GCC/binutils toolchain found.' 1>&2; \
	echo '*** Install aarch64-elf-gcc or set TOOLPREFIX.' 1>&2; \
	exit 1; fi)
endif

CC      := $(TOOLPREFIX)gcc
LD      := $(TOOLPREFIX)ld
AR      := $(TOOLPREFIX)ar
OBJCOPY := $(TOOLPREFIX)objcopy
GDB     := $(TOOLPREFIX)gdb

QEMU ?= qemu-system-aarch64
GDBPORT ?= 25501
QEMUGDB := -gdb tcp:127.0.0.1:$(GDBPORT)
QEMUOPTS := -machine raspi3b -kernel kernel8.img -display none
# This kernel uses the BCM2837 PL011, exposed by QEMU as serial[0].
QEMUOPTS += -serial mon:stdio -serial null

BOOTMNT ?= /Volumes/bootfs
INSTALL_KERNEL_NAME ?= kernel8_bare.img

CFLAGS  := -g -O0 -Wall -MMD -MP -fno-omit-frame-pointer -std=c99
CFLAGS  += -mcpu=cortex-a53+nofp -ffreestanding -fno-common -nostdlib
CFLAGS  += -fno-stack-protector -mgeneral-regs-only
SCHED_TRACE ?= 0
CFLAGS  += -DSCHED_TRACE=$(SCHED_TRACE)
ASFLAGS := -g -O0 -fno-omit-frame-pointer -mcpu=cortex-a53

KERNEL_C_SRCS := main.c uart.c print.c debug.c handler.c memory.c file.c process.c syscall.c lib.c
KERNEL_C_OBJS := $(KERNEL_C_SRCS:.c=.o)
# boot.o must be first: Raspberry Pi firmware starts at the first byte of
# kernel8.img; an ELF entry point is not present in the raw binary.
KERNEL_OBJS   := boot.o main.o liba.o lib.o uart.o print.o debug.o \
		 handlera.o handler.o mmu.o memory.o file.o process.o syscall.o

-include $(KERNEL_C_OBJS:.o=.d)

.PHONY: all clean install rpi qemu qemu-gdb gdb

all: kernel8.img

install: all config.txt
	@test -d "$(BOOTMNT)" || { echo "Boot volume not found: $(BOOTMNT)"; exit 1; }
	cp -f kernel8.img "$(BOOTMNT)/$(INSTALL_KERNEL_NAME)"
	cp -f config.txt "$(BOOTMNT)/config.txt"
	@cmp -s kernel8.img "$(BOOTMNT)/$(INSTALL_KERNEL_NAME)" || { echo "Installed $(INSTALL_KERNEL_NAME) differs"; exit 1; }
	@cmp -s config.txt "$(BOOTMNT)/config.txt" || { echo "Installed config.txt differs"; exit 1; }
	sync
	@echo "Installed kernel8.img to $(BOOTMNT)/$(INSTALL_KERNEL_NAME)"
	@echo "Installed config.txt to $(BOOTMNT)/config.txt"

rpi: all config.txt
	@test -d "$(BOOTMNT)" || { echo "Boot volume not found: $(BOOTMNT)"; exit 1; }
	cp -f kernel8.img config.txt "$(BOOTMNT)/"
	@cmp -s kernel8.img "$(BOOTMNT)/kernel8.img" || { echo "Installed kernel8.img differs"; exit 1; }
	@cmp -s config.txt "$(BOOTMNT)/config.txt" || { echo "Installed config.txt differs"; exit 1; }
	sync
	@echo "Installed kernel8.img and config.txt to $(BOOTMNT)"

qemu: kernel8.img
	$(QEMU) $(QEMUOPTS)

qemu-gdb: kernel8.img
	@echo "Starting QEMU GDB server on 127.0.0.1:$(GDBPORT)"
	@echo "QEMU GDB server ready"
	$(QEMU) $(QEMUOPTS) -S $(QEMUGDB)

gdb: kernel.elf
	$(GDB) kernel.elf -ex "target remote 127.0.0.1:$(GDBPORT)"

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
	rm -f lib/print.o lib/print.d lib/syscall.o lib/lib.a
	rm -f init/start.o init/main.o init/main.d init/init init/user.bin
	rm -f myinit/start.o myinit/main.o myinit/main.d myinit/init myinit/init.bin
