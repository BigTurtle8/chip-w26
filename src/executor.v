module executor #(
	parameter ALEN = 8,
	parameter IALEN = 11
)(
    input wire clk,
    input wire rst,

    // w/ controller
    input wire begin_execute,
    output reg executor_done,

    // w/ decoder
	input wire [2:0] op,
    input wire [2:0] tt,
    input wire [2:0] ns,
    input wire [2:0] sf, 
    input wire [5:0] imm,
	input wire l,

    // w/ loader/storer 
    output reg is_store,

    // w/ pc
    output reg we,
    output reg [IALEN-1:0] new_addr
);

	wire we1;
	wire [ALEN-1:0] reg_in1;
	wire [ALEN-1:0] reg_out1;
	register reg1 (
		.clk(clk),
		.rst(rst),
		.we(we1),
		.in(reg_in1),
		.out(reg_out1)
	);

	wire we2;
	wire [ALEN-1:0] reg_in2;
	wire [ALEN-1:0] reg_out2;
	register reg2 (
		.clk(clk),
		.rst(rst),
		.we(we2),
		.in(reg_in2),
		.out(reg_out2)
	);

	wire we3;
	wire [ALEN-1:0] reg_in3;
	wire [ALEN-1:0] reg_out3;
	register reg3 (
		.clk(clk),
		.rst(rst),
		.we(we3),
		.in(reg_in3),
		.out(reg_out3)
	);

	wire we4;
	wire [ALEN-1:0] reg_in4;
	wire [ALEN-1:0] reg_out4;
	register reg4 (
		.clk(clk),
		.rst(rst),
		.we(we4),
		.in(reg_in4),
		.out(reg_out4)
	);

	wire we5;
	wire [ALEN-1:0] reg_in5;
	wire [ALEN-1:0] reg_out5;
	register reg5 (
		.clk(clk),
		.rst(rst),
		.we(we5),
		.in(reg_in5),
		.out(reg_out5)
	);

	wire we6;
	wire [7:0] reg_in6;
	wire [7:0] reg_out6;
	register reg6 (
		.clk(clk),
		.rst(rst),
		.we(we6),
		.in(reg_in6),
		.out(reg_out6)
	);

	wire we7;
	wire [7:0] reg_in7;
	wire [7:0] reg_out7;
	register reg7 (
		.clk(clk),
		.rst(rst),
		.we(we7),
		.in(reg_in7),
		.out(reg_out7)
	);

	reg [7:0] op_out, r1_val, r2_val;

	assign we1 = (tt == 3'd1);
	assign we2 = (tt == 3'd2);
	assign we3 = (tt == 3'd3);
	assign we4 = (tt == 3'd4);
	assign we5 = (tt == 3'd5);
	assign we6 = (tt == 3'd6);
	assign we7 = (tt == 3'd7);

	assign reg_in1 = (we1) ? op_out : 8'd0;
	assign reg_in2 = (we2) ? op_out : 8'd0;
	assign reg_in3 = (we3) ? op_out : 8'd0;
	assign reg_in4 = (we4) ? op_out : 8'd0;
	assign reg_in5 = (we5) ? op_out : 8'd0;
	assign reg_in6 = (we6) ? op_out : 8'd0;
	assign reg_in7 = (we7) ? op_out : 8'd0;

	always @(*) begin
		case(ns)
			3'd1: r1_val = reg_out1;
			3'd2: r1_val = reg_out2;
			3'd3: r1_val = reg_out3;
			3'd4: r1_val = reg_out4;
			3'd5: r1_val = reg_out5;
			3'd6: r1_val = reg_out6;
			3'd7: r1_val = reg_out7;
			default: r1_val = 8'd0;
		endcase

		case(sf)
			3'd1: r2_val = reg_out1;
			3'd2: r2_val = reg_out2;
			3'd3: r2_val = reg_out3;
			3'd4: r2_val = reg_out4;
			3'd5: r2_val = reg_out5;
			3'd6: r2_val = reg_out6;
			3'd7: r2_val = reg_out7;
			default: r2_val = 8'd0;
		endcase

        case(op)
			3'b000: op_out = r1_val + r2_val;
			3'b001: op_out = r1_val + imm;
			// 3'b010: 
			3'b011: begin
					is_store = 1'b1;
					end
			3'b100: begin
					we = 1'b1;
					new_addr = r1_val < r2_val ? new_addr + op_out : new_addr;
					end 
			3'b101: op_out = ~(r1_val & r2_val);
			3'b110: op_out = l ? r1_val << r2_val : r1_val >> r2_val;
			3'b111: op_out = l ? r1_val << imm : r1_val >> imm;
			default: op_out = 8'b0;
        endcase
	end


endmodule



