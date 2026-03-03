/*
 * Copyright (c) 2025 Marcus Alagar, Derek Maeshiro, Chloe Zhong
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_lorenz_attractor_vga (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    reg [8:0] point_0_x;
    reg [7:0] point_0_y;

    vga_controller vga_control (
        .clk(clk),
        .rst(~rst_n),
        .point_0_x(point_0_x),
        .point_0_y(point_0_y),
        .point_0_valid(1'b1),
        .r({ uo_out[0], uo_out[4] }),
        .g({ uo_out[1], uo_out[5] }),
        .b({ uo_out[2], uo_out[6] }),
        .hsync(uo_out[7]),
        .vsync(uo_out[3])
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            point_0_x <= 9'h0;
            point_0_y <= 8'h0;
        end else begin
            point_0_x <= point_0_x + 1;
            point_0_y <= point_0_y + 1;
        end
    end

    // List all unused inputs to prevent warnings
    wire _unused = &{ui_in, uio_in, ena, 1'b0};

    // Pull unused outputs to prevent warnings
    assign uio_out = 8'h0;
    assign uio_oe = 8'h0;

endmodule
