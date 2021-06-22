SECTIONS
{

    . = 0x000F5000;
    .force_high_up : ALIGN(1) {
        *(.force_high_up)
    }

    .text : ALIGN(4096) {
        *(.text*)
    }

    .rodata : ALIGN(4096) {
        *(.rodata*)
    }

    .data : ALIGN(4096) {
        *(.data*)
    }

    .bss : ALIGN(4096) {
        *(COMMON)
        *(.bss*)
    }
}
