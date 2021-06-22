module stivalebios.full.pci;

import stivalebios.common.io;
import stivalebios.common.print;

uint readpci(uint bus, uint slot, uint func, uint offset) {
    uint address = (bus << 16) | (slot << 11) | (func << 8) | offset | (0x80000000U);
    outl(0xCF8, address);
    return inl(0xCFC);
}

void writepci(uint bus, uint slot, uint func, uint offset, uint value) {
    assert(offset & 3 == 0, "What the fuck are you doing");
    uint address = (bus << 16) | (slot << 11) | (func << 8) | offset | (0x80000000U);

    outl(0xCF8, address);
    outl(0xCFC, value);
}

ubyte readpcibyte(uint bus, uint slot, uint func, uint offset) {
    assert(offset & 3 == 0, "What the fuck are you doing");
    uint address = (bus << 16) | (slot << 11) | (func << 8) | offset | (0x80000000U);
    outl(0xCF8, address);
    return inb(0xCFC);
}

void writepcibyte(uint bus, uint slot, uint func, uint offset, ubyte value) {
    assert(offset & 3 == 0, "What the fuck are you doing");
    uint address = (bus << 16) | (slot << 11) | (func << 8) | offset | (0x80000000U);

    outl(0xCF8, address);
    outb(0xCFC, value);
}

void scanpci(ref ulong alloc_address) {
    foreach (bus; 0 .. 256) {
        foreach (slot; 0 .. 32) {
            uint id = readpci(bus, slot, 0, 0);
            if (id != 0xffff_ffff && id != 0x0000_0000) {
                printf("Allocating BAR for {}:{}.0", bus, slot);
                alloc_bars(bus, slot, 0, alloc_address);
                if ((readpci(bus, slot, 0, 0xC) >> 16) & 0x80) {
                    foreach (func; 1 .. 8) {
                        uint id2 = readpci(bus, slot, 0, 0);
                        if (id2 != 0xffff_ffff && id2 != 0x0000_0000) {
                            printf("Allocating BARs for {}:{}.{}", bus, slot, func);
                            alloc_bars(bus, slot, func, alloc_address);
                        }
                    }
                }
            }
        }
    }
}
void pcifind(T)(void function(uint, uint, uint, ref T) callback, ref T value) {
    foreach (bus; 0 .. 256) {
        foreach (slot; 0 .. 32) {
            uint id = readpci(bus, slot, 0, 0);
            if (id != 0xffff_ffff && id != 0x0000_0000) {
                callback(bus, slot, 0, value);
                if ((readpci(bus, slot, 0, 0xC) >> 16) & 0x80) {
                    foreach (func; 1 .. 8) {
                        uint id2 = readpci(bus, slot, 0, 0);
                        if (id2 != 0xffff_ffff && id2 != 0x0000_0000) {
                            callback(bus, slot, func, value);
                        }
                    }
                }
            }
        }
    }
}
void pcifind(void function(uint, uint, uint) callback) {
    foreach (bus; 0 .. 256) {
        foreach (slot; 0 .. 32) {
            uint id = readpci(bus, slot, 0, 0);
            if (id != 0xffff_ffff && id != 0x0000_0000) {
                callback(bus, slot, 0);
                if ((readpci(bus, slot, 0, 0xC) >> 16) & 0x80) {
                    foreach (func; 1 .. 8) {
                        uint id2 = readpci(bus, slot, 0, 0);
                        if (id2 != 0xffff_ffff && id2 != 0x0000_0000) {
                            callback(bus, slot, func);
                        }
                    }
                }
            }
        }
    }
}

uint get_bar_amount(uint bus, uint slot, uint func) {
    uint htype = (readpci(bus, slot, func, 0x0C) >> 16) & ~0x80;
    uint barcount = 0;
    if (htype == 0)
        barcount = 6;
    if (htype == 1)
        barcount = 2;
    return barcount;
}
uint get_bar(uint bus, uint slot, uint func, uint bar) {
    assert(bar < get_bar_amount(bus, slot, func));
    return readpci(bus, slot, func, bar * 4 + 0x10) & ~0b1111;
}
uint get_vendor_device(uint bus, uint slot, uint func) {
    return readpci(bus, slot, func, 0);
}

void alloc_bars(uint bus, uint slot, uint func, ref ulong alloc_address) {
    uint barcount = get_bar_amount(bus, slot, func);
    bool lastwas64 = false;
    foreach (idx; 0 .. barcount) {
        if (lastwas64) {
            lastwas64 = false;
            continue;
        }
        writepci(bus, slot, func, idx * 4 + 0x10, ~0);
        if (readpci(bus, slot, func, idx * 4 + 0x10)) {
            uint flags = readpci(bus, slot, func, idx * 4 + 0x10);
            if ((flags & 1) != 0)
                continue;
            bool is64 = (flags & 0b110) >> 1 == 2;
            lastwas64 |= is64;
            ulong size = cast(ulong)(flags & 0xFFFFFFF0);
            if (is64) {
                writepci(bus, slot, func, (idx + 1) * 4 + 0x10, ~0);
                size |= cast(ulong)(readpci(bus, slot, func, idx * 4 + 0x10)) << 32;
            }
            size = ~size + 1;
            if (!is64)
                size &= (1UL << 32) - 1;
            if (size == 0)
                continue;
            if (is64) {
                assert(false, "TODO: 64 bit BAR allocation");
            } else {
                alloc_address -= alloc_address % size;
                alloc_address -= size;
                writepci(bus, slot, func, idx * 4 + 0x10, cast(uint) alloc_address);
                printf("{}:{}.{} BAR{} => [{ptr}; {hex}]", bus, slot, func, idx, alloc_address, size);
            }
        }
    }
    writepci(bus, slot, func, 0x04, 2);
}
