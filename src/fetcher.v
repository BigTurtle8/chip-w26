/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module fetcher #(
    parameter IALEN = 11,
    parameter START_ADDR = {IALEN{1'b0}}
) (
    input  wire clk,
    input  wire rst,
    input  wire begin_fetch,
    output wire fetch_done,
    input  wire [IALEN-1:0] pc_addr,
    output wire fetch_req,
    output wire [IALEN-1:0] fetch_addr,
    input  wire fetch_valid,
    input  wire [15:0] fetch_instr,
    output wire [15:0] instr
);

    localparam IDLE = 1'b0;
    localparam REQUESTING = 1'b1;
    reg state;

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else if (fetch_valid)
            state <= IDLE;
        else if (begin_fetch)
            state <= REQUESTING;
        else
            state <= state;
    end

    wire new_req = begin_fetch & (state == IDLE);
    reg [IALEN-1:0] req_addr;
    always @(posedge clk) begin
        if (rst)
            req_addr <= START_ADDR;
        else if (new_req)
            // Only request address if not currently requesting
            req_addr <= pc_addr;
        else
            req_addr <= req_addr;
    end

    assign fetch_req = state == REQUESTING;
    assign fetch_addr = req_addr;

    assign fetch_done = fetch_valid & (state == REQUESTING);
    assign instr = fetch_instr;

endmodule
