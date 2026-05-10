module decoder (
    input  wire clk,
    input  wire rst,
 
    input wire [15:0] instruction,
    input wire begin_decode,
 
    output reg store,
    output reg load,
    output reg [3:0] tf,
    output reg [2:0] se,
    output reg [2:0] rt,
    output reg [5:0] imm,
    output reg l,
    output reg decode_done,
    output reg r2_or_imm,
    output reg shft,
    output reg nand_op
);
 
    wire [2:0] opcode = instruction[2:0];
 
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            store <= 1'b0;
            load <= 1'b0;
            tf <= 4'b0000;
            se <= 3'b000;
            rt <= 3'b000;
            imm <= 6'b000000;
            l <= 1'b0;
            r2_or_imm <= 1'b0;
            shft <= 1'b0;
            nand_op <= 1'b0;
            decode_done <= 1'b0;
        end else if (begin_decode) begin
            nand_op <= (opcode == 3'b101);
            store <= (opcode == 3'b011);
            load <= (opcode == 3'b010); 
            shft <= (opcode == 3'b110) | (opcode == 3'b111); 
            r2_or_imm <= (opcode == 3'b001) | (opcode == 3'b111);
 
            tf <= {instruction[5:3], (opcode == 3'b100)};
            se <= instruction[8:6];
            rt <= instruction[11:9];
            imm <= instruction[14:9];
            l <= instruction[15];
 
            decode_done <= 1'b1;
        end else begin
            decode_done <= 1'b0;
        end
    end
 
endmodule
