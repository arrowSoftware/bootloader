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

Start:
    cli                 ; Clear all interrupts.
    hlt                 ; Halt the system.

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
dw 0xAA55               ; Boot signature.
