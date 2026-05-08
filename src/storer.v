/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module storer #(
    parameter ALEN = 8
) (
    input  wire clk,
    input  wire rst,
    input  wire begin_store,
    output wire store_done,
    input  wire [ALEN-1:0] addr,
    input  wire [7:0] store_val,
    output wire mem_w_req,
    output wire [ALEN-1:0] mem_addr,
    output wire [7:0] mem_w_val,
    input  wire mem_w_done
);

    localparam IDLE = 1'b0;
    localparam WRITING = 1'b1;
    reg state;

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else if (mem_w_done)
            state <= IDLE;
        else if (begin_store)
            state <= WRITING;
        else
            state <= state;
    end

    wire new_w = begin_store & (state == IDLE);
    reg [ALEN-1:0] w_addr;
    reg [7:0] w_val;
    always @(posedge clk) begin
        if (rst) begin
            w_addr <= 0;
            w_val <= 0;
        end else if (new_w) begin
            // Only write address if not currently writing
            w_addr <= addr;
            w_val <= store_val;
        end else begin
            w_addr <= w_addr;
            w_val <= w_val;
        end
    end

    assign mem_w_req = state == WRITING;
    assign mem_addr = w_addr;
    assign mem_w_val = w_val;

    assign store_done = mem_w_done & (state == WRITING);

endmodule
