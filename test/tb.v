`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Wire up the inputs and outputs:
  reg clk;
  reg rst;
  wire sck;
  wire [2:0] cs;
  wire mosi;
  reg miso;
  reg [7:0] xpos;
  reg [7:0] ypos;
  wire [5:0] rgb;

  processor_top dut (
    .clk(clk),
    .rst(rst),
    .sck(sck),
    .cs(cs),
    .mosi(mosi),
    .miso(miso),
    .xpos(xpos),
    .ypos(ypos),
    .rgb(rgb)
);

  initial begin
    /*
      // Reach into: dut -> mh (the mem_handler) -> rom (the array)
      $readmemb("program.hex", dut.mh.rom);
    */
      // Standard Cocotb/Dumpfile setup
      $dumpfile("tb.fst");
      $dumpvars(0, tb);
  end

endmodule
