module executor #(
    parameter ALEN = 8,
    parameter IALEN = 11
) (
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

    // for loader/storer 

    // w/ pc
    input wire [IALEN-1:0] pc_addr,
    output wire pc_incr,
    output wire pc_we,
    output wire [IALEN-1:0] pc_new_addr
);

    wire [7:0] we;
    reg [7:0] op_out;

    wire [7:0] reg_out1;
    register reg1 (
        .clk(clk),
        .rst(rst),
        .we(we[1]),
        .in(op_out),
        .out(reg_out1)
    );

    wire [7:0] reg_out2;
    register reg2 (
        .clk(clk),
        .rst(rst),
        .we(we[2]),
        .in(op_out),
        .out(reg_out2)
    );

    wire [7:0] reg_out3;
    register reg3 (
        .clk(clk),
        .rst(rst),
        .we(we[3]),
        .in(op_out),
        .out(reg_out3)
    );

    wire [7:0] reg_out4;
    register reg4 (
        .clk(clk),
        .rst(rst),
        .we(we[4]),
        .in(op_out),
        .out(reg_out4)
    );

    wire [7:0] reg_out5;
    register reg5 (
        .clk(clk),
        .rst(rst),
        .we(we[5]),
        .in(op_out),
        .out(reg_out5)
    );

    wire [7:0] reg_out6;
    register reg6 (
        .clk(clk),
        .rst(rst),
        .we(we[6]),
        .in(op_out),
        .out(reg_out6)
    );

    wire [7:0] reg_out7;
    register reg7 (
        .clk(clk),
        .rst(rst),
        .we(we[7]),
        .in(op_out),
        .out(reg_out7)
    );

    reg [7:0] r1_val, r2_val;

    wire [7:0] raw_we = {
        tt == 3'd7,
        tt == 3'd6,
        tt == 3'd5,
        tt == 3'd4,
        tt == 3'd3,
        tt == 3'd2,
        tt == 3'd1,
        1'b0
    };

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
    end

    always @(*) begin
        case(op)
            3'b000: op_out = $signed(r1_val) + $signed(r2_val);
            3'b001: op_out = $signed(r1_val) + $signed(imm);
            // 3'b010: 
            // 3'b011:
            //3'b100: begin
            /*
                pc_we = 1'b1;
                pc_new_addr = $signed(r1_val) < $signed(r2_val) ? $signed(pc_addr) + $signed(op_out) : pc_addr;
            */
            3'b101: op_out = ~(r1_val & r2_val);
            3'b110: op_out = l ? r1_val << r2_val : r1_val >> r2_val;
            3'b111: op_out = l ? r1_val << imm : r1_val >> imm;
            default: op_out = 8'b0;
        endcase
    end

    assign we = raw_we & {8{begin_execute}};

    reg delayed_finished;
    always @(posedge clk) begin
        delayed_finished <= begin_execute;
    end

    assign pc_incr = begin_execute;
    assign executor_done = delayed_finished;

    assign pc_we = 1'b0;
    assign pc_new_addr = 11'b0;

endmodule
