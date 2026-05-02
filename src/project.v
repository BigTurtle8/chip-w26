/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_8bit_processor_vga (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  // program counter (PC)
  reg [15:0] program_counter;
  // register file
  reg [15:0] registers [0:7];

  // fetch logic: PC needs to know how to react when the clk ticks or when the rst_n is pressed
  always @(posedge clk) begin
    if (!rst_n) begin // resetting (n = negative/active low)
      program_counter <= 16'b0;
    end else begin
      // otherwise, update PC by 2
      program_counter <= program_counter + 16'd2;
    end
  end

  // 16-bit instruction that the PC will read
  reg [15:0] instruction;

  wire [2:0] opcode = instruction[15:13];
  destination

endmodule
