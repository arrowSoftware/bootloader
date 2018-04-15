NASM           = nasm
NASM_FLAGS     = -w-orphan-labels -f bin
STAGE1_SOURCES = ../src/stage1.asm
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
	sudo mount -o loop $(BIN)/$(BOOT_IMG) /media/floppy/
	sudo cp $(BIN)/$(STAGE2) /media/floppy/
	sudo umount /media/floppy

clean:
	rm -rf $(BIN)
	rm -f *.bin

# You need to create an empty file that will serve as the final image holding
# the bootloader. The command to create the file is given below.
# sudo dd if=/dev/zero of=bootloader.img bs=512 count=2880

# Now copy the bin file content to the image file
# sudo dd status=noxfer conv=notrunc if=bootloader.bin of=bootloader.img

# mount the bootload.img
# sudo mount -o loop bootloader.img /media/floppy/

# copy the second stage to the mounted image
# cp STAGE2.SYS /media/floppy/

# unount the image
# sudo umount /media/floppy

# run with
# qemu-system-x86_64 bootloader.bin
# or
# sudo qemu-system-x86_64 -drive format=raw,index=0,if=floppy,file=bootloader.img
