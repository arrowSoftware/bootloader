; Note: Here, we are executed like a normal
; COM program, but we are still in Ring 0.
; We will use this loader to set up 32 bit
; mode and basic exception handling

; This loaded program will be our 32 bit Kernel.

; We do not have the limitation of 512 bytes here,
; so we can add anything we want here!

org 0x0     ; Offset to 0, we'll set the segments later
bits 16     ; Still in real mode

; we're loaded at linear address 0x10000
jmp main    ; Jump to main

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
; Second stage loader entry point
;*******************************************************************************
main:
    cli             ; Clear interrupts
    push cs         ; Ensure DS=CS
    pop ds

    mov si, msg     ; The welcome message to print.
    call Print      ; Call the print function

    cli             ; clear interrupts to prevent triple faults
    hlt             ; Hault the system.

;*******************************************************************************
; Data section
;*******************************************************************************
msg db "Preparing to load operating system...",13,10,0
