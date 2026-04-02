module point_storage (
   input  wire        clk,
   input  wire        rst_n,
   input  wire        valid_in,     // High when Calculator has new data
   input  wire [29:0] point_in,     // The new {X, Y, Z}
   output wire        ready_out,    // Always ready for this design
   output wire [299:0] full_bus_out // All 10 points at once
);


   // Memory array: 10 slots, 30 bits each
   reg [29:0] memory [0:9];
   integer i;


   // Shift logic: Move points down the line on every 'valid' pulse
   always @(posedge clk) begin
       if (!rst_n) begin
           for (i = 0; i < 10; i = i + 1) begin
               memory[i] <= 30'b0;
           end
       end else if (valid_in) begin
           // Shift points: 8 moves to 9, 0 moves to 1, etc.
           for (i = 9; i > 0; i = i - 1) begin
               memory[i] <= memory[i-1];
           end
           // Newest point always enters at position 0
           memory[0] <= point_in;
       end
   end


   // Flatten the 2D array into the 300-bit output bus
   generate
       genvar j;
       for (j = 0; j < 10; j = j + 1) begin : flatten
           assign full_bus_out[(j*30) + 29 : (j*30)] = memory[j];
       end
   endgenerate


   assign ready_out = 1'b1;


endmodule
