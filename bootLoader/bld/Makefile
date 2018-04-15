NASM           = nasm
NASM_FLAGS     = -f bin
STAGE1_SOURCES = ../src/bootloader.asm
STAGE2_SOURCES = ../src/stage2.asm
STAGE1         = bootloader.bin
STAGE2         = STAGE2.SYS
BOOT_IMG       = bootloader.img
BIN            = ../bin

all: $(BIN) $(STAGE1_SOURCES) $(STAGE1) $(STAGE2_SOURCES) $(STAGE2)

$(BIN):
	mkdir -p $@

$(STAGE1):
	$(NASM) $(NASM_FLAGS) $(STAGE1_SOURCES) -o $(BIN)/$(STAGE1)
	sudo dd if=/dev/zero of=$(BIN)/$(BOOT_IMG) bs=512 count=2880
	sudo dd status=noxfer conv=notrunc if=$(BIN)/$(STAGE1) of=$(BIN)/$(BOOT_IMG)

$(STAGE2):
	$(NASM) $(NASM_FLAGS) $(STAGE2_SOURCES) -o $(BIN)/$(STAGE2)

clean:
	rm -rf $(BIN)
	rm -f *.bin

# You need to create an empty file that will serve as the final image holding
# the bootloader. The command to create the file is given below.
# sudo dd if=/dev/zero of=bootloader.img bs=512 count=2880

# Now copy the bin file content to the image file
# sudo dd status=noxfer conv=notrunc if=bootloader.bin of=bootloader.img

# run with
# qemu-system-x86_64 bootloader.bin
# or
# sudo qemu-system-x86_64 -drive format=raw,index=0,if=floppy,file=bootloader.img
