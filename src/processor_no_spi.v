/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module processor_no_spi #(
    parameter IALEN = 11,
    parameter ALEN = 8
) (
    input  wire clk,
    input  wire rst,
    output wire fetch_req,
    output wire [IALEN-1:0] fetch_addr,
    input  wire fetch_valid,
    input  wire [15:0] fetch_instr,
    output wire mem_req,
    output wire mem_w_req,
    output wire [ALEN-1:0] mem_addr,
    input  wire mem_valid,
    input  wire [7:0] mem_val,
    output wire [7:0] mem_w_val,
    input  wire mem_w_done,
    input  wire [7:0] xpos,
    input  wire [7:0] ypos,
    output wire [5:0] rgb               // { R[1:0], G[1:0], B[1:0] }
);

    wire _unused_ok = &{mem_valid, mem_val, mem_w_done, xpos, ypos};

    assign mem_req = 1'b0;
    assign mem_w_req = 1'b0;
    assign mem_addr = {ALEN{1'b0}};
    assign mem_w_val = 8'b0;

    wire [IALEN-1:0] pc_addr;
    wire pc_incr;
    wire [IALEN-1:0] pc_new_addr;
    wire pc_we;
    pc #(
        .IALEN(IALEN),
        .ALEN(ALEN)
    ) pc_instance (
        .clk(clk),
        .rst(rst),
        .pc(pc_addr),
        .incr(pc_incr),
        .new_addr(pc_new_addr),
        .we(pc_we)
    );

    wire begin_fetch, fetch_done;
    wire begin_decode, decode_done;
    wire begin_executor, executor_done;
    controller controller_instance (
        .clk(clk),
        .rst(rst),
        .begin_fetch(begin_fetch),
        .fetch_done(fetch_done),
        .begin_decode(begin_decode),
        .decode_done(decode_done),
        .begin_executor(begin_executor),
        .executor_done(executor_done)
    );

    wire [15:0] instr;
    fetcher #(
        .IALEN(IALEN)
    ) fetcher_instance (
        .clk(clk),
        .rst(rst),
        .begin_fetch(begin_fetch),
        .fetch_done(fetch_done),
        .pc_addr(pc_addr),
        .fetch_req(fetch_req),
        .fetch_addr(fetch_addr),
        .fetch_valid(fetch_valid),
        .fetch_instr(fetch_instr),
        .instr(instr)
    );

    wire store, load;
    wire [3:0] tf;
    wire [2:0] se;
    wire [2:0] rt;
    wire [5:0] imm;
    wire l;
    wire r2_or_imm;
    wire shft;
    decoder decoder_instance (
        .clk(clk),
        .rst_n(~rst),      // To change to `rst`?
        .ins(instr),    // To change to `instruction`?
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

    wire lsi_begin;
    wire lsi_done = 1'b0;
    wire is_store;
    wire [ALEN-1:0] addr;
    wire [7:0] store_val;
    wire [7:0] load_val = 8'b0;
    wire [7:0] in_reg;
    wire [7:0] out_reg = 8'b0;
    wire we;
    executor #(
        .ALEN(ALEN),
        .IALEN(IALEN)
    ) exeggutor_instance (
        .clk(clk),
        .rst(rst),
        .begin_executor(begin_executor),
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

        .lsi_begin(lsi_begin),
        .lsi_done(lsi_done),
        .is_store(is_store),
        .addr(addr),
        .store_val(store_val),
        .load_val(load_val),
        .in_reg(in_reg),
        .out_reg(out_reg),
        .we(we),

        .pc_new_addr(pc_new_addr),
        .pc_we(pc_we),
        .pc_incr(pc_incr),
        .current_pc(pc_addr)
    );

    assign rgb = addr[6:1] ^ store_val[6:1] ^ in_reg[6:1];

endmodule
