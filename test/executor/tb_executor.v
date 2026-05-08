`timescale 1ns/1ps
module tb #(
    parameter ALEN  = 8,
    parameter IALEN = 11
) (
    input  wire             clk,
    input  wire             rst,

    // Controller interface
    input  wire             begin_execute,
    output wire             executor_done,

    // Decoded signals
    input  wire             store,
    input  wire             load,
    input  wire [3:0]       tf,
    input  wire [2:0]       se,
    input  wire [2:0]       rt,
    input  wire [5:0]       imm,
    input  wire             l,
    input  wire             r2_or_imm,
    input  wire             shft,
    input  wire             nand_op,

    // Loader/storer interface
    output wire             lsi_begin,
    input  wire             lsi_done,
    output wire             is_store,
    output wire [ALEN-1:0]  lsi_addr,
    output wire [7:0]       store_val,
    input  wire [7:0]       load_val,

    // PC interface
    input  wire [IALEN-1:0] new_addr,
    output wire             pc_we,
    output wire [IALEN-1:0] pc_new_addr
);
    executor #(
        .ALEN(ALEN),
        .IALEN(IALEN)
    ) dut (
        .clk(clk),
        .rst(rst),
        .begin_execute(begin_execute),
        .executor_done(executor_done),
        .store(store),
        .load(load),
        .tf(tf),
        .se(se),
        .rt(rt),
        .imm(imm),
        .l(l),
        .r2_or_imm(r2_or_imm),
        .shft(shft),
        .nand_op(nand_op),
        .lsi_begin(lsi_begin),
        .lsi_done(lsi_done),
        .is_store(is_store),
        .lsi_addr(lsi_addr),
        .store_val(store_val),
        .load_val(load_val),
        .new_addr(new_addr),
        .pc_we(pc_we),
        .pc_new_addr(pc_new_addr)
    );
endmodule