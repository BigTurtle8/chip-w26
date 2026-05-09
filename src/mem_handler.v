/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module mem_handler #(
    parameter IALEN = 11,
    parameter ALEN = 8
) (
    input  wire clk,
    input  wire rst,
    input  wire fetch_req,
    input  wire [IALEN-1:0] fetch_addr,
    output wire fetch_valid,
    output wire [15:0] fetch_instr,
    input  wire mem_req,
    input  wire mem_w_req,
    input  wire [ALEN-1:0] mem_addr,
    output wire mem_valid,
    output wire [7:0] mem_val,
    input  wire [7:0] mem_w_val,
    output wire mem_w_done,
    output wire sck,
    output wire [2:0] cs,
    output wire mosi,
    input  wire miso
);

    wire _unusued_ok = &{clk, rst, fetch_req, fetch_addr,
                            mem_req, mem_w_req, mem_addr,
                            mem_w_val, miso};

    // assign fetch_valid = 1'b0;
    // assign fetch_instr = 16'b0;
    assign mem_valid = 1'b0;
    assign mem_val = 8'b0;
    assign mem_w_done = 1'b0;
    assign sck = 1'b0;
    assign cs = 3'b0;
    assign mosi = 1'b0;

    reg [15:0] mem_instr;
    always @(*) begin
        case (fetch_addr)
            11'd0  : mem_instr = 16'b0010010001100110;
            11'd2  : mem_instr = 16'b1010100010000000;
            default: mem_instr = 16'b1100100100010000;
        endcase
    end

    assign fetch_instr = mem_instr;
    assign fetch_valid = fetch_req;

    
    // Added by Derek: Inside mem_handler module (for loading the hex file into the testbench)
    // ROM array for the hex file
    reg [15:0] rom [0:2047];

    // Connect the ROM to the fetch interface
    assign fetch_instr = rom[fetch_addr[IALEN-1:1]]; // Index by word, not byte
    assign fetch_valid = fetch_req; 

endmodule
