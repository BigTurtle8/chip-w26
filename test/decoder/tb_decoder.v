`timescale 1ns/1ps
module tb (
    input  wire clk,
    input  wire rst_n,
    input  wire [15:0] ins,
    input  wire begin_decode,
    output wire store,
    output wire load,
    output wire [3:0] tf,
    output wire [2:0] se,
    output wire [2:0] rt,
    output wire [5:0] imm,
    output wire l,
    output wire decode_done,
    output wire r2_or_imm,
    output wire shft
);
    decoder dut (
        .clk(clk),
        .rst_n(rst_n),
        .ins(ins),
        .begin_decode(begin_decode),
        .store(store),
        .load(load),
        .tf(tf),
        .se(se),
        .rt(rt),
        .imm(imm),
        .l(l),
        .decode_done(decode_done),
        .r2_or_imm(r2_or_imm),
        .shft(shft)
    );
endmodule