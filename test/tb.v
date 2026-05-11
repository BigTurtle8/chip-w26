`default_nettype none
`timescale 1ns / 1ps

module tb ();
//
  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg miso;
  wire [7:0] uio_in = {5'b0, miso, 2'b0};

  wire [7:0] uo_out;

  wire [2:0] cs;
  wire sck;
  wire mosi;
  wire [7:0] uio_out;
  assign {cs[2], cs[1]} = uio_out[7:6];
  assign sck = uio_out[3];
  assign {mosi, cs[0]} = uio_out[1:0];

  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_madech_8bit_processor_vga dut (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );


  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
  end

endmodule
