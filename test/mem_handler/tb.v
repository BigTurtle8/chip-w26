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
    reg fetch_req;
    reg [10:0] fetch_addr;
    reg mem_req;
    reg mem_w_req;
    reg [7:0] mem_addr;
    reg [7:0] mem_w_val;
    reg miso;

    wire fetch_valid;
    wire [15:0] fetch_instr;
    wire mem_valid;
    wire [7:0] mem_val;
    wire mem_w_done;
    wire sck;
    wire [2:0] cs;
    wire mosi;
    `ifdef GL_TEST
        wire VPWR = 1'b1;
        wire VGND = 1'b0;
    `endif

    mem_handler dut (

    // Include power ports for the Gate Level test:
    `ifdef GL_TEST
        .VPWR(VPWR),
        .VGND(VGND),
    `endif

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
        .sck(sck),
        .cs(cs),
        .mosi(mosi),
        .miso(miso)

    );

endmodule
