[BITS 16]
[ORG 0x7C00]

start:
    mov si, welcome
    call print       

read_key:
    mov ah, 0x00    
    int 0x16        

    cmp al, 0x1B    
    je hang         

    mov ah, 0x0E    
    int 0x10

    jmp read_key

hang:
    hlt
    jmp hang

print:
    mov ah, 0x0E
.next_char:
    lodsb
    test al, al
    jz done
    int 0x10
    jmp .next_char
done:
    ret

welcome db "Send message: ", 0

times 510-($-$$) db 0
dw 0xAA55
