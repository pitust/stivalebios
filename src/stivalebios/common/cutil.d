module stivalebios.common.cutil;

import stivalebios.common.print;



/// Internal assetion code
extern (C) void __assert(char* assertion, char* file, int line) {

    printf(FATAL, "Kernel assertion failed: {} at {}:{}", assertion, file, line);
    for (;;) {
        asm {
            hlt;
        }
    }
}


/// memset - fill memory with a constant byte
///
/// The memset() function fills the first len bytes of the memory 
/// area pointed to by mem with the constant byte data.
///
/// The memset() function returns a pointer to the memory area mem.
extern (C) byte* memset(byte* mem, int data, size_t len) {
    for (size_t i = 0; i < len; i++)
        mem[i] = cast(byte) data;
    return mem;
}



/// memcpy - copy memory area
///
/// The  memcpy() function copies n bytes from memory area src to memory area dest.
/// The memory areas must not overlap. Use memmove(3) if the memory
/// areas do overlap.
///
/// The memcpy() function returns a pointer to dest.
extern (C) byte* memcpy(byte* dst, const byte* src, size_t n) {
    size_t i = 0;
    while (i + 8 <= n) {
        *(cast(ulong*)(&dst[i])) = *(cast(ulong*)(&src[i]));
        i += 8;
    }
    while (i + 4 <= n) {
        *(cast(uint*)(&dst[i])) = *(cast(uint*)(&src[i]));
        i += 4;
    }
    while (i + 2 <= n) {
        *(cast(ushort*)(&dst[i])) = *(cast(ushort*)(&src[i]));
        i += 2;
    }
    while (i + 1 <= n) {
        *(cast(byte*)(&dst[i])) = *(cast(byte*)(&src[i]));
        i += 1;
    }
    return dst;
}

/// memcmp - compare memory areas
///
/// # Description
/// The memcmp() function compares the first n bytes (each interpreted as unsigned char) of the memory areas s1 and s2.
///
/// # Return Value
/// The  memcmp()  function  returns an integer less than, equal to, or greater than zero if the first n bytes of s1 is found, respectively, to be less than, to match, or be greater than the
/// first n bytes of s2.
///
/// Not the above guarantee about memcmp's return value is guaranteed by linux and not the standard, as seen in CVE-2012-2122 "optimized memcmp"
/// glibc memcmp when SSE/AVX is on will return whatever.
/// So we return 1/0/-1.
///
/// For a nonzero return value, the sign is determined by the sign of the difference between the first pair of bytes (interpreted as unsigned char) that differ in s1 and s2.
///
/// If n is zero, the return value is zero.
extern (C) int memcmp(const byte* s1, const byte* s2, size_t n) {
    foreach (i; 0 .. n) {
        if (s1[i] < s2[i])
            return -1;
        if (s1[i] > s2[i])
            return 1;
    }
    return 0;
}