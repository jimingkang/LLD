T113_DISK ?= /dev/disk4
QEMU_GDB_PORT ?= 1234
MINIOS_DIR := miniOS
MINIBOOT_DIR := miniBoot
KERNEL_BIN := ../$(MINIOS_DIR)/build-t113/minios-kernel.bin
IMAGE := $(MINIBOOT_DIR)/build-t113/minios-t113.bin

.PHONY: all t113 miniOS miniBoot clean install qemu qemu-gdb qemu-gdb-client

all: t113
t113: miniBoot

miniOS:
	$(MAKE) -C $(MINIOS_DIR) t113-kernel

miniBoot: miniOS
	$(MAKE) -C $(MINIBOOT_DIR) t113 KERNEL_BIN=$(KERNEL_BIN)

clean:
	$(MAKE) -C $(MINIBOOT_DIR) clean
	$(MAKE) -C $(MINIOS_DIR) t113-clean

install: t113
	@echo "WARNING: writing $(IMAGE) to $(T113_DISK) at 8 KiB"
	@test -e "$(T113_DISK)" || { echo "Device $(T113_DISK) does not exist"; exit 1; }
	sudo dd if=$(IMAGE) of=$(T113_DISK) bs=1024 seek=8 conv=fsync
	sync

# QEMU models Raspberry Pi 3, not the Allwinner T113-S3.  These targets
# therefore debug miniOS's RPi3 build and are forwarded for convenience.
qemu:
	$(MAKE) -C $(MINIOS_DIR) qemu

qemu-gdb:
	$(MAKE) -C $(MINIOS_DIR) qemu-gdb QEMU_GDB_PORT=$(QEMU_GDB_PORT)

qemu-gdb-client:
	$(MAKE) -C $(MINIOS_DIR) qemu-gdb-client QEMU_GDB_PORT=$(QEMU_GDB_PORT)
