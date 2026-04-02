module calculator (
   input  wire        clk,
   input  wire        rst_n,
   input  wire        ready,      // From Storage
   output reg         valid,      // To Storage
   output wire [29:0] out_xyz     // The {X, Y, Z} point
);


   reg [9:0] x_reg, y_reg, z_reg;
   reg [19:0] slow_clk; // To slow down the movement


   // 1. Slow down the calculation so we can actually see it
   // Without this, the points would move 25 million times per second!
   always @(posedge clk) begin
       if (!rst_n) begin
           slow_clk <= 0;
           valid    <= 0;
           x_reg    <= 10'sd0;
           y_reg    <= 10'sd0;
           z_reg    <= 10'sd0;
       end else begin
           slow_clk <= slow_clk + 1;
          
           // Trigger a new point roughly 24 times per second
           if (slow_clk == 20'd1_000_000) begin
               slow_clk <= 0;
               valid    <= 1;
              
               // Move in a diagonal "bounce" pattern
               x_reg <= x_reg + 10'sd1;
               y_reg <= y_reg + 10'sd1;
               z_reg <= z_reg + 10'sd25; // Change brightness rapidly
              
               // Reset if it goes too far (Lorentz world is roughly -20 to 20)
               if (x_reg > 10'sd25) begin
                   x_reg <= -10'sd25;
                   y_reg <= -10'sd25;
               end
           end else begin
               valid <= 0;
           end
       end
   end


   // Pack the output: [X(10), Y(10), Z(10)]
   assign out_xyz = {x_reg, y_reg, z_reg};


endmodule