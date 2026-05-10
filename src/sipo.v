/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
 * Serial-In Parallel-Out shift register
 * Shifted in on LSB, side so that first bit
 * shifted in will be MSB by end
 */
module sipo #(
    parameter WIDTH = 16
) (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire in,
    output wire [WIDTH-1:0] out
);

    reg [WIDTH-1:0] val;

    always @(posedge clk) begin
        if (rst) begin
            val <= {WIDTH{1'b0}};
        end else if (load) begin
            val <= {val[14:0], in};
        end else begin
            val <= val;
        end
    end

    assign out = val;

endmodule
