section .force_high_up
extern da_trampoline_entry
init_desc:
    dq 0xdeadbeefdeadbeef ; magic
    dq asm_entry ; entrypoint
asm_entry:
    mov rsp, 2 << 20 ; 2mb to 1mb growing downwards
    call da_trampoline_entry

cli_hlt:
    cli
    hlt
    jmp cli_hlt