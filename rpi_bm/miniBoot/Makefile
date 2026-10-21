T113_CROSS ?= arm-none-eabi-
BUILD := build-t113
SRC := src/boards/100ask_t113
KERNEL_BIN ?= ../miniOS/build-t113/minios-kernel.bin
# 0 (default): SPL loads the kernel from the SD bootpack at 128 KiB.
# 1: embed the kernel in the SPL image (FEL / xfel boot, kernel must fit SRAM).
EMBED_KERNEL ?= 0
# Extra bootpack entries, e.g. "fw_xr829=path/fw_xr829.bin@0x42000000".
BOOTPACK_EXTRA ?=

CFLAGS := -g -Os -mcpu=cortex-a7 -marm -mno-unaligned-access \
	-ffreestanding -fno-builtin -fno-common -fno-stack-protector \
	-fno-unwind-tables -fno-asynchronous-unwind-tables -nostdlib -nostartfiles \
	-Wall -Wextra -I$(SRC)
OBJS := $(BUILD)/head.o $(BUILD)/start.o $(BUILD)/early_uart.o \
	$(BUILD)/dram_syterkit.o $(BUILD)/dram.o $(BUILD)/sd.o $(BUILD)/fat32.o $(BUILD)/spl.o \
	$(BUILD)/kernel_payload.o

.PHONY: all t113 clean bootpack FORCE

all: t113
t113: $(BUILD)/minios-t113.bin bootpack
bootpack: $(BUILD)/bootpack.bin

$(BUILD):
	mkdir -p $@

$(BUILD)/%.o: $(SRC)/%.c | $(BUILD)
	$(T113_CROSS)gcc $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: $(SRC)/%.S | $(BUILD)
	$(T113_CROSS)gcc $(CFLAGS) -c $< -o $@

$(BUILD)/dram_syterkit.o: CFLAGS += \
	-Wno-unused-parameter -Wno-sign-compare -Wno-unused-but-set-variable

ifeq ($(EMBED_KERNEL),1)
$(BUILD)/payload.bin: $(KERNEL_BIN) FORCE | $(BUILD)
	cp $< $@
else
# objcopy rejects empty input: a 4-byte placeholder means "no kernel".
$(BUILD)/payload.bin: FORCE | $(BUILD)
	printf '\000\000\000\000' > $@
endif

$(BUILD)/kernel_payload.o: $(BUILD)/payload.bin | $(BUILD)
	$(T113_CROSS)objcopy -I binary -O elf32-littlearm -B arm $< $@

$(BUILD)/mkbootpack: tools/mkbootpack.c $(SRC)/bootpack.h | $(BUILD)
	$(CC) -O2 -Wall -Wextra $< -o $@

$(BUILD)/bootpack.bin: $(KERNEL_BIN) $(BUILD)/mkbootpack FORCE
	$(BUILD)/mkbootpack $@ kernel=$(KERNEL_BIN)@0x40200000 $(BOOTPACK_EXTRA)

FORCE:

$(BUILD)/miniboot-t113.elf: $(OBJS) $(SRC)/linker.ld
	$(T113_CROSS)ld -T $(SRC)/linker.ld -Map $(BUILD)/miniboot-t113.map \
		-o $@ $(OBJS)

$(BUILD)/mksunxi: $(SRC)/mksunxi.c | $(BUILD)
	$(CC) -O2 -Wall -Wextra $< -o $@

$(BUILD)/minios-t113.bin: $(BUILD)/miniboot-t113.elf $(BUILD)/mksunxi
	$(T113_CROSS)objcopy -O binary $< $@
	$(BUILD)/mksunxi $@ 512

clean:
	rm -rf $(BUILD)
