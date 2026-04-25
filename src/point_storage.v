module point_storage (
   input  wire       clk,
   input  wire       rst_n,
   input  wire       valid_in,
   input  wire [9:0] x_in,
   input  wire [9:0] y_in,
   input  wire [9:0] z_in,
   output wire       ready_out,
   output wire [299:0] full_bus_out
);
   wire [29:0] point_in = { x_in, y_in, z_in };

   reg [29:0] memory [0:9];
   integer i;

   always @(posedge clk) begin
       if (!rst_n) begin
           for (i = 0; i < 10; i = i + 1) memory[i] <= 30'b0;
       end else if (valid_in) begin
           for (i = 9; i > 0; i = i - 1) memory[i] <= memory[i-1];
           memory[0] <= point_in;
       end
   end


   generate
       genvar j;
       for (j = 0; j < 10; j = j + 1) begin : flatten
           assign full_bus_out[(j*30) + 29 : (j*30)] = memory[j];
       end
   endgenerate


   assign ready_out = 1'b1;
endmodule
