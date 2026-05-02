/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module processor_no_spi #(
    parameter IALEN = 11,
    parameter ALEN = 8
) (
    input  wire clk,
    input  wire rst,
    output wire fetch_req,
    output wire [IALEN-1:0] fetch_addr,
    input  wire fetch_valid,
    input  wire [15:0] fetch_instr,
    output wire mem_req,
    output wire mem_w_req,
    output wire [ALEN-1:0] mem_addr,
    input  wire mem_valid,
    input  wire [7:0] mem_val,
    output wire [7:0] mem_w_val,
    input  wire mem_w_done,
    input  wire [7:0] xpos,
    input  wire [7:0] ypos,
    output wire [5:0] rgb               // { R[1:0], G[1:0], B[1:0] }
);

    wire _unused_ok = &{clk, rst, fetch_valid, fetch_instr,
                        mem_valid, mem_val, mem_w_done, xpos, ypos};

    assign fetch_req = 1'b0;
    assign fetch_addr = {IALEN{1'b0}};
    assign mem_req = 1'b0;
    assign mem_w_req = 1'b0;
    assign mem_addr = {ALEN{1'b0}};
    assign mem_w_val = 8'b0;
    assign rgb = 6'b0;

endmodule
