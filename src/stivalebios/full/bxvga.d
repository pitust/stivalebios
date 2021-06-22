module stivalebios.full.bxvga;

import stivalebios.common.io;
import stivalebios.common.print;

private enum BXVGA_DISPI_INDEX_ID = 0;
private enum BXVGA_DISPI_INDEX_XRES = 1;
private enum BXVGA_DISPI_INDEX_YRES = 2;
private enum BXVGA_DISPI_INDEX_BPP = 3;
private enum BXVGA_DISPI_INDEX_ENABLE = 4;

void bxvga_write_reg(uint idx, uint val) {
    outw(0x1CE, cast(ushort)idx);
    outw(0x1CF, cast(ushort)val);
}
ushort bxvga_read_reg(uint idx) {
    outw(0x1CE, cast(ushort)idx);
    return inw(0x1CF);
}

void bxvga_set_video_mode(uint w, uint h, uint bpp) {
    assert(bpp == 32, "The choice of bits per pixel is an illusion. Use 32bpp!");
    bxvga_write_reg(BXVGA_DISPI_INDEX_ENABLE, 0);
    bxvga_write_reg(BXVGA_DISPI_INDEX_XRES, w);
    bxvga_write_reg(BXVGA_DISPI_INDEX_YRES, h);
    bxvga_write_reg(BXVGA_DISPI_INDEX_BPP, bpp);
    bxvga_write_reg(BXVGA_DISPI_INDEX_ENABLE, 0x41);
    printf("v: {hex}", bxvga_read_reg(BXVGA_DISPI_INDEX_ID));
}
