T113_CROSS ?= arm-none-eabi-
BUILD := build-t113
SRC := src/boards/100ask_t113
KERNEL_BIN ?= ../miniOS/build-t113/minios-kernel.bin

CFLAGS := -g -Os -mcpu=cortex-a7 -marm -mno-unaligned-access \
	-ffreestanding -fno-builtin -fno-common -fno-stack-protector \
	-fno-unwind-tables -fno-asynchronous-unwind-tables -nostdlib -nostartfiles \
	-Wall -Wextra -I$(SRC)
OBJS := $(BUILD)/head.o $(BUILD)/start.o $(BUILD)/early_uart.o \
	$(BUILD)/dram_syterkit.o $(BUILD)/dram.o $(BUILD)/spl.o \
	$(BUILD)/kernel_payload.o

.PHONY: all t113 clean

all: t113
t113: $(BUILD)/minios-t113.bin

$(BUILD):
	mkdir -p $@

$(BUILD)/%.o: $(SRC)/%.c | $(BUILD)
	$(T113_CROSS)gcc $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: $(SRC)/%.S | $(BUILD)
	$(T113_CROSS)gcc $(CFLAGS) -c $< -o $@

$(BUILD)/dram_syterkit.o: CFLAGS += \
	-Wno-unused-parameter -Wno-sign-compare -Wno-unused-but-set-variable

$(BUILD)/kernel_payload.o: $(KERNEL_BIN) | $(BUILD)
	$(T113_CROSS)objcopy -I binary -O elf32-littlearm -B arm $< $@

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
