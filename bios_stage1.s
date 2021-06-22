org 0

page_table_root:
dq 0x01003
%assign i 0
%rep 511
    dq 0
%assign i i+1
%endrep

page_table_l2:
%assign i 0
%rep 512
    dq 0x0083 | (i * GB)
%assign i i+1
%endrep

GB equ 1 << 30
MB equ 1 << 20

jmp 0:stage0e ; enter s0e in a nice state

stage0e:
    mov ax, cs
    mov ds, ax
    
    lgdt [pointer]
    mov eax, cr0
    or al, 1
    mov cr0, eax

    mov eax, page_table_root
    mov cr3, eax
    
    mov eax, 0xa0
    mov cr4, eax
    mov ecx, 0xC0000080
    mov eax, 0x500
    xor edx, edx
    wrmsr
    mov ebx, 1<<31 | 1
    ; jmp $
    mov cr0, ebx
    jmp 0x28:longmode

cpy0_end:

bits 64
longmode:
    mov ax, 0x30
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rsi, target + 0x000F1000
    mov rax, 0xdeadbeefdeadbeef
    cmp [rsi], rax
    jne .boot_failed
    mov rsi, target + 0x000F1008 ; target

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rdi, rdi
    xor rbp, rbp
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

    mov rdi, 0 ; boot_mode_no_stack
    mov rsi, [rsi]
    jmp rsi

%macro output 1
    mov al, %1
    out dx, al
%endmacro
.boot_failed:
    mov dx, 0xe9
    ; ERR: MAGIC
    output 0x45
    output 0x52
    output 0x52
    output 0x3a
    output 0x20
    output 0x4d
    output 0x41
    output 0x47
    output 0x49
    output 0x43
    output 0x0a
.hang:
    cli
    hlt
    jmp .hang ; if nmi hits


; gdt. this is my shitty gdt that i made some time ago, and can't remember how it worked. oh well.
align 8
gdt:
    ; 0x00 - null segment
    dq 0
    ; 0x08 - 16bit code
    db 0xff, 0xff, 0, 0, 0, 10011010b, 10001111b, 0
    ; 0x10 - 16bit data
    db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
    ; 0x18 - 32bit code
    dw 0xffff, 0x0000
    db 0x00, 0x9a, 0xcf, 0x00
    ; 0x20 - 32bit data
    dw 0xffff, 0x0000
    db 0x00, 0x92, 0xcf, 0x00
    ; 0x28 - 64bit code
    dq 0x00af9b000000ffff
    ; 0x30 - 64bit data
    dq 0x00af93000000ffff

pointer:dw 0x38 ; lots of entries
dd gdt

align 8
huge_unreal_gdt:
    dw 0x10
    dd gdtdata
gdtdata:
    dq 0
    db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0

align 0x4000 ; 16K
target:
incbin "bin/bios_stage2.bin"