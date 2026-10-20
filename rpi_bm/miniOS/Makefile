RPI_VERSION ?= 3

-include .config
CONFIG_WLAN_XRADIO_XR829 ?= y
CONFIG_WPA2_PSK ?= y
PYTHON ?= python3

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
BOOTMNT ?= /Volumes/bootfs
ARMGNU ?= aarch64-elf
else
BOOTMNT ?= /media/rlk/bootfs
ARMGNU ?= aarch64-linux-gnu
endif

INIT_MMU ?= 1
MMU_DUMP ?= 1

COPS =  -g -O0 -DRPI_VERSION=$(RPI_VERSION) -DINIT_MMU=$(INIT_MMU) -DMMU_DUMP=$(MMU_DUMP) -Wall -Wno-psabi -nostdlib -nostartfiles -ffreestanding \
	   -fno-exceptions -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector \
	   -Isrc/boards/raspberrypi/include -Isrc/include -mgeneral-regs-only

# The kernel is linked in the high half while the embedded EL0 image has a low
# VMA (0x400000).  Symbol references can therefore exceed ADRP's +/-4 GiB range.
COPS += -mcmodel=large

ASMOPS = -Isrc/boards/raspberrypi/include -Isrc/include

BUILD_DIR = build
SRC_DIR = src

ifeq ($(CONFIG_BOARD_100ASK_T113),y)
DEFAULT_IMAGE := t113
else
DEFAULT_IMAGE := kernel8.img
endif

all : $(DEFAULT_IMAGE)

.PHONY: all clean install rpi-install run debug qemu qemu-gdb \
	qemu-gdb-client armstub t113 t113-kernel t113-clean menuconfig \
	100ask_t113_defconfig rpi3_defconfig savedefconfig

menuconfig:
	$(PYTHON) scripts/kconfig/menuconfig.py

100ask_t113_defconfig:
	$(PYTHON) scripts/kconfig/menuconfig.py --defconfig src/arch/arm/configs/100ask_t113_defconfig

rpi3_defconfig:
	$(PYTHON) scripts/kconfig/menuconfig.py --defconfig src/arch/arm64/configs/rpi3_defconfig

savedefconfig:
	@test -f .config || (echo "Run make menuconfig first"; exit 1)
	cp .config defconfig

clean :
	rm -rf $(BUILD_DIR) build-t113 *.img armstub-new.bin

$(BUILD_DIR)/%_c.o: $(SRC_DIR)/%.c
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

$(BUILD_DIR)/%_s.o: $(SRC_DIR)/%.S
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

C_FILES = $(wildcard $(SRC_DIR)/*.c)
C_FILES += $(wildcard $(SRC_DIR)/*/*.c)
C_FILES += $(wildcard $(SRC_DIR)/*/*/*.c)
C_FILES += $(wildcard $(SRC_DIR)/*/*/*/*.c)
C_FILES += $(wildcard $(SRC_DIR)/*/*/*/*/*.c)
C_FILES := $(filter-out $(SRC_DIR)/boards/100ask_t113/% \
	$(SRC_DIR)/drivers/net/% \
	$(SRC_DIR)/drivers/mmc/% \
	$(SRC_DIR)/kernel/fs/% \
	$(SRC_DIR)/kernel/mm/page_alloc.c \
	$(SRC_DIR)/kernel/sched/core.c \
	$(SRC_DIR)/kernel/sync.c \
	$(SRC_DIR)/kernel/syscall.c \
	$(SRC_DIR)/kernel/init/main.c \
	$(SRC_DIR)/net/tftp.c \
	$(SRC_DIR)/lib/wpa_crypto.c,$(C_FILES))

ASM_FILES = $(wildcard $(SRC_DIR)/*.S)
ASM_FILES += $(wildcard $(SRC_DIR)/*/*.S)
ASM_FILES += $(wildcard $(SRC_DIR)/*/*/*.S)
ASM_FILES += $(wildcard $(SRC_DIR)/*/*/*/*.S)
ASM_FILES += $(wildcard $(SRC_DIR)/*/*/*/*/*.S)
ASM_FILES := $(filter-out $(SRC_DIR)/boards/100ask_t113/%,$(ASM_FILES))

OBJ_FILES = $(C_FILES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%_c.o)
OBJ_FILES += $(ASM_FILES:$(SRC_DIR)/%.S=$(BUILD_DIR)/%_s.o)

DEP_FILES = $(OBJ_FILES:%.o=%.d)
-include $(DEP_FILES)

kernel8.img: $(SRC_DIR)/linker.ld $(OBJ_FILES)
	@echo "Building for RPI $(value RPI_VERSION)"
	@echo ""
	$(ARMGNU)-ld -T $(SRC_DIR)/linker.ld -o $(BUILD_DIR)/kernel8.elf $(OBJ_FILES)
	$(ARMGNU)-objcopy $(BUILD_DIR)/kernel8.elf -O binary kernel8.img

T113_DISK ?= /dev/disk4
T113_ROOTFS_DISK ?= $(T113_DISK)s2

# T113 installation is owned by the rpi_bm parent build because miniBoot
# creates the final Boot0 image. Keep this convenience entry point.
install:
	$(MAKE) -C .. install T113_DISK=$(T113_DISK) \
		T113_ROOTFS_DISK=$(T113_ROOTFS_DISK)

rpi-install: kernel8.img armstub-new.bin
	@echo "Deploy to $(value BOOTMNT)"
ifeq ($(RPI_VERSION), 4)
	cp kernel8.img $(BOOTMNT)/kernel8-rpi4.img
else
	cp kernel8.img $(BOOTMNT)/kernel8_minios.img
endif
	cp armstub-new.bin $(BOOTMNT)/
	cp config.txt $(BOOTMNT)/
	sync

armstub/build/armstub_s.o: armstub/src/armstub.S
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

armstub-new.bin: armstub/build/armstub_s.o
	$(ARMGNU)-ld --section-start=.text=0 -o armstub/build/armstub.elf armstub/build/armstub_s.o -e _start
	$(ARMGNU)-objcopy armstub/build/armstub.elf -O binary armstub-new.bin

armstub: armstub-new.bin
	cp armstub-new.bin $(BOOTMNT)/
	sync
QEMU ?= qemu-system-aarch64
QEMU_GDB_PORT ?= 1234
GDB_AARCH64 ?= $(ARMGNU)-gdb
QEMU_FLAGS += -nographic
QEMU_FLAGS += -machine raspi3


qemu run: kernel8.img
	$(QEMU) $(QEMU_FLAGS) -kernel kernel8.img

# Raspberry Pi 3 QEMU debug server.  -S leaves every CPU stopped until GDB
# connects; the raw image is booted while GDB reads symbols from kernel8.elf.
qemu-gdb: kernel8.img
	@echo "QEMU/GDB: waiting on tcp::$(QEMU_GDB_PORT)"
	@echo "Connect with: make qemu-gdb-client QEMU_GDB_PORT=$(QEMU_GDB_PORT)"
	$(QEMU) $(QEMU_FLAGS) -S -gdb tcp::$(QEMU_GDB_PORT) -kernel kernel8.img

qemu-gdb-client: kernel8.img
	$(GDB_AARCH64) $(BUILD_DIR)/kernel8.elf \
		-ex "target remote localhost:$(QEMU_GDB_PORT)"

debug: qemu-gdb

# 100ASK T113-S3 DDR-resident ARMv7 kernel. The SRAM Boot0/SPL lives in
# ../miniBoot and embeds the binary produced here.
T113_CROSS ?= arm-none-eabi-
T113_BUILD := build-t113
T113_SRC := src/boards/100ask_t113
T113_KERNEL_SRC := src/kernel
T113_USER_SRC := user-t113
T113_KERNEL_INCLUDE := src/include/t113
T113_COMMON_CFLAGS := -g -Os -mcpu=cortex-a7 -marm -mno-unaligned-access \
	-ffreestanding -fno-builtin -fno-common -fno-stack-protector \
	-fno-unwind-tables -fno-asynchronous-unwind-tables -nostdlib -nostartfiles \
	-Wall -Wextra

T113_CFLAGS := $(T113_COMMON_CFLAGS) -I$(T113_KERNEL_INCLUDE) \
	-Isrc/include -Isrc/include/net
ifneq ($(wildcard src/include/generated/autoconf.h),)
T113_CFLAGS += -include src/include/generated/autoconf.h
endif
T113_USER_CFLAGS := $(T113_COMMON_CFLAGS) -I$(T113_USER_SRC)/include -fno-pic
T113_OBJS := $(T113_BUILD)/kernel_entry.o $(T113_BUILD)/uart.o \
	$(T113_BUILD)/exception.o $(T113_BUILD)/gic.o \
	$(T113_BUILD)/timer.o $(T113_BUILD)/mmu.o \
	$(T113_BUILD)/kernel/mm/page_alloc.o $(T113_BUILD)/user_vm.o \
	$(T113_BUILD)/kernel/sched/core.o $(T113_BUILD)/kernel/sync.o \
	$(T113_BUILD)/kobject.o \
	$(T113_BUILD)/device.o $(T113_BUILD)/platform_bus.o \
	$(T113_BUILD)/board.o $(T113_BUILD)/driver_model.o \
	$(T113_BUILD)/gpio.o $(T113_BUILD)/delay.o \
	$(T113_BUILD)/bootpack.o \
	$(T113_BUILD)/switch.o \
	$(T113_BUILD)/fork_entry.o \
	$(T113_BUILD)/kernel/syscall.o $(T113_BUILD)/kernel/init/main.o \
	$(T113_BUILD)/fs/vfs.o \
	$(T113_BUILD)/fs/minifs.o $(T113_BUILD)/fs/devfs.o \
	$(T113_BUILD)/fs/bootfs.o \
	$(T113_BUILD)/fs/rootdev.o $(T113_BUILD)/drivers/mmc/sunxi-sd.o \
	$(T113_BUILD)/platform_kernel.o

ifeq ($(CONFIG_I2C),y)
T113_OBJS += $(T113_BUILD)/i2c_core.o $(T113_BUILD)/twi.o
endif
ifeq ($(CONFIG_VIDEO),y)
T113_OBJS += $(T113_BUILD)/csi.o
endif
ifeq ($(CONFIG_VIDEO_OV5640),y)
T113_OBJS += $(T113_BUILD)/ov5640.o
endif
ifeq ($(CONFIG_MMC),y)
T113_OBJS += $(T113_BUILD)/drivers/mmc/core.o \
	$(T113_BUILD)/drivers/mmc/host/sunxi-smhc.o
endif

ifeq ($(CONFIG_WLAN_XRADIO_XR829),y)
T113_OBJS += $(T113_BUILD)/drivers/net/wireless/xradio/core.o \
	$(T113_BUILD)/drivers/net/wireless/xradio/wsm.o \
	$(T113_BUILD)/drivers/net/wireless/xradio/sta.o
endif
ifeq ($(CONFIG_WPA2_PSK),y)
T113_OBJS += $(T113_BUILD)/lib/wpa_crypto.o
endif
ifeq ($(CONFIG_TFTP_CLIENT),y)
T113_OBJS += $(T113_BUILD)/net/tftp.o \
	$(T113_BUILD)/miniboot_update.o
endif
T113_USER_LIB_OBJS := $(T113_BUILD)/user/usys.o \
	$(T113_BUILD)/user/libc/libc.o
T113_USER_LIB := $(T113_BUILD)/user/libc.a
T113_USER_COMMON := $(T113_BUILD)/user/start.o
T113_USER_PROGRAMS := sh ls echo pwd cat sleep uptime grep wc forktest zombie
T113_USER_BINARIES := $(addprefix $(T113_BUILD)/_,$(T113_USER_PROGRAMS))

t113: t113-kernel
t113-kernel: $(T113_BUILD)/minios-kernel.bin $(T113_BUILD)/minifs.img

$(T113_BUILD):
	mkdir -p $@

$(T113_BUILD)/%.o: $(T113_SRC)/%.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/fs/%.o: $(T113_KERNEL_SRC)/fs/%.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/kernel/%.o: $(T113_KERNEL_SRC)/%.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/drivers/mmc/%.o: src/drivers/mmc/%.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -DMINIOS_KERNEL -c $< -o $@

$(T113_BUILD)/drivers/mmc/host/%.o: src/drivers/mmc/host/%.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/%.o: $(T113_SRC)/%.S | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/drivers/net/wireless/xradio/core.o: src/drivers/net/wireless/xradio/xr829_core.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/drivers/net/wireless/xradio/wsm.o: src/drivers/net/wireless/xradio/wsm.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/drivers/net/wireless/xradio/sta.o: src/drivers/net/wireless/xradio/sta.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/lib/wpa_crypto.o: src/lib/wpa_crypto.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/net/tftp.o: src/net/tftp.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_CFLAGS) -c $< -o $@

$(T113_BUILD)/user/%.o: $(T113_USER_SRC)/%.c | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_USER_CFLAGS) -c $< -o $@

$(T113_BUILD)/user/%.o: $(T113_USER_SRC)/%.S | $(T113_BUILD)
	mkdir -p $(@D)
	$(T113_CROSS)gcc $(T113_USER_CFLAGS) -c $< -o $@

$(T113_USER_LIB): $(T113_USER_LIB_OBJS)
	$(T113_CROSS)ar rcs $@ $^

$(T113_BUILD)/user-init.elf: $(T113_USER_COMMON) $(T113_BUILD)/user/init.o \
		$(T113_USER_LIB) $(T113_USER_SRC)/linker.ld
	$(T113_CROSS)ld -T $(T113_USER_SRC)/linker.ld -Map $(T113_BUILD)/user-init.map \
		-o $@ $(T113_USER_COMMON) $(T113_BUILD)/user/init.o $(T113_USER_LIB)

$(T113_BUILD)/_init: $(T113_BUILD)/user-init.elf
	$(T113_CROSS)objcopy --strip-debug $< $@

$(T113_BUILD)/user-echo.elf: $(T113_USER_COMMON) $(T113_BUILD)/user/echo.o \
		$(T113_USER_LIB) \
		$(T113_USER_SRC)/linker.ld
	$(T113_CROSS)ld -T $(T113_USER_SRC)/linker.ld -Map $(T113_BUILD)/user-echo.map \
		-o $@ $(T113_USER_COMMON) $(T113_BUILD)/user/echo.o $(T113_USER_LIB)

$(T113_BUILD)/_echo: $(T113_BUILD)/user-echo.elf
	$(T113_CROSS)objcopy --strip-debug $< $@

$(T113_BUILD)/user-%.elf: $(T113_USER_COMMON) $(T113_BUILD)/user/%.o \
		$(T113_USER_LIB) $(T113_USER_SRC)/linker.ld
	$(T113_CROSS)ld -T $(T113_USER_SRC)/linker.ld -Map $(T113_BUILD)/user-$*.map \
		-o $@ $(T113_USER_COMMON) $(T113_BUILD)/user/$*.o $(T113_USER_LIB)

$(T113_BUILD)/_%: $(T113_BUILD)/user-%.elf
	$(T113_CROSS)objcopy --strip-debug $< $@

$(T113_BUILD)/mkfs_minifs: tools/mkfs_minifs.c | $(T113_BUILD)
	$(CC) -O2 -Wall -Wextra -Werror $< -o $@

$(T113_BUILD)/minifs.img: $(T113_BUILD)/mkfs_minifs $(T113_BUILD)/_init \
		$(T113_USER_BINARIES)
	$(T113_BUILD)/mkfs_minifs $@ $(T113_BUILD)/_init \
		$(T113_USER_BINARIES)

$(T113_BUILD)/minifs_image.o: $(T113_BUILD)/minifs.img
	$(T113_CROSS)objcopy -I binary -O elf32-littlearm -B arm $< $@

$(T113_BUILD)/minios-kernel.elf: $(T113_OBJS) $(T113_SRC)/linker.ld
	$(T113_CROSS)ld -T $(T113_SRC)/linker.ld -Map $(T113_BUILD)/minios-t113.map \
		-o $@ $(T113_OBJS)

$(T113_BUILD)/minios-kernel.bin: $(T113_BUILD)/minios-kernel.elf
	$(T113_CROSS)objcopy -O binary $< $@

t113-clean:
	rm -rf $(T113_BUILD)
