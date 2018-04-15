NASM       = nasm
NASM_FLAGS = -f bin
SOURCES    = ../src/bootloader.asm
FINAL      = bootloader.bin
BOOT_IMG   = bootloader.img
BIN        = ../bin

all: $(BIN) $(SOURCES) $(FINAL)

$(BIN):
	mkdir -p $@

$(FINAL):
	$(NASM) $(NASM_FLAGS) $(SOURCES) -o $(BIN)/$(FINAL)
	sudo dd if=/dev/zero of=$(BIN)/$(BOOT_IMG) bs=512 count=2880
	sudo dd status=noxfer conv=notrunc if=$(BIN)/$(FINAL) of=$(BIN)/$(BOOT_IMG)

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
