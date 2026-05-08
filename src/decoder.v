module decoder (
    input  wire clk,
    input  wire rst_n,
 
    input wire [15:0] ins,
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
    output reg shft
);
 
    wire [2:0] opcode = ins[2:0];
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            store <= 1'b0;
            load <= 1'b0;
            tf <= 4'b0000;
            se <= 3'b000;
            rt <= 3'b000;
            imm <= 6'b000000;
            l <= 1'b0;
            r2_or_imm <= 1'b0;
            shft <= 1'b0;
            decode_done <= 1'b0;
        end else if (begin_decode) begin
            store <= (opcode == 3'b011);
            load <= (opcode == 3'b010); 
            shft <= (opcode == 3'b110) | (opcode == 3'b111); 
            r2_or_imm <= (opcode == 3'b001) | (opcode == 3'b111);
 
            tf <= {ins[5:3], (opcode == 3'b100)};
            se <= ins[8:6];
            rt <= ins[11:9];
            imm <= ins[14:9];
            l <= ins[15];
 
            decode_done <= 1'b1;
        end else begin
            decode_done <= 1'b0;
        end
    end
 
endmodule
