.PHONY: all clean dir bootloader kernel a_img

A_IMG = a.img
BIN_DIR = bin
LIB_DIR = lib

BOOTLOADER = bootloader.bin
BOOTLOADER_ASM = $(wildcard bootloader/*.s)

KERNEL_C = $(wildcard kernel/*.c) $(wildcard mm/*.c) $(wildcard lib/*.c)
KERNEL_ASM = $(wildcard kernel/*.s) $(filter-out lib/syscall.s, $(wildcard lib/*.s))

KERNEL = kernel.bin
KERNEL_OBJS = $(subst .c,.o,$(KERNEL_C)) $(subst .s,.o,$(KERNEL_ASM))

LIBC = libc.a
LIBC_OBJS = $(subst .c,.o,$(wildcard lib/*.c)) $(subst .s,.o,$(wildcard lib/*.s))

INCLUDE = -I. -Ilib
CFLAGS = -std=c99 -m32 -Wall -Wextra -nostdinc -fno-builtin -fno-stack-protector $(INCLUDE)

all: dir bootloader kernel libc a_img disk

clean:
	@ rm -f kernel/*.o mm/*.o lib/*.o lib/*.a $(BIN_DIR)/* $(A_IMG)

dir:
	@ mkdir -p $(BIN_DIR)

bootloader: $(BOOTLOADER_ASM)
	@ echo "compiling $< ..."
	@ nasm $< -o $(BIN_DIR)/$(BOOTLOADER)

kernel: $(KERNEL_OBJS)
	@ echo "linking $(BIN_DIR)/$(KERNEL) ..."
	@ ld -m elf_i386 -Ttext-seg=0xC0100000 $(KERNEL_OBJS) -s -o $(BIN_DIR)/$(KERNEL)

libc: $(LIBC_OBJS)
	@ echo "ar $(LIB_DIR)/$(LIBC) ..."
	@ ar -r $(LIB_DIR)/$(LIBC) $(LIBC_OBJS) > /dev/null 2>&1

%.o : %.s
	@ echo "compiling $< ..."
	@ nasm -felf $< -o $@

%.o : %.c
	@ echo "compiling $< ..."
	@ gcc $(CFLAGS) -c $< -o $@

a_img: bootloader kernel
	@ echo "making $(A_IMG) ..."
	@ dd if=/dev/zero of=$(A_IMG) bs=512 count=2880 > /dev/null 2>&1
	@ dd if=$(BIN_DIR)/$(BOOTLOADER) of=$(A_IMG) conv=notrunc bs=512 count=1 > /dev/null 2>&1
	@ dd if=$(BIN_DIR)/$(KERNEL) of=$(A_IMG) seek=512 conv=notrunc bs=1 > /dev/null 2>&1

disk:
	@ echo "making disk ..."
	@ dd if=/dev/zero of=disk bs=512 count=20160 > /dev/null 2>&1
