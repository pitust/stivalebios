module stivalebios.full.entry;

import stivalebios.full.pci;
import stivalebios.full.bxvga;
import stivalebios.full.bootheap;
import stivalebios.common.io;
import stivalebios.common.print;
import stivalebios.common.fw_cfg;
import core.bitop;
import ldc.intrinsics;

struct De {
    uint entc;
    FWCfgFile[32] filez;
}

extern(C) struct E820Entry {
    align(1) ulong base;
    align(1) ulong len;
    align(1) uint type;
    align(1) uint _reserved;
}

__gshared int i = 3;

pragma(mangle, "da_entry")
void entrypoint() {
    ulong gAllocAddress = 0xDFFF_FFFF;

    printf("EP @ {}", cast(void*)(&entrypoint));
    
    printf("{}", 1 << (64 - llvm_ctlz(cast(ulong)31, false)));

    // char[48] ram;
    // add_mem_block(cast(ulong)ram.ptr, ram.sizeof);

    // printf("a: {}", malloc(8));
    // printf("a: {}", malloc(8));

    // De de;

    // read(/* FILE_DIR */ 0x0019, 4, &de);
    // // putchar(cast(char)('0' + bswap(entc)));
    // de.entc = bswap(de.entc);
    // read(/* FILE_DIR */ 0x0019, de.entc * FWCfgFile.sizeof + 4, &de);
    // foreach (ref f; de.filez) {
    //     if (f.name == "opt/dev.pitust.stivalebios.config"
    //         ~ "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00") {
    //         printf("Found the config! size={}, select={hex}", bswap(f.size), bswap(f.select) >> 16);
    //         char[4096] buf;
    //         read(cast(ushort)(bswap(f.select) >> 16), bswap(f.size), buf.ptr);
    //         printf("Config: {}", buf[0 .. bswap(f.size)]);
    //         break;
    //     } else {
    //         printf("Name: {} size={hex}", f.name, bswap(f.size));
    //     }
    // }


    // 0x 03 00 00 02

    scanpci(gAllocAddress);
    uint bxvga_lfb_address = 0;
    pcifind((uint bus, uint slot, uint func, ref uint bxvga_lfb_address) {
        if (get_vendor_device(bus, slot, func) == 0x11111234) {
            printf("Found bxvga @ {}:{}.{}", bus, slot, func);
            printf("Found LFB @ {ptr}", get_bar(bus, slot, func, 0));
            bxvga_lfb_address = get_bar(bus, slot, func, 0);
        }
    }, bxvga_lfb_address);
    bxvga_set_video_mode(1024, 768, 32);
    printf("Let's try writing to the LFB...");
    foreach (i; 0 .. 1024) (cast(uint*)bxvga_lfb_address)[i] = 0xffffffff;
    // alloc_bars(0, 2, 0, gAllocAddress);
    // alloc_bars(0, 31, 2, gAllocAddress);
    // alloc_bars(0, 31, 3, gAllocAddress);
    while (1) { }
}