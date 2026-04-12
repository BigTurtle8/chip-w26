`timescale 1ns/1ps

module jdoodle;

    reg clk;
    reg ready;
    wire done;
    wire [8:0] x;
    wire [8:0] y;
    wire [8:0] z;
    
    calculate_points dut (
        .clk(clk),
        .ready(ready),
        .done(done),
        .x(x),
        .y(y),
        .z(z)
    );

    // Clock
    initial begin
        clk = 0;
        forever begin
            clk = 1; #0.5;
            clk = 0; #0.5;
        end
    end

    // Test: fire ready 5 times and watch x/y/z change
    initial begin
        ready = 0;
        #5;

        repeat (500) begin
            #0.5; // fall to falling edge
            ready = 1;
            #1;
            ready = 0;
            #1;
            $display("x=%d y=%d z=%d", $signed(x), $signed(y), $signed(z));
        end

        $finish(2);
    end

endmodule


module calculate_points (
	input wire ready,
    input wire clk,
    
    // 1st bit = sign, last 8 bits = val
    output wire [8:0] x,
    output wire [8:0] y,
    output wire [8:0] z,
    
    output reg done
);

// for shifting
localparam integer FRAC = 16;

localparam signed [63:0] SIGMA = 64'sd655360;
localparam signed [63:0] RHO   = 64'sd1835008;
localparam signed [63:0] BETA  = 64'sd174762;
localparam signed [63:0] DT    = 64'sd655;

// 32 bit regs 
reg signed [31:0] x_reg;
reg signed [31:0] y_reg;
reg signed [31:0] z_reg;

// sets initial reg values all to 1
// initial: runs once when FPGA is powered on 
initial begin
    x_reg = 32'h0001_0000;
    y_reg = 32'h0001_0000;
    z_reg = 32'h0001_0000;
end

// CLAUDE: to prevent overflow, do operations in bigger registers (copy 32 bit value + fill rest of reg w/ copies of sign bit)
wire signed [63:0] x64 = {{32{x_reg[31]}}, x_reg};
wire signed [63:0] y64 = {{32{y_reg[31]}}, y_reg};
wire signed [63:0] z64 = {{32{z_reg[31]}}, z_reg};

// calculation logic (shift by FRAC = 16 b/c numbers are represented as 16 bits int, 16 bits frac)

// X
wire signed [63:0] yx_diff  = y64 - x64;
wire signed [63:0] sigma_yx = (SIGMA * yx_diff) >>> FRAC;
wire signed [63:0] dx       = (sigma_yx * DT)   >>> FRAC;
 
// Y
wire signed [63:0] rho_z    = RHO - z64;
wire signed [63:0] x_rhoz   = (x64 * rho_z) >>> FRAC;
wire signed [63:0] dy       = ((x_rhoz - y64) * DT) >>> FRAC;
 
// Z
wire signed [63:0] xy_prod  = (x64  * y64) >>> FRAC;
wire signed [63:0] beta_z   = (BETA * z64) >>> FRAC;
wire signed [63:0] dz       = ((xy_prod - beta_z) * DT) >>> FRAC;
 
wire signed [31:0] x_next = x_reg + dx[31:0];
wire signed [31:0] y_next = y_reg + dy[31:0];
wire signed [31:0] z_next = z_reg + dz[31:0];

// extract most significant 9 bits
assign x = x_reg[FRAC+8 : FRAC];
assign y = y_reg[FRAC+8 : FRAC];
assign z = z_reg[FRAC+8 : FRAC];

always @(posedge clk) begin
    done <= 1'b0;
    if (ready) begin
        x_reg <= x_next;
        y_reg <= y_next;
        z_reg <= z_next;
        done  <= 1'b1;
    end
end

endmodule
