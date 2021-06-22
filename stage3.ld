SECTIONS
{

    . = 0x00100000;
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

    .debug_frame : {
        *(.eh_frame)
    }
}
