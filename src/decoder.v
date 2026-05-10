module decoder (
    input  wire clk,
    input  wire rst,
 
    input wire [15:0] ins,
    input wire begin_decode,
 
    output reg store,
    output reg load,
    output reg [3:0] tt, // og: tf
    output reg [2:0] ns, // og: se
    output reg [2:0] sf, // og: rt
    output reg [5:0] imm,
    output reg l,
    output reg decode_done,
    output reg r2_or_imm,
    output reg shft
);
 
    wire [2:0] opcode = ins[15:13];
 
    always @(posedge clk) begin
        if (rst) begin
            store <= 1'd0;
            load <= 1'd0;
            tf <= 4'd0;
            se <= 3'd0;
            rt <= 3'd0;
            imm <= 6'd0;
            l <= 1'd0;
            r2_or_imm <= 1'bd;
            shft <= 1'd0;
            decode_done <= 1'd0;
        end else if (begin_decode) begin
            store <= (opcode == 3'b011);
            load <= (opcode == 3'b010); 
            shft <= (opcode == 3'b110) | (opcode == 3'b111); 
            r2_or_imm <= (opcode == 3'b001) | (opcode == 3'b111);
 
            tt <= {ins[12:10], (opcode == 3'b100)};
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