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
    wire [2:0] tt;
    wire [2:0] ns;
    wire [2:0] sf;
    wire [5:0] imm;
    wire l;
    wire [2:0] op;
    decoder decoder_instance (
        .clk(clk),
        .rst(rst),
        .ins(instr),
        .begin_decode(begin_decode),
        .tt(tt),
        .ns(ns),
        .sf(sf),
        .imm(imm),
        .l(l),
        .decode_done(decode_done),
        .op(op)
    );

    wire is_store;
    wire we;
    wire [ALEN-1:0] new_addr;
    executor #(
        .ALEN(ALEN),
        .IALEN(IALEN)
    ) exeggutor_instance (
        .clk(clk),
        .rst(rst),
        .begin_execute(begin_executor),
        .executor_done(executor_done),
        .op(op),
        .tt(tt),
        .ns(ns),
        .sf(sf),
        .imm(imm),
        .l(l),
        .pc_addr(pc_addr),
        .pc_incr(pc_incr),
        .pc_we(pc_we),
        .pc_new_addr(pc_new_addr)
    );

    assign rgb = 6'd0;

endmodule
