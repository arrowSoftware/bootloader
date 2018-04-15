# operatingSystem
OperatingSystem
https://blog.ghaiklor.com/how-to-implement-a-second-stage-boot-loader-80e75ae4270c


### Linux environment

You need to create an empty file that will serve as the final image holding
the bootloader. The command to create the file is given below.
```
 sudo dd if=/dev/zero of=bootloader.img bs=512 count=2880
```
Now copy the bin file content to the image file
```
sudo dd status=noxfer conv=notrunc if=bootloader.bin of=bootloader.img
```

mount the bootloader.img
```
sudo mount -o loop bootloader.img /media/floppy/
```

copy the second stage to the mounted image
```
cp STAGE2.SYS /media/floppy/
```

unount the image
```
sudo umount /media/floppy
```

run with
```
qemu-system-x86_64 bootloader.bin
```
or ( Better option )
```
sudo qemu-system-x86_64 -drive format=raw,index=0,if=floppy,file=bootloader.img
```
