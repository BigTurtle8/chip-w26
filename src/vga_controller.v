/*
 * Copyright (c) 2025, Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module vga_controller (
    input  wire       clk,
    input  wire       rst,          // reset high
    input  wire [8:0] point_0_x,
    input  wire [7:0] point_0_y,
    input  wire       point_0_valid,
    output wire [1:0] r,
    output wire [1:0] g,
    output wire [1:0] b,
    output wire       hsync,
    output wire       vsync
);

    localparam ON_COLOR = 6'b111111;

    wire display_on;
    wire [9:0] hpos;
    wire [9:0] vpos;

    // Generates necessary VGA timing signals
    hvsync_generator hvsync_gen (
        .clk(clk),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(display_on),
        .hpos(hpos),
        .vpos(vpos)
    );

    // Checks if current display point is one
    // of the input points
    wire is_input_point;

    assign is_input_point = (point_0_x == hpos[8:0]) &
                            (point_0_y == vpos[7:0]) &
                            point_0_valid;

    // Mux to display on color
    assign {r, g, b} = (display_on & is_input_point) ?
                        ON_COLOR : 6'b0;

endmodule
