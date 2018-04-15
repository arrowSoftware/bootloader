;*******************************************************************************
;   stage1.asm
;       - A simple bootloader
;   Tyler Gajewski 4/14/18
;*******************************************************************************

; All x86 compatible computers boot into 16 bit mode. This means: We are limited
; to 1 MB (+64k) of memory.
bits 16         ; We are still in 16 bit real mode.

org 0           ; we will set regisers later

Start: jmp main ; Jump over OEM block

;*******************************************************************************
; OEM Parameter block / BIOS Parameter block
;*******************************************************************************
; BPB Begins 3 bytes from start. We do a far jump, which is 3 bytes in size.
; If you use a short jump, add a "nop" after it to offset the 3rd byte.
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
; Prints a string
; DS=>SI: 0 terminated string
;*******************************************************************************
Print:
    lodsb           ; Load next byte from string from SI to AL
    or  al, al      ; Does AL = 0
    jz  PrintDone   ; yes, null terminator found, leave now
    mov ah, 0eh     ; No, print the character
    int 0x10        ; INTERRUPT 0x10 - VIDEO TELETYPE OUTPUT
                    ;    AH = 0x0E
                    ;    AL = Character to write
                    ;    BH - Page Number (Should be 0)
                    ;    BL = Foreground color (Graphics Modes Only)
    jmp Print       ; Repeat until null terminator found

PrintDone:
    ret             ; We are done, return now.

;*******************************************************************************
; Reads a series of sectors.
;   CX    = Number of sectors to read.
;   AX    = Starting sector
;   ES:BX = Buffer tp read to
;*******************************************************************************
ReadSectors:
    .MAIN
        mov di, 0x0005                  ; Five retries for error
    .SECTORLOOP
        push ax,
        push bx,
        push cx,
        call LBACHS                     ; Convert Starting sector to CHS
        mov ah, 0x02                    ; BIOS read sector
        mov al, 0x01                    ; Read one sector
        mov ch, BYTE[absoluteTrack]     ; Track
        mov cl, BYTE[absoluteSector]    ; Sector
        mov dh, BYTE[absoluteHead]      ; Head
        mov dl, BYTE[bsDriveNumber]     ; Drive
        int 0x13                        ; Invoke BIOS
        jnc .SUCCESS                    ; Test for read error
        xor ax, ax                      ; Bios reset disk
        int 0x13                        ; Invoke BIOS
        dec di                          ; Decrement error counter
        pop cx
        pop bx
        pop ax
        jnz .SECTORLOOP                 ; Attempt to read again
        int 0x18
    .SUCCESS
        mov si, msgProgress
        call Print
        pop cx
        pop bx
        pop ax
        add bx, WORD[bpbBytesPerSector] ; Queue next Buffer
        inc ax                          ; Increment next sector
        loop .MAIN                      ; read next sector
        ret

;*******************************************************************************
; Convert CHS to LBA
; LBA = (cluster - 2) * sectors per cluster
;*******************************************************************************
ClusterLBA:
    sub ax, 0x0002
    xor cx, cx                          ; Zero base cluster number
    mov cl, BYTE[bpbSectorsPerCluster]  ; Convert byte to word
    mul cx
    add ax, WORD[datasector]            ; Base data sector
    ret

;*******************************************************************************
; Convert LBA to CHS
; AX = LBA Address to convert
;
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
;*******************************************************************************
LBACHS:
    xor dx, dx                      ; Prepare dx:ax for operation
    div WORD[bpbSectorsPerTrack]    ; calculate
    inc dl                          ; Adjust for sector 0
    mov BYTE[absoluteSector], dl
    xor dx, dx                      ; Prepare dx:ax for operation
    div WORD[bpbHeadsPerCylinder]   ; calculate
    mov BYTE[absoluteHead], dl
    mov BYTE[absoluteTrack], al
    ret

;*******************************************************************************
; Bootloader entry point
;*******************************************************************************
main:
    ;***************************************************************************
    ; Code located at 0000:7C00, adjust some registers
    ;***************************************************************************
    cli            ; Disable interrupts
    mov ax, 0x07C0 ; Setup registers to point to our segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ;***************************************************************************
    ; Create the stack
    ;***************************************************************************
    mov ax, 0x0000  ; Set the stack
    mov ss, ax
    mov sp, 0xFFFF
    sti             ; Restore interrupts

    ;***************************************************************************
    ; Display loading message
    ;***************************************************************************
    mov si, msgLoading
    call Print

    ;***************************************************************************
    ; Load root directory table
    ;***************************************************************************
    LOAD_ROOT:
        ; Compute size of root directory and store in cx
        xor cx, cx
        xor dx, dx
        mov ax, 0x0020  ; 32 byte directory entry
        mul WORD[bpbRootEntries]    ; total size of Directory
        div WORD[bpbBytesPerSector] ; Sectors used by directory
        xchg ax, cx

        ; Compute location of root directory and store in ax
        mov al, BYTE[bpbNumberOfFATs]       ; Number of FATs
        mul WORD[bpbSectorsPerFAT]          ; Sectors used by FATs
        add ax, WORD[bpbReservedSectors]    ; Adjust for boot sector
        mov WORD[datasector], ax            ; base of root directory
        add WORD[datasector], cx

        ; Read root directory into memory (7C00:0200)
        mov bx, 0x0200  ; Copy root dir above boot code
        call ReadSectors

        ;***********************************************************************
        ; Final stage 2
        ;***********************************************************************
        ; Browse root directory for binary image
        mov cx, WORD[bpbRootEntries]    ; Load loop counter
        mov di, 0x0200                  ; Locate first root entry
    .LOOP
        push cx
        mov cx, 0x000B                  ; 11 character name
        mov si, imageName               ; Image name to find
        push di
    rep cmpsb                           ; Test for match
        pop di
        je LOAD_FAT
        pop cx
        add di, 0x0020                  ; Queue next directory entry
        loop .LOOP
        jmp FAILURE

    LOAD_FAT:
        ; Save stating cluster of boot image
        mov si, msgCRLF
        call Print
        mov dx, WORD[di + 0x001A]
        mov WORD[cluster], dx       ; Files first cluster

        ; Compute size of FAT and store in cx
        xor ax, ax
        mov al, BYTE[bpbNumberOfFATs]   ; Number of FATs
        mul WORD[bpbSectorsPerFAT]      ; Sectors used by FATs
        mov cx, ax

        ; Compute location of FAT and store in ax
        mov ax, WORD[bpbReservedSectors]    ; Adjust for boot sector

        ; Read FAT into memory (0x7C00:0x0200)
        mov bx, 0x0200  ; Copy FAT above boot code
        call ReadSectors

        ; Read image file into memory (0x0050:0x0000)
        mov si, msgCRLF
        call Print
        mov ax, 0x0050
        mov es, ax      ; Destination for image
        mov bx, 0x0000  ; Destination for image
        push bx

    ;***************************************************************************
    ; Load Stage 2
    ;***************************************************************************
    LOAD_IMAGE:
        mov ax, WORD[cluster]               ; cluster to read
        pop bx                              ; buffer to read into
        call ClusterLBA                     ; Convert cluster to LBA
        xor cx, cx
        mov cl, BYTE[bpbSectorsPerCluster]  ; Sectors to read
        call ReadSectors
        push bx

        ; Compute next cluster
        mov ax, WORD[cluster]    ; Identify current cluster
        mov cx, ax               ; Copy current cluster
        mov dx, ax               ; Copy current cluster
        shr dx, 0x0001           ; Divide by two
        add cx, dx               ; Sum for (3/2)
        mov bx, 0x0200           ; Location of FAT in memory
        add bx, cx               ; Index into FAT
        mov dx, WORD[bx]         ; Read two bytes from FAT
        test ax, 0x0001
        jnz .ODD_CLUSTER

    .EVEN_CLUSTER:
        and dx, 0000111111111111b   ; Take low twelve bits
        jmp .DONE

    .ODD_CLUSTER:
        shr dx, 0x0004  ; Take high twelve bits

    .DONE:
        mov WORD[cluster], dx   ; Store new cluster
        cmp dx, 0x0FF0          ; Test for end of file
        jb LOAD_IMAGE

    DONE:
        mov si, msgCRLF
        call Print
        push WORD 0x0050
        push WORD 0x0000
        retf

    FAILURE:
        mov si, msgFailure
        call Print
        mov si, msgCRLF
        call Print
        mov ah, 0x00
        int 0x16            ; Await keypress
        int 0x19            ; warm boot computer

    absoluteSector db 0x00
    absoluteHead   db 0x00
    absoluteTrack  db 0x00

    datasector  dw 0x0000
    cluster     dw 0x0000
    imageName   db "STAGE2  SYS"
    msgLoading  db 0x0D, 0x0A, "Loading Boot Image ", 0x0D, 0x0A, 0x00
    msgCRLF     db 0x0D, 0x0A, 0x00
    msgProgress db ".", 0x00
    msgFailure  db 0x0D, 0x0A, "ERROR : Press any key to reboot", 0x0A, 0x00

        ; NASM, the dollar operator ($) represents the address of the current line.
        ; $$ represents the address of the first instruction (Should be 0x7C00). So,
        ; $­$$ returns the number of bytes from the current line to the start
        ; (In this case, the size of the program).
        times 510-($-$$) db 0 ; We have to be 512 bytes, clear the rest of the bytes
                              ; with 0

        ; Remember that the BIOS INT 0x19 searches for a bootable disk. How does it know
        ; if the disk is bootable? The boot signiture. If the 511 byte is 0xAA and the
        ; 512 byte is 0x55, INT 0x19 will load and execute the bootloader. Because the
        ; boot signiture must be the last two bytes in the bootsector, We use the times
        ; keyword to calculate the size different to fill in up to the 510th byte,
        ; rather then the 512th byte.
        dw 0xAA55 ; Boot signature.

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
