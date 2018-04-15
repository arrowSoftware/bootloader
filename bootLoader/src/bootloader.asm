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
bits    16              ; We are still in 16 bit real mode.

Start:  jmp loader      ; Jump over OEM block

;*******************************************************************************
; OEM Parameter block
;*******************************************************************************
welcome db "Welcome to the Operating System: ", 0 ; The string to print.
bpbOEM  db "BabyGirl" ; This member must be exactally 8 bytes. Tt is the name of
                      ; the OS

bpbBytesPerSector:    DW 512
bpbSectorsPerCluster: DB 1
bpbReservedSectors:   DW 1
bpbNumberOfFATs:      DB 2
bpbRootEntries:       DW 224
bpbTotalSectors:      DW 2880
bpbMedia:             DB 0xF0
bpbSectorsPerFAT:     DW 9
bpbSectorsPerTrack:   DW 18
bpbHeadsPerCylinder:  DW 2
bpbHiddenSectors:     DD 0
bpbTotalSectorsBig:   DD 0
bsDriveNumber:        DB 0
bsUnused:             DB 0
bsExtBootSignature:   DB 0x29
bsSerialNumber:       DD 0xa0a1a2a3
bsVolumeLabel:        DB "FLOPPY "
bsFileSystem:         DB "FAT12   "

;*******************************************************************************
; Prints a string
; DS=>SI: 0 terminated string
;*******************************************************************************
Print:
    lodsb           ; Load next byte from string from SI to AL
    or  al, al      ; Does AL = 0
    jz  PrintDone   ; yes, null terminator found, leave now
    mov ah, 0eh     ; No, print the character
    int 0x10        ; INTERRUPT 0x10 - VIDEO TELETYPE OUTPUT
                        ; AH = 0x0E
                        ; AL = Character to write
                        ; BH - Page Number (Should be 0)
                        ; BL = Foreground color (Graphics Modes Only)
    jmp Print       ; Repeat until null terminator found

PrintDone:
    ret             ; We are done, return now.

loader:
    xor    ax, ax   ; Setup segments to insure they are 0. Remember that
    mov    ds, ax   ; we have ORG 0x7C00. This means all addresses are based
    mov    es, ax   ; from 0x7C00:0. Because the data segments are within the same
                    ; code segment, null them.

    mov si, welcome ; The welcome message to print.
    call Print      ; Call the print function

    mov si, bpbOEM  ; The OS name to print
    call Print      ; Call the print function

    xor ax, ax      ; Clear AX.
    int 0x12        ; INTERRUPT 0x12 - BIOS GET MEMORY SIZE
                        ; Returns: AX = Kilobytes of contiguous memory starting from
                        ; absolute address 0x0. Get the amount of KB from the BIOS

    cli             ; Clear all interrupts
    hlt             ; Halt the system

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
