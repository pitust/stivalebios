module stivalebios.common.io;

void putchar(char c) {
    asm {
        mov AL, c;
        mov DX, 0xe9;
        out DX, AL;
    }
}
void puts(string s) {
    foreach (c; s) {
        putchar(c);
    }
}

uint inl(ushort port) {
    uint v;
    asm {
        mov DX, port;
        in EAX, DX;
        mov v, EAX;
    }
    return v;
}
void outl(ushort port, uint v) {
    asm {
        mov DX, port;
        mov EAX, v;
        out DX, EAX;
    }
}
ushort inw(ushort port) {
    ushort v;
    asm {
        mov DX, port;
        in AX, DX;
        mov v, AX;
    }
    return v;
}
void outw(ushort port, ushort v) {
    asm {
        mov DX, port;
        mov AX, v;
        out DX, AX;
    }
}


ubyte inb(ushort port) {
    ubyte v;
    asm {
        mov DX, port;
        in AL, DX;
        mov v, AL;
    }
    return v;
}
void outb(ushort port, ubyte v) {
    asm {
        mov DX, port;
        mov AL, v;
        out DX, AL;
    }
}