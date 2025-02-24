[BITS 16]
[ORG 0x7C00]

%define SCREEN_WIDTH 80    
%define CMD_BUFFER_SIZE 64  

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    cli
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ax, 0x0003
    int 0x10

    mov ah, 0x01
    mov cx, 0x2607
    int 0x10

    mov si, welcome
    call print

main_loop:
    call read_key
    jmp main_loop

read_key:
    mov ah, 0x00
    int 0x16            

    cmp al, 0x08
    je .backspace
    cmp al, 0x0D
    je .enter
    cmp al, 0x1B
    je hang

    cmp al, 32
    jb .invalid_char
    cmp al, 126
    ja .invalid_char

    call buffer_add
    mov ah, 0x0E
    int 0x10
    ret

.backspace:
    call buffer_remove
    ret

.enter:
    call new_line
    mov si, prompt
    call print
    ret

.invalid_char:
    ret

buffer_add:
    mov di, cmd_buffer
    add di, [buffer_pos]
    cmp byte [buffer_pos], CMD_BUFFER_SIZE
    jae .overflow
    mov [di], al
    inc byte [buffer_pos]
.overflow:
    ret

buffer_remove:
    cmp byte [buffer_pos], 0
    je .empty
    dec byte [buffer_pos]
    mov ah, 0x03
    int 0x10            
    cmp dl, 0
    je .prev_line
    dec dl
    jmp .update_cursor
.prev_line:
    dec dh
    mov dl, SCREEN_WIDTH-1
.update_cursor:
    mov ah, 0x02
    int 0x10
    mov al, ' '
    mov ah, 0x0A
    mov cx, 1
    int 0x10
.empty:
    ret

new_line:
    call print_crlf
    call process_command
    mov byte [buffer_pos], 0
    mov di, cmd_buffer
    mov cx, CMD_BUFFER_SIZE
    xor al, al
    rep stosb
    ret

process_command:
    mov si, cmd_buffer
    cmp byte [si], 0
    je .empty
    mov cx, 4
    mov di, echo_cmd
    repe cmpsb
    je .echo
    mov si, unknown_cmd
    call print
    ret
.echo:
    add si, cx
    call print
    call print_crlf
.empty:
    ret

print_crlf:
    mov si, crlf
    call print
    ret

print:
    mov ah, 0x0E
.next_char:
    lodsb
    test al, al
    jz .done
    cmp al, 0x09        
    je .tab
    cmp al, 0x0A
    je .lf
    cmp al, 0x0D
    je .cr
    int 0x10
    jmp .next_char
.tab:
    mov cx, 8
.spaces:
    mov al, ' '
    int 0x10
    loop .spaces
    jmp .next_char
.cr:
    mov al, 0x0D
    int 0x10
    jmp .next_char
.lf:
    mov al, 0x0A
    int 0x10
    mov al, 0x0D
    int 0x10
    jmp .next_char
.done:
    ret

hang:
    hlt
    jmp hang

welcome db "HelisOS v0.0", 0x0D, 0x0A, 0
prompt db "> ", 0
crlf db 0x0D, 0x0A, 0
echo_cmd db "ECHO",0
unknown_cmd db "Unknown command", 0x0D, 0x0A, 0

buffer_pos db 0
cmd_buffer times CMD_BUFFER_SIZE db 0

times 510-($-$$) db 0
dw 0xAA55
