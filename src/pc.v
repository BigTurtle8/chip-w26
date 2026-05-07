/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module pc #(
    parameter IALEN = 11,
    parameter ALEN = 8
) (
    input  wire clk,
    input  wire rst,
    output reg  [IALEN-1:0] pc,
    input  wire incr,                   // increments address by 2
    input  wire [IALEN-1:0] new_addr,
    input  wire we                      // takes priority over `incr`
);

    always @(posedge clk) begin
        if (rst) begin
            pc <= {IALEN{1'b0}};  // reset to instruction at address 0
        end else if (we) begin
            pc <= new_addr;
        end else if (incr) begin
            pc <= pc + 2;
        end else begin
            pc <= pc;
        end
    end

endmodule
