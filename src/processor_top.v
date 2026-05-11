/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module processor_top (
    input  wire clk,
    input  wire rst,
    output wire sck,
    output wire [2:0] cs,
    output wire mosi,
    input  wire miso,
    output wire [5:0] rgb
);

    localparam IALEN = 11;
    localparam ALEN = 8;

    wire fetch_req;
    wire [IALEN-1:0] fetch_addr;
    wire fetch_valid;
    wire [15:0] fetch_instr;
    wire mem_req;
    wire mem_w_req;
    wire [ALEN-1:0] mem_addr;
    wire mem_valid;
    wire [7:0] mem_val;
    wire [7:0] mem_w_val;
    wire mem_w_done;
    processor_no_spi proc (
        .clk(clk),
        .rst(rst),
        .fetch_req(fetch_req),
        .fetch_addr(fetch_addr),
        .fetch_valid(fetch_valid),
        .fetch_instr(fetch_instr),
        .mem_req(mem_req),
        .mem_w_req(mem_w_req),
        .mem_addr(mem_addr),
        .mem_valid(mem_valid),
        .mem_val(mem_val),
        .mem_w_val(mem_w_val),
        .mem_w_done(mem_w_done),
        .rgb(rgb)
    );

    mem_handler mh (
        .clk(clk),
        .rst(rst),
        .fetch_req(fetch_req),
        .fetch_addr(fetch_addr),
        .fetch_valid(fetch_valid),
        .fetch_instr(fetch_instr),
        .mem_req(mem_req),
        .mem_w_req(mem_w_req),
        .mem_addr(mem_addr),
        .mem_valid(mem_valid),
        .mem_val(mem_val),
        .mem_w_val(mem_w_val),
        .mem_w_done(mem_w_done),
        .sck(sck),
        .cs(cs),
        .mosi(mosi),
        .miso(miso)
    );

endmodule
