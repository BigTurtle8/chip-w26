`default_nettype none
`timescale 1ns / 1ps

module tb ();
  reg clk;
  reg rst;

  // Since we are bypassing processor_top, we need to create 
  // the signals that processor_no_spi expects
  wire fetch_req;
  wire [10:0] fetch_addr;
  wire fetch_valid;     // Always valid for simple simulation
  wire [15:0] fetch_instr;

  // Memory interface signals (can be left open if not testing RAM yet)
  wire mem_req, mem_w_req;
  wire [7:0] mem_addr, mem_w_val;
  wire [7:0] mem_val;
  wire mem_valid = 1'b0;
  wire mem_w_done = 1'b0;

  // IO Signals
  reg [7:0] xpos = 8'h0;
  reg [7:0] ypos = 8'h0;
  wire [5:0] rgb;

  // 1. Instantiate the CORE directly
  processor_no_spi dut (
    .clk(clk),
    .rst(rst),
    .fetch_req(fetch_req),
    .fetch_addr(fetch_addr),
    .fetch_valid(fetch_valid),
    .fetch_instr(fetch_instr),
    .mem_req(mem_req),
    .mem_w_req(mem_w_req),
    .mem_addr(mem_addr),
    .mem_valid(mem_valid),
    .mem_val(mem_val),
    .mem_w_val(mem_w_val),
    .mem_w_done(mem_w_done),
    .xpos(xpos),
    .ypos(ypos),
    .rgb(rgb)
  );

  // // 2. Instantiate the Memory Handler so we can load the program
  // // This replaces the "mh" that was missing before
  // mem_handler mh (
  //   .clk(clk),
  //   .rst(rst),
  //   .fetch_req(fetch_req),
  //   .fetch_addr(fetch_addr),
  //   .fetch_valid(fetch_valid),
  //   .fetch_instr(fetch_instr),
  //   // Connect remaining pins to dummy signals or 0
  //   .mem_req(1'b0),
  //   .mem_w_req(1'b0),
  //   .mem_addr(8'b0),
  //   .mem_w_val(8'b0),
  //   .miso(1'b0)
  // );


  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
  end

endmodule