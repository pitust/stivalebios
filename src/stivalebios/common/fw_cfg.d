module stivalebios.common.fw_cfg;

import core.bitop;

extern(C) struct FWCfgFile {
    align(1) uint size;
    align(1) ushort select;
    align(1) ushort reserved;
    align(1) char[56] name;
}

void fw_read(ushort selector, ulong len, void* tgd) {
    byte* tg2 = cast(byte*)tgd;
    asm {
        mov DX, 0x510;
        mov AX, selector;
        out DX, AX;
    }
    foreach (i; 0 .. len) {
        byte t;
        asm {
            mov DX, 0x511;
            in AL, DX;
            mov t, AL;
        }
        tg2[i] = t;
    }
}