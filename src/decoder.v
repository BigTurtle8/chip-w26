module decoder (
    input  wire clk,
    input  wire rst,
 
    input wire [15:0] ins,
    input wire begin_decode,

    output wire [2:0] op,
    output reg [2:0] tt, // og: tf
    output reg [2:0] ns, // og: se
    output reg [2:0] sf, // og: rt
    output reg [5:0] imm,
    output reg l,

    output reg decode_done
    
);
 
    wire [2:0] opcode = ins[15:13];
    assign op = opcode;
 
    always @(posedge clk) begin
        if (rst) begin
            tt <= 3'd0;
            ns <= 3'd0;
            sf <= 3'd0;
            imm <= 6'd0;
            l <= 1'd0;

            decode_done <= 1'd0;

        end else if (begin_decode) begin

            tt <= ins[12:10];
            ns <= ins[9:7];
            sf <= ins[6:4];
            imm <= ins[6:1];
            l <= ins[0];

            decode_done <= 1'b1;

        end else begin
            decode_done <= 1'b0;
        end
    end
 
endmodule