/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module loader_storer #(
    parameter ALEN = 8
) (
    input  wire clk,
    input  wire rst,
    input  wire is_store,           // 0 = load, 1 = store
    input  wire begin_ls,
    output wire done_ls,
    input  wire [ALEN-1:0] addr,
    input  wire [7:0] store_val,
    output wire [7:0] load_val,
    output wire mem_req,
    output wire mem_w_req,
    output wire [ALEN-1:0] mem_addr,
    input  wire mem_valid,
    input  wire [7:0] mem_val,
    output wire [7:0] mem_w_val,
    input  wire mem_w_done
);

    reg is_started_store;
    always @(posedge clk) begin
        if (rst)
            is_started_store <= 0;
        else if (begin_Ls)
            is_started_store <= is_store;
        else
            is_started_store <= is_started_store;
    end

    wire load_done;
    wire [ALEN-1:0] load_mem_addr;
    loader loader_inst (
        .clk(clk),
        .rst(rst),
        .begin_load(~is_store & begin_ls),
        .load_done(load_done),
        .addr(addr),
        .load_val(load_val),
        .mem_req(mem_req),
        .mem_addr(load_mem_addr),
        .mem_valid(mem_valid),
        .mem_val(mem_val)
    );

    wire store_done;
    wire [ALEN-1:0] store_mem_addr;
    storer storer_inst (
        .clk(clk),
        .rst(rst),
        .begin_store(is_store & begin_ls),
        .store_done(store_done),
        .addr(addr),
        .store_val(store_val),
        .mem_w_req(mem_w_req),
        .mem_addr(store_mem_addr),
        .mem_w_val(mem_w_val),
        .mem_w_done(mem_w_done)
    );

    assign mem_addr = ((begin_ls & is_store) | is_started_store)
                        ? store_mem_addr : load_mem_addr;
    assign done_ls = load_done | store_done;

endmodule
