// Project F: Ad Astra - Top Space 'F' (iCEBreaker 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_space_f (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
    output      logic dvi_clk,      // DVI pixel clock
    output      logic dvi_hsync,    // DVI horizontal sync
    output      logic dvi_vsync,    // DVI vertical sync
    output      logic dvi_de,       // DVI data enable
    output      logic [3:0] dvi_r,  // 4-bit DVI red
    output      logic [3:0] dvi_g,  // 4-bit DVI green
    output      logic [3:0] dvi_b   // 4-bit DVI blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst(!clk_locked),
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        /* verilator lint_off PINCONNECTEMPTY */
        .frame(),
        /* verilator lint_on PINCONNECTEMPTY */
        .line
    );

    // font glyph ROM
    localparam FONT_WIDTH  = 8;   // width in pixels (also ROM width)
    localparam FONT_HEIGHT = 8;   // height in pixels
    localparam FONT_GLYPHS = 64;  // number of glyphs
    localparam F_ROM_DEPTH = FONT_GLYPHS * FONT_HEIGHT;
    localparam FONT_FILE   = "../res/font_unscii_8x8_latin_uc.mem";

    logic [$clog2(F_ROM_DEPTH)-1:0] font_rom_addr;
    logic [FONT_WIDTH-1:0] font_rom_data;  // line of glyph pixels

    rom_sync #(
        .WIDTH(FONT_WIDTH),
        .DEPTH(F_ROM_DEPTH),
        .INIT_F(FONT_FILE)
    ) font_rom (
        .clk(clk_pix),
        .addr(font_rom_addr),
        .data(font_rom_data)
    );

    // sprite
    localparam SPR_SCALE_X = 32;  // enlarge sprite width by this factor
    localparam SPR_SCALE_Y = 32;  // enlarge sprite height by this factor

    // horizontal and vertical screen position of letter
    localparam SPR_X = 192;
    localparam SPR_Y = 112;

    // signal to start sprite drawing
    logic spr_start; 
    always_comb spr_start = (line && sy == SPR_Y);

    // subtract 0x20 from code points as font starts at U+0020
    localparam SPR_GLYPH_ADDR = FONT_HEIGHT * 'h26;  // F U+0046

    // font ROM address
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line;
    logic spr_fdma;  // font ROM DMA slot
    always_comb begin
        font_rom_addr = 0;
        spr_fdma = line;  // load glyph line at start of horizontal blanking
        /* verilator lint_off WIDTH */
        font_rom_addr = (spr_fdma) ? SPR_GLYPH_ADDR + spr_glyph_line : 0;
        /* verilator lint_on WIDTH */
    end

    logic spr_pix;  // sprite pixel
    sprite #(
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .LSB(0),
        .CORDW(CORDW),
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma),
        .sx,
        .sprx(SPR_X),
        .data_in(font_rom_data),
        .pos(spr_glyph_line),
        .pix(spr_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .drawing(),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // starfields
    logic sf1_on, sf2_on, sf3_on;
    /* verilator lint_off UNUSED */
    logic [7:0] sf1_star, sf2_star, sf3_star;
    /* verilator lint_on UNUSED */

    starfield #(.INC(-1), .SEED(21'h9A9A9)) sf1 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf1_on),
        .sf_star(sf1_star)
    );

    starfield #(.INC(-2), .SEED(21'hA9A9A)) sf2 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf2_on),
        .sf_star(sf2_star)
    );

    starfield #(.INC(-4), .MASK(21'h7FF)) sf3 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf3_on),
        .sf_star(sf3_star)
    );

    // sprite colour & star brightness
    logic [3:0] red_spr, green_spr, blue_spr, starlight;
    always_comb begin
        {red_spr, green_spr, blue_spr} = (spr_pix) ? 12'hFC0 : 12'h000;
        starlight = (sf1_on) ? sf1_star[7:4] :
                    (sf2_on) ? sf2_star[7:4] :
                    (sf3_on) ? sf3_star[7:4] : 4'h0;
    end

    // colours
    logic [3:0] red, green, blue;
    always_comb begin
        red   = de ? spr_pix ? red_spr   : starlight : 4'h0;
        green = de ? spr_pix ? green_spr : starlight : 4'h0;
        blue  = de ? spr_pix ? blue_spr  : starlight : 4'h0;
    end

    // Output DVI clock: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );

    // Output DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, red, green, blue}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );
endmodule
