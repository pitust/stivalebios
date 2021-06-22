module stivalebios.trampoline.trampoline;

import core.bitop;
import stivalebios.common.print;
import stivalebios.common.fw_cfg;

struct De {
    uint entc;
    FWCfgFile[32] filez;
}
struct File {
    uint size;
    ushort select;
    ushort reserved;
    string name;
    byte[] read(byte[] buffer) {
        assert(buffer.length >= size, "Buffer too small!");
        fw_read(select, size, buffer.ptr);
        ArrayInternal ai = ArrayInternal(size, buffer.ptr);
        return *cast(byte[]*)&ai;
    }
}
struct De2 {
    uint entc;
    File[] files;
}

struct ArrayInternal {
    ulong len;
    void* ptr;
}

pragma(mangle, "da_trampoline_entry")
void entrypoint() {
    De de;
    File[32] de2files;
    

    fw_read(/* FILE_DIR */ 0x0019, 4, &de);
    // putchar(cast(char)('0' + bswap(entc)));
    de.entc = bswap(de.entc);
    fw_read(/* FILE_DIR */ 0x0019, de.entc * FWCfgFile.sizeof + 4, &de);
    de.entc = bswap(de.entc);
    foreach (i; 0 .. de.entc) {
        ArrayInternal ai = ArrayInternal(strlen(de.filez[i].name.ptr), de.filez[i].name.ptr);
        de2files[i].name = *cast(immutable(char)[]*)&ai;
        de2files[i].select = cast(ushort)(bswap(de.filez[i].select) >> 16);
        de2files[i].size = bswap(de.filez[i].size);
    }
    ArrayInternal ai2 = ArrayInternal(de.entc, de2files.ptr);
    De2 fileList = De2(de.entc, *cast(File[]*)&ai2);


    foreach (ref file; fileList.files) {
        if (file.name == "opt/dev.pitust.stivalebios.fullbin") {
            printf("Found the stage3/fullbin! size={hex}, select={hex}", file.size, file.select);
            printf("[p]data: {hex}", *cast(ushort*)0x0000000000100010);
            fw_read(file.select, file.size, cast(void*)0x10_0000);
            printf("[v]data: {hex}", *cast(ushort*)0x0000000000100010);
        } else {
            printf("Name: {} size={hex}", file.name, file.size);
        }
    }
    ulong* fullbin_supposed_location = cast(ulong*)0x10_0000;
    if (fullbin_supposed_location[0] == 0xdeadbeefdeadbeef) {
        printf("Fullbin loaded correctly!");
        printf("Should branch to: {ptr}", fullbin_supposed_location[1]);
        ulong target = fullbin_supposed_location[1];
        printf("data there: {hex}", *cast(ushort*)target);
        while (1) {}
        asm {
            mov RAX, target;
            mov RDI, 0; // boot_mode_has_stack
            call RAX;
        }
    }
    printf("Error: never supposed to reach here, the fullbin returned somehow...");
}