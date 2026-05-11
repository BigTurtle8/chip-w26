module decoder (
    input  wire clk,
    input  wire rst,
 
    input wire [15:0] ins,
    input wire begin_decode,

    output wire [2:0] op,
    output wire [2:0] tt, // og: tf
    output wire [2:0] ns, // og: se
    output wire [2:0] sf, // og: rt
    output wire [5:0] imm,
    output wire l,

    output wire decode_done
);
 
    assign op = ins[15:13];
    assign tt = ins[12:10];
    assign ns = ins[9:7];
    assign sf = ins[6:4];
    assign imm = ins[6:1];
    assign l = ins[0];

    assign decode_done = begin_decode;
 
endmodule
