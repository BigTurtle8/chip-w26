/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module mem_handler #(
    parameter IALEN = 11,
    parameter ALEN = 8
) (
    input  wire clk,
    input  wire rst,
    input  wire fetch_req,
    input  wire [IALEN-1:0] fetch_addr,
    output wire fetch_valid,
    output wire [15:0] fetch_instr,
    input  wire mem_req,
    input  wire mem_w_req,
    input  wire [ALEN-1:0] mem_addr,
    output wire mem_valid,
    output wire [7:0] mem_val,
    input  wire [7:0] mem_w_val,
    output wire mem_w_done,
    output wire sck,
    output reg  [2:0] cs,               // ACTIVE LOW, 2 (RAM B), 1 (RAM A), 0 (Flash)
    output reg  mosi,
    input  wire miso
);

    localparam IDLE = 2'b00;
    localparam FETCHING = 2'b01;
    localparam LOADING = 2'b10;
    localparam STORING = 2'b11;
    reg [1:0] state;

    wire start_fetch = (state == IDLE) & fetch_req;
    wire start_load = (state == IDLE) & mem_req;
    wire start_write = (state == IDLE) & mem_w_req;
    wire finished_transaction;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            cs <= 3'b111;
        end else if (start_fetch) begin
            state <= FETCHING;
            cs <= 3'b110;
        end else if (start_load) begin
            state <= LOADING;
            cs <= 3'b101;
        end else if (start_write) begin
            state <= STORING;
            cs <= 3'b101;
        end else if (finished_transaction) begin
            state <= IDLE;
            cs <= 3'b111;
        end else begin
            state <= state;
            cs <= cs;
        end
    end

    // Need 8 sck for instruction, 24 for address,
    // up to 16 for data, and 2 for synchronization
    // so need to track up to "50 sck", which fits within 6 bits

    // "Divide" `clk` by 2 to use for `sck`
    // `mosi` should NOT change while `sck` is changing,
    //  for safety
    wire in_transaction = (state != IDLE);

    reg [5:0] sck_counter;
    reg sck_state;
    always @(posedge clk) begin
        if (rst) begin
            sck_counter <= 6'd0;
            sck_state <= 1'b0;
        end else if (start_fetch | start_load | start_write) begin
            sck_counter <= 6'd0;
            sck_state <= 1'b0;
        end else if (in_transaction & ~finished_transaction) begin
            if (sck_state == 1) begin
                sck_counter <= sck_counter + 1;
            end else begin
                sck_counter <= sck_counter;
            end
            sck_state <= ~sck_state;
        end else begin
            sck_counter <= 6'd0;
            sck_state <= 1'b0;
        end
    end

    // Don't output last `sck` cycles in read, as falling
    // edge of previous is what loads and if cycle again then
    // will begin reading from following byte
    wire is_last_read = ((state == FETCHING) & (sck_counter >= 47)) |
                        ((state == LOADING) & (sck_counter >= 39));
    assign sck = is_last_read ? 1'b0 : sck_state ;

    wire is_reading = (state == FETCHING) | (state == LOADING);
    // Two (relevant) SPI instructions:
    always @(*) begin
        if (sck_counter < 8) begin
            //  READ:  0x03
            //  WRITE: 0x02
            case (sck_counter)
                0, 1, 2, 3, 4, 5:   mosi = 1'b0;
                6:                  mosi = 1'b1;
                7:                  mosi = is_reading ? 1'b1 : 1'b0;
                default:            mosi = 1'b0;
            endcase
        end else if (sck_counter < 32) begin
            // MSB first
            if (state == FETCHING) begin
                if (sck_counter < 32 - IALEN) begin
                    mosi = 1'b0;
                end else begin
                    mosi = fetch_addr[31 - sck_counter];
                end
            end else begin
                if (sck_counter < 32 - ALEN) begin
                    mosi = 1'b0;
                end else begin
                    mosi = mem_addr[31 - sck_counter];
                end
            end
        end else if ((state == STORING) & ~finished_transaction) begin
            mosi = mem_w_val[39 - sck_counter];
        end else begin
            mosi = 1'b0;
        end
    end

    // Brute-force sync over 4 cycles (2 SCK cycles),
    // in case of metastability issues
    reg [3:0] syncing_miso;
    always @(posedge clk) begin
        if (rst)    syncing_miso = 4'b0;
        else        syncing_miso <= {syncing_miso[3:0], miso};
    end
    wire sync_miso = syncing_miso[3];

    // Load in on rising edge of `sck_state`
    // so that can also read last bit even though
    // `sck` is not asserted on it
    wire load = is_reading & (sck_counter >= 32) & (sck_state == 0);
    wire [15:0] loaded_val;
    sipo #( .WIDTH(16) ) sipo_inst (
        .clk(clk),
        .rst(rst),
        .load(load),
        .in(sync_miso),
        .out(loaded_val)
    );

    assign fetch_instr = loaded_val;
    assign mem_val = loaded_val[7:0];

    wire finished_fetch = (state == FETCHING) & (sck_counter == 50);
    wire finished_load = (state == LOADING) & (sck_counter == 42);
    wire finished_write = (state == STORING) & (sck_counter == 40);
    assign finished_transaction = finished_fetch |
                                    finished_load |
                                    finished_write;

    assign fetch_valid = finished_fetch;
    assign mem_valid = finished_load;
    assign mem_w_done = finished_write;

endmodule
