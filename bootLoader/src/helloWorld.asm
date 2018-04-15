BITS 16
jmp main
nop
main:
    mov ax, 07C0h
    add ax, 288
    mov ss, ax
    mov sp, 4096
    mov ax, 07C0h
    mov ds, ax
    call PrintHelloWorld
    jmp .InfiniteLoop
    .InfiniteLoop:
        jmp .InfiniteLoop

HelloWorld      db  "Hello World. This is from the bootloader", 0x0d, 0x0a, 0x00
PrintHelloWorld:
    mov si, HelloWorld
    call PrintStr
    ret
PrintStr:
    push ax
    mov ah, 0Eh
    .loop:
        lodsb
        cmp al, 0x00
        je .done
        int 10h
        jmp .loop
    .done:
        pop ax
        ret
times 510-($-$$) db 0
dw 0xAA55
