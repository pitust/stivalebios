module stivalebios.full.bootheap;

import stivalebios.common.print;
import ldc.intrinsics;

ref Slab*[64] slabpointers() {
    return *cast(Slab*[64]*)0x00_7E00;
}
enum MIN_SLAB_SIZE = 8;
// goodblk!
enum BLOCK_MAGIC = 0x676f6f64626c6b21;
// dblfree!
enum BLOCK_MAGIC_UAF = 0x64626c6672656521;
extern(C) private struct Slab {
    Slab* next;
}

void add_mem_block(ulong low, ulong size) {
    ulong tempsize = size;
    foreach (ulong i; 0 .. 64) {
        if ((size & (1UL << i)) == 0) continue;
        if ((1UL << i) < MIN_SLAB_SIZE) {
            tempsize -= 1UL << i;
            continue;
        }
        printf("low={ptr} size={hex} i={} BLOCK: [{ptr}; {hex}]", low, size, i, low + tempsize - (1 << i), 1 << i);
        Slab* mynewslab = cast(Slab*)(low + tempsize - (1 << i));
        mynewslab.next = slabpointers[i];
        slabpointers[i] = mynewslab;
        tempsize -= 1UL << i;
    }
    printf("slabpointers: {ptr}", slabpointers);
}
void* malloc(ulong len) {
    if ((len & (len - 1)) != 0) len = 1UL << (64 - llvm_ctlz(len, false));
    printf("malloc({hex})", 1UL << llvm_cttz(len, false));
    ulong ite = llvm_cttz(len, false);
    if (slabpointers[ite] != cast(Slab*)0) {
        Slab* old = slabpointers[ite];
        slabpointers[ite] = old.next;
        return cast(void*)old;
    }
    if (ite > 48) return cast(void*)0;
    void* newmemarea = malloc(len << 1);
    if (newmemarea == cast(void*)0) return cast(void*)0;
    Slab* low = cast(Slab*)newmemarea;
    Slab* high = cast(Slab*)(newmemarea + len);
    low.next = high;
    high.next = slabpointers[ite];
    slabpointers[ite] = low;
    return malloc(len);
}
void free(ulong len, void* ptr) {
    add_mem_block(cast(ulong)ptr, len);
}