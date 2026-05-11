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
    output wire mem_req,
    output wire mem_w_req,
    output wire [ALEN-1:0] mem_addr,
    input wire mem_valid,
    input wire [7:0] mem_val,
    output wire [7:0] mem_w_val,
    input wire mem_w_done,

    // w/ pc
    input wire [IALEN-1:0] pc_addr,
    output wire pc_incr,
    output wire pc_we,
    output wire [IALEN-1:0] pc_new_addr,

    // w/ project
    input wire [7:0] xpos,
    input wire [7:0] ypos,
    output wire [5:0] rgb               // { R[1:0], G[1:0], B[1:0] }
);

    wire [7:0] we;
    wire [7:0] reg_in;

    wire [7:0] reg_out1;
    register reg1 (
        .clk(clk),
        .rst(rst),
        .we(we[1]),
        .in(reg_in),
        .out(reg_out1)
    );

    wire [7:0] reg_out2;
    register reg2 (
        .clk(clk),
        .rst(rst),
        .we(we[2]),
        .in(reg_in),
        .out(reg_out2)
    );

    wire [7:0] reg_out3;
    register reg3 (
        .clk(clk),
        .rst(rst),
        .we(we[3]),
        .in(reg_in),
        .out(reg_out3)
    );

    wire [7:0] reg_out4;
    register reg4 (
        .clk(clk),
        .rst(rst),
        .we(we[4]),
        .in(reg_in),
        .out(reg_out4)
    );

    wire [7:0] reg_out5;
    register reg5 (
        .clk(clk),
        .rst(rst),
        .we(we[5]),
        .in(reg_in),
        .out(reg_out5)
    );

    wire is_branch = op == 3'b100;
    wire is_load_store = (op == 3'b010) | (op == 3'b011);
    wire is_rr_ri = ~(is_branch | is_load_store);
    wire finished_accessing;

    reg [7:0] tt_val, ns_val, sf_val;

    // Mux register for given index from
    // 12-10, 9-7, and 6-4
    always @(*) begin
        case (tt)
            3'd1: tt_val = reg_out1;
            3'd2: tt_val = reg_out2;
            3'd3: tt_val = reg_out3;
            3'd4: tt_val = reg_out4;
            3'd5: tt_val = reg_out5;
            3'd6: tt_val = xpos;
            3'd7: tt_val = ypos;
            default: tt_val = 8'd0;
        endcase

        case(ns)
            3'd1: ns_val = reg_out1;
            3'd2: ns_val = reg_out2;
            3'd3: ns_val = reg_out3;
            3'd4: ns_val = reg_out4;
            3'd5: ns_val = reg_out5;
            3'd6: ns_val = xpos;
            3'd7: ns_val = ypos;
            default: ns_val = 8'd0;
        endcase

        case(sf)
            3'd1: sf_val = reg_out1;
            3'd2: sf_val = reg_out2;
            3'd3: sf_val = reg_out3;
            3'd4: sf_val = reg_out4;
            3'd5: sf_val = reg_out5;
            3'd6: sf_val = xpos;
            3'd7: sf_val = ypos;
            default: sf_val = 8'd0;
        endcase
    end

    // Register-Register, Register-Immediate
    wire [7:0] r1_val = ns_val;
    wire [7:0] r2_val = sf_val;
    reg [7:0] op_out;
    always @(*) begin
        case(op)
            3'b000: op_out = $signed(r1_val) + $signed(r2_val);
            3'b001: op_out = $signed(r1_val) + $signed(imm);
            3'b101: op_out = ~(r1_val & r2_val);
            3'b110: op_out = l ? r1_val << r2_val : r1_val >> r2_val;
            3'b111: op_out = l ? r1_val << imm : r1_val >> imm;
            default: op_out = 8'b0;
        endcase
    end

    wire [7:0] rr_ri_we = {
        1'b0,
        1'b0,
        tt == 3'd5,
        tt == 3'd4,
        tt == 3'd3,
        tt == 3'd2,
        tt == 3'd1,
        1'b0
    };
    wire [7:0] rr_ri_reg_in = op_out;

    // Branch
    wire [7:0] ro_val = tt_val;
    wire lt = $signed(r1_val) < $signed(r2_val);
    assign pc_we = begin_execute & is_branch & lt;
    assign pc_new_addr = $signed(pc_addr) + $signed(ro_val);

    // Load/Store
    wire [7:0] ra_val = tt_val;
    wire [7:0] rv_val = ns_val;
    wire [7:0] loaded_val;
    wire finished_store_load;
    loader_storer #( .ALEN(8) ) ls (
        .clk(clk),
        .rst(rst),
        .is_store(op[0]),
        .begin_ls(begin_execute & is_load_store),
        .done_ls(finished_store_load),
        .addr(ra_val),
        .store_val(rv_val),
        .load_val(loaded_val),
        .mem_req(mem_req),
        .mem_w_req(mem_w_req),
        .mem_addr(mem_addr),
        .mem_valid(mem_valid),
        .mem_val(mem_val),
        .mem_w_val(mem_w_val),
        .mem_w_done(mem_w_done)
    );

    wire [7:0] load_we = {
        1'b0,
        1'b0,
        ns == 3'd5,
        ns == 3'd4,
        ns == 3'd3,
        ns == 3'd2,
        ns == 3'd1,
        1'b0
    };

    assign we = (rr_ri_we & {8{begin_execute & is_rr_ri}})
                | (load_we & {8{finished_store_load & ~op[0]}});
    assign reg_in = finished_store_load ? loaded_val : op_out;

    // General control
    assign pc_incr = begin_execute & (~is_branch | (is_branch & ~lt));

    reg delayed_finished;
    always @(posedge clk) begin
        delayed_finished <= begin_execute & ~is_load_store;
    end

    assign executor_done = delayed_finished | finished_store_load;

    assign rgb = reg_out5[5:0];

endmodule
