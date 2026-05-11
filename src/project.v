/*
 * Copyright (c) 2026 Marcus Alagar, Derek Maeshiro, Chloe Zhong
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_madech_8bit_processor_vga (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire hsync, vsync;
    wire display_on;
    wire [9:0] hpos, vpos;
    hvsync_generator hvsync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(display_on),
        .hpos(hpos),
        .vpos(vpos)
    );

    wire sck;
    wire [2:0] cs; // ACTIVE LOW, Flash (0), RAM A (1), RAM B (2)
    wire mosi, miso;
    wire [1:0] r, g, b;
    processor_top proc_top (
        .clk(clk),
        .rst(~rst_n),
        .sck(sck),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .xpos(hpos[7:0]),
        .ypos(vpos[7:0]),
        .rgb({r, g, b})
    );

    // TinyVGA PMOD
    assign uo_out = {hsync, b[0], g[0], r[0], vsync, b[1], g[1], r[1]};

    // TinyTapeout QSPI PMOD
    assign miso = uio_in[2];
    assign uio_out = {cs[2], cs[1], 2'b0, sck, 1'b0, mosi, cs[0]};
    assign uio_oe = 8'b11111011;

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
