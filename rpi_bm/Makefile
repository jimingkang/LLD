T113_DISK ?= /dev/disk4
MINIOS_DIR := miniOS
MINIBOOT_DIR := miniBoot
KERNEL_BIN := ../$(MINIOS_DIR)/build-t113/minios-kernel.bin
IMAGE := $(MINIBOOT_DIR)/build-t113/minios-t113.bin

.PHONY: all t113 miniOS miniBoot clean install

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
