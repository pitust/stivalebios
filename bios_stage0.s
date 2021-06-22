size equ 0x10000

org 0x000F0000

bios_main:
    mov ax, cs
    mov ds, ax

    mov esi, stage1_start
    mov edi, 0
.loopp:
    mov al, es:[esi]
    mov es:[edi], al
    inc esi
    inc edi
    mov eax, stage1_start + 0x4000
    cmp esi, eax
    jb .loopp

    jmp 0:0x02000

times (0x1000) - ($ - $$) db 0x00 ; boring stuff

stage1_start:
    incbin "bin/bios_stage1.bin"
stage1_end:

bits 16
times (size - 16) - ($ - $$) db 0x00

; reset vector
jmp bios_main
times 13 db 0xFF

