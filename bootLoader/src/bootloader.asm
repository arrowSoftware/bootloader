;*******************************************************************************
;   boot1.asm
;       - A simple bootloader
;   Tyler Gajewski 4/14/18
;*******************************************************************************

; The BIOS loads us at 0x7C00. The above code tells NASM to insure all addresses
; are relative to 0x7C00. This means, the first instruction will be at 0x7C00.
org 0x7C00              ; We are loaded by BIOS at 0x7C00.

; All x86 compatible computers boot into 16 bit mode. This means: We are limited
; to 1 MB (+64k) of memory.
bits 16                 ; We are still in 16 bit real mode.

Start:  jmp loader      ; Jump over OEM block

;*******************************************************************************
; OEM Parameter block / BIOS Parameter block
;*******************************************************************************
msg db "Welcome to the Operating System: ", 0 ; The string to print.
bpbOEM db "BabyGirl" ; This member must be exactally 8 bytes. Tt is the name of
                     ; the OS

bpbBytesPerSector:    DW 512    ; Number of bytes that represent a sector
bpbSectorsPerCluster: DB 1      ; Number of sectors per cluster
bpbReservedSectors:   DW 1      ; Number of sectors included in FAT12, not part
                                ; of root directory
bpbNumberOfFATs:      DB 2      ; number of File Allocation Tables (FATs) on the
                                ; disk.
bpbRootEntries:       DW 224    ; Floppy Disks have a maximum of 224 directories
                                ; within its Root Directory.
bpbTotalSectors:      DW 2880   ; there are 2,880 sectors in a floppy disk.
bpbMedia:             DB 0xF0   ; Bits 0: Sides/Heads =
                                ;   0 if it is single sided,
                                ;   1 if its double sided
                                ; Bits 1: Size =
                                ;   0 if it has 9 sectors per FAT,
                                ;   1 if it has 8.
                                ; Bits 2: Density =
                                ;   0 if it has 80 tracks,
                                ;   1 if it is 40 tracks.
                                ; Bits 3: Type =
                                ;   0 if its a fixed disk (Such as hard drive),
                                ;   1 if removable (Such as floppy drive)
                                ;   Bits 4 to 7 are unused, and always 1.
                                ; We have a single sided, 9 sectors per FAT,
                                ; 80 tracks, and is a movable disk.
bpbSectorsPerFAT:     DW 9      ; Sectors per FAT
bpbSectorsPerTrack:   DW 18     ; There are 18 sectors per track
bpbHeadsPerCylinder:  DW 2      ; There are 2 heads that represents a cylinder
bpbHiddenSectors:     DD 0      ; Number of sectors from the start of the
                                ; physical disk and the start of the volume.
bpbTotalSectorsBig:   DD 0
bsDriveNumber:        DB 0      ; floppy drive is drive 0
bsUnused:             DB 0
bsExtBootSignature:   DB 0x29   ; The Boot Signiture represents the type and
                                ; version of this BIOS Parameter Block
                                ; (This OEM Table) is. The values are:
                                ;   0x28 and 0x29 indicate this is a MS/PC-DOS
                                ;   version 4.0 Bios Parameter Block (BPB)
bsSerialNumber:       DD 0xa0a1a2a3 ; The serial number is unique to that
                                    ; particular floppy disk
bsVolumeLabel:        DB "BOS FLOPPY "
bsFileSystem:         DB "FAT12   "

;*******************************************************************************
; Bootloader entry point
;*******************************************************************************
loader:

; Before reading any sectors, we have to insure we begin from sector 0. We dont
; know what sector the floppy controller is reading from. This is bad, as it can
; change from any time you reboot. Reseting the disk to sector 0 will insure you
; are reading the same sectors each time.
.Reset:
    mov ah, 0       ; reset floppy disk functions
    mov dl, 0       ; Drive 0 is floppy drive
    int 0x13        ; INTERRUPT 0x13/AH=0x0 - DISK : RESET DISK SYSTEM
                    ;   AH = 0x0
                    ;   DL = Drive to Reset
                    ;   Returns:
                    ;   AH = Status Code
                    ;   CF (Carry Flag) is c
                    ; INTERRUPT 0x13/AH=0x02 - DISK : READ SECTOR(S) INTO MEMORY
                    ;   AH = 0x02
                    ;   AL = Number of sectors to read
                    ;   CH = Low eight bits of cylinder number
                    ;   CL = Sector Number (Bits 0-5). Bits 6-7 are for hard disks only
                    ;   DH = Head Number
                    ;   DL = Drive Number (Bit 7 set for hard disks)
                    ;   ES:BX = Buffer to read sectors to
                    ;   Returns:
                    ;   AH = Status Code
                    ;   AL = Number of sectors read
                    ;   CF = set if failure, cleared is successfull
    jc .Reset       ; If carry flag (CF) is setm there was an error, try to
                    ; reset again

    mov ax, 0x1000  ; We are going to read sector into address 0x1000:0
    mov es, ax
    xor bx, bx

    mov ah, 02      ; read floppy sector function
    mov al, 1       ; read 1 sector
    mov ch, 1       ; we are reading the second sector past us, so its still
                    ; on track 1
    mov cl, 2       ; sector to read (The second sector)
    mov dh, 0       ; head humber
    mov dl, 0       ; drive number, remember drive 0 is floppy drive
    int 0x13        ; Call BIOS - read the sector
    jmp 0x1000:0x0  ; Jump to execute the sector

; NASM, the dollar operator ($) represents the address of the current line.
; $$ represents the address of the first instruction (Should be 0x7C00). So,
; $­$$ returns the number of bytes from the current line to the start
; (In this case, the size of the program).
times 510 - ($-$$) db 0 ; We have to be 512 bytes, clear the rest of the bytes
                        ; with 0

; Remember that the BIOS INT 0x19 searches for a bootable disk. How does it know
; if the disk is bootable? The boot signiture. If the 511 byte is 0xAA and the
; 512 byte is 0x55, INT 0x19 will load and execute the bootloader. Because the
; boot signiture must be the last two bytes in the bootsector, We use the times
; keyword to calculate the size different to fill in up to the 510th byte,
; rather then the 512th byte.
dw 0xAA55 ; Boot signature.

;*******************************************************************************
; End of sector 1, beginning sector 2
;*******************************************************************************

org 0x1000  ; This sector is loaded at 0x1000:0 by the bootloader

cli         ; Clear all interrupts
hlt         ; Halt the system

; The root directory is a table of 32 byte values that represent information
; reguarding file and directories. This 32 byte value uses the format:
;   Bytes 0-7 : DOS File name (Padded with spaces)
;   Bytes 8-10 : DOS File extension (Padded with spaces)
;   Bytes 11 : File attributes. This is a bit pattern:
;       Bit 0 : Read Only
;       Bit 1 : Hidden
;       Bit 2 : System
;       Bit 3 : Volume Label
;       Bit 4 : This is a subdirectory
;       Bit 5 : Archive
;       Bit 6 : Device (Internal use)
;       Bit 6 : Unused
;   Bytes 12 : Unused
;   Bytes 13 : Create time in ms
;   Bytes 14-15 : Created time, using the following format:
;       Bit 0-4 : Seconds (0-29)
;       Bit 5-10 : Minutes (0-59)
;       Bit 11-15 : Hours (0-23)
;   Bytes 16-17 : Created year in the following format:
;       Bit 0-4 : Year (0=1980; 127=2107
;       Bit 5-8 : Month (1=January; 12=December)
;       Bit 9-15 : Hours (0-23)
;   Bytes 18-19 : Last access date (Uses same format as above)
;   Bytes 20-21 : EA Index (Used in OS/2 and NT, dont worry about it)
;   Bytes 22-23 : Last Modified time (See byte 14-15 for format)
;   Bytes 24-25 : Last modified date (See bytes 16-17 for format)
;   Bytes 26-27 : First Cluster
;   Bytes 28-32 : File Size


;xor ax, ax      ; Clear AX.
;int 0x12        ; INTERRUPT 0x12 - BIOS GET MEMORY SIZE
                ;   Returns: AX = Kilobytes of contiguous memory starting from
                ;   absolute address 0x0. Get the amount of KB from the BIOS
