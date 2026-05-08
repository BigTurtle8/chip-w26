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
    reg begin_fetch;
    reg [10:0] pc_addr;
    reg fetch_valid;
    reg [15:0] fetch_instr;
    wire fetch_done;
    wire fetch_req;
    wire [10:0] fetch_addr;
    wire [15:0] instr;
    `ifdef GL_TEST
        wire VPWR = 1'b1;
        wire VGND = 1'b0;
    `endif

    // Replace tt_um_example with your module name:
    fetcher dut (

    // Include power ports for the Gate Level test:
    `ifdef GL_TEST
        .VPWR(VPWR),
        .VGND(VGND),
    `endif

        .clk(clk),
        .rst(rst),
        .begin_fetch(begin_fetch),
        .fetch_done(fetch_done),
        .pc_addr(pc_addr),
        .fetch_req(fetch_req),
        .fetch_addr(fetch_addr),
        .fetch_valid(fetch_valid),
        .fetch_instr(fetch_instr),
        .instr(instr)

    );

endmodule
