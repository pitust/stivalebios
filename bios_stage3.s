section .force_high_up
extern da_entry
init_desc:
    dq 0xdeadbeefdeadbeef ; magic
    dq asm_entry ; entrypoint
asm_entry:
    cmp rdi, 1
    je .just_call
    mov rsp, 2 << 20 ; 2mb to 1mb growing downwards
    call da_entry
.haltloop:
    cli
    hlt
    jmp .haltloop
    
.just_call:
    jmp da_entry