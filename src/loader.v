/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module loader #(
    parameter ALEN = 8
) (
    input  wire clk,
    input  wire rst,
    input  wire begin_load,
    output wire load_done,
    input  wire [ALEN-1:0] addr,
    output wire [7:0] load_val,
    output wire mem_req,
    output wire [ALEN-1:0] mem_addr,
    input  wire mem_valid,
    input  wire [7:0] mem_val
);

    localparam IDLE = 1'b0;
    localparam REQUESTING = 1'b1;
    reg state;

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else if (mem_valid)
            state <= IDLE;
        else if (begin_load)
            state <= REQUESTING;
        else
            state <= state;
    end

    wire new_req = begin_load & (state == IDLE);
    reg [ALEN-1:0] req_addr;
    always @(posedge clk) begin
        if (rst)
            req_addr <= 0;
        else if (new_req)
            // Only request address if not currently requesting
            req_addr <= addr;
        else
            req_addr <= req_addr;
    end

    assign mem_req = state == REQUESTING;
    assign mem_addr = req_addr;

    assign load_done = mem_valid & (state == REQUESTING);
    assign load_val = mem_val;

endmodule
