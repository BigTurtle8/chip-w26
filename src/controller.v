/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module controller (
    input  wire clk,
    input  wire rst,
    output wire begin_fetch,
    input  wire fetch_done,
    output wire begin_decode,
    input  wire decode_done,
    output wire begin_executor,
    input  wire executor_done
);

    reg prev_rst;
    always @(posedge clk) begin
        prev_rst <= rst;
    end

    wire is_starting = ~rst & prev_rst;

    assign begin_decode = fetch_done;
    assign begin_executor = decode_done;

    assign begin_fetch = is_starting | executor_done;

endmodule
