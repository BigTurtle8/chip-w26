`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

    // Dump the signals to a FST file. You can view it with gtkwave or surfer.
    initial begin
        $dumpfile("tb.fst");
        $dumpvars(0, tb);
        #1;
    end

    // Wire up the inputs and outputs:
    reg clk;
    reg rst;
    reg begin_store;
    reg [7:0] addr;
    reg [7:0] store_val;
    reg mem_w_done;
    wire store_done;
    wire mem_w_req;
    wire [7:0] mem_addr;
    wire [7:0] mem_w_val;
    `ifdef GL_TEST
        wire VPWR = 1'b1;
        wire VGND = 1'b0;
    `endif

    // Replace tt_um_example with your module name:
    storer dut (

    // Include power ports for the Gate Level test:
    `ifdef GL_TEST
        .VPWR(VPWR),
        .VGND(VGND),
    `endif

        .clk(clk),
        .rst(rst),
        .begin_store(begin_store),
        .store_done(store_done),
        .addr(addr),
        .store_val(store_val),
        .mem_w_req(mem_w_req),
        .mem_addr(mem_addr),
        .mem_w_val(mem_w_val),
        .mem_w_done(mem_w_done)

    );

endmodule
