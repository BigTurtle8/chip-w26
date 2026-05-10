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
    reg fetch_done, decode_done, executor_done;
    wire begin_fetch, begin_decode, begin_executor;
    wire [10:0] pc;
    `ifdef GL_TEST
        wire VPWR = 1'b1;
        wire VGND = 1'b0;
    `endif

    // Replace tt_um_example with your module name:
    controller dut (

    // Include power ports for the Gate Level test:
    `ifdef GL_TEST
        .VPWR(VPWR),
        .VGND(VGND),
    `endif

        .clk(clk),
        .rst(rst),
        .begin_fetch(begin_fetch),
        .fetch_done(fetch_done),
        .begin_decode(begin_decode),
        .decode_done(decode_done),
        .begin_executor(begin_executor),
        .executor_done(executor_done)

    );

endmodule
