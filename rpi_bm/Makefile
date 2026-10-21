T113_DISK ?= /dev/disk4
T113_FAT_MOUNT ?= /Volumes/bootfs
T113_ROOTFS_DISK ?= $(T113_DISK)s2
QEMU_GDB_PORT ?= 1234
MINIOS_DIR := miniOS
MINIBOOT_DIR := miniBoot
KERNEL_BIN := ../$(MINIOS_DIR)/build-t113/minios-kernel.bin
IMAGE := $(MINIBOOT_DIR)/build-t113/minios-t113.bin
BOOTPACK := $(MINIBOOT_DIR)/build-t113/bootpack.bin

.PHONY: all t113 miniOS miniBoot clean install install-firmware install-rootfs qemu qemu-gdb qemu-gdb-client

all: t113
t113: miniBoot

miniOS:
	$(MAKE) -C $(MINIOS_DIR) t113-kernel

miniBoot: miniOS
	$(MAKE) -C $(MINIBOOT_DIR) t113 KERNEL_BIN=$(KERNEL_BIN) \
		EMBED_KERNEL=$(EMBED_KERNEL) BOOTPACK_EXTRA='$(BOOTPACK_EXTRA)'

# EMBED_KERNEL=1 builds the old single-image SPL for FEL/xfel boot.
EMBED_KERNEL ?= 0
# XR829 images are ordinary files in the FAT32 root.  They are deliberately
# not packed into bootpack, so they can be replaced without rebuilding it.
XR829_FW_DIR ?= $(CURDIR)/firmware/xr829
BOOTPACK_EXTRA ?=

clean:
	$(MAKE) -C $(MINIBOOT_DIR) clean
	$(MAKE) -C $(MINIOS_DIR) t113-clean

# SD layout: Boot0 (miniBoot SPL) at 8 KiB, bootpack (kernel + extra
# images, see miniBoot bootpack.h) at 128 KiB. Both must end before the
# first partition (usually 1 MiB).
install-firmware:
	@echo "Mounting FAT32 partition(s) on $(T113_DISK)"
	diskutil mountDisk "$(T113_DISK)"
	@test -d "$(T113_FAT_MOUNT)" || { echo "FAT32 mount $(T113_FAT_MOUNT) not found"; exit 1; }
	@test -f "$(XR829_FW_DIR)/boot_xr829.bin" -a \
	      -f "$(XR829_FW_DIR)/fw_xr829.bin" -a \
	      -f "$(XR829_FW_DIR)/sdd_xr829.bin" || { echo "XR829 firmware files missing"; exit 1; }
	cp "$(XR829_FW_DIR)/boot_xr829.bin" "$(T113_FAT_MOUNT)/boot_xr829.bin"
	cp "$(XR829_FW_DIR)/fw_xr829.bin" "$(T113_FAT_MOUNT)/fw_xr829.bin"
	cp "$(XR829_FW_DIR)/sdd_xr829.bin" "$(T113_FAT_MOUNT)/sdd_xr829.bin"
	@# WiFi settings (ssid=, psk=, optional ip=/netmask=/gateway=); kept in
	@# the git-ignored firmware/ directory so the passphrase is never committed.
	@if [ -f "$(CURDIR)/firmware/wifi.txt" ]; then \
		cp "$(CURDIR)/firmware/wifi.txt" "$(T113_FAT_MOUNT)/wifi.txt"; \
		echo "cp firmware/wifi.txt $(T113_FAT_MOUNT)/wifi.txt"; fi
	@# The SPL boots /kernel_minios.img from FAT32 in preference to the
	@# bootpack copy (miniOS "tftp" updates it), so keep both identical.
	@if [ -f "$(MINIOS_DIR)/build-t113/kernel_minios.img" ]; then \
		cp "$(MINIOS_DIR)/build-t113/kernel_minios.img" "$(T113_FAT_MOUNT)/kernel_minios.img"; \
		echo "cp kernel_minios.img $(T113_FAT_MOUNT)/kernel_minios.img"; fi
	sync

install-rootfs: miniOS
	@test -e "$(T113_ROOTFS_DISK)" || { echo "Root partition $(T113_ROOTFS_DISK) not found"; exit 1; }
	@test -s "$(MINIOS_DIR)/build-t113/minifs.img" || { echo "minifs image is missing or empty"; exit 1; }
	@echo "Writing current minifs root filesystem (init, sh and commands) to $(T113_ROOTFS_DISK)"
	sudo dd if=$(MINIOS_DIR)/build-t113/minifs.img of=$(T113_ROOTFS_DISK) bs=1024 conv=fsync
	sync

install: t113
	@echo "WARNING: writing $(IMAGE) at 8 KiB and $(BOOTPACK) at 128 KiB to $(T113_DISK)"
	@test -e "$(T113_DISK)" || { echo "Device $(T113_DISK) does not exist"; exit 1; }
	sudo dd if=$(IMAGE) of=$(T113_DISK) bs=1024 seek=8 conv=fsync
	sudo dd if=$(BOOTPACK) of=$(T113_DISK) bs=1024 seek=128 conv=fsync
	sync
	$(MAKE) install-firmware
	$(MAKE) install-rootfs

# QEMU models Raspberry Pi 3, not the Allwinner T113-S3.  These targets
# therefore debug miniOS's RPi3 build and are forwarded for convenience.
qemu:
	$(MAKE) -C $(MINIOS_DIR) qemu

qemu-gdb:
	$(MAKE) -C $(MINIOS_DIR) qemu-gdb QEMU_GDB_PORT=$(QEMU_GDB_PORT)

qemu-gdb-client:
	$(MAKE) -C $(MINIOS_DIR) qemu-gdb-client QEMU_GDB_PORT=$(QEMU_GDB_PORT)
