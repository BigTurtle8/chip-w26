module calculator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ready,
    output reg         valid,
    output wire [29:0] out_xyz
);
    reg [9:0] count;
    reg [23:0] slow_clk; // Increased size to 24 bits for a longer wait

    always @(posedge clk) begin
        if (!rst_n) begin
            slow_clk <= 0;
            valid    <= 0;
            count    <= 0;
        end else begin
            // Slower speed: 5,000,000 cycles
            if (slow_clk >= 24'd5_000_000) begin 
                slow_clk <= 0;
                valid    <= 1; // Pulse valid for exactly ONE clock cycle
                count    <= count + 5; // Move by 5 pixels at a time
            end else begin
                slow_clk <= slow_clk + 1;
                valid    <= 0; // Ensure it's low otherwise
            end
        end
    end

    // X moves, Y is fixed, Z is max brightness (11 in top 2 bits)
    assign out_xyz = {count[9:0], 10'sd0, 10'b1100000000};
endmodule
