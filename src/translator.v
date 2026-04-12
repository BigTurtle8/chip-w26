module translator(
   input  wire [299:0] coords,          // 10 points * 30 bits
   output reg  [219:0] adjusted_coords  // 10 points * 22 bits
);
   integer i;
   reg signed [9:0] x_raw, y_raw, z_raw;


   always @(*) begin
       for (i = 0; i < 10; i = i + 1) begin
           // Syntax: [base_expr +: width]
           x_raw = coords[(i*30 + 20) +: 10]; // Starts at (i*30+20), width is 10
           y_raw = coords[(i*30 + 10) +: 10]; // Starts at (i*30+10), width is 10
           z_raw = coords[(i*30 + 0)  +: 10]; // Starts at (i*30+0),  width is 10


           adjusted_coords[(i*22 + 12) +: 10] = (x_raw <<< 3) + 10'sd320;
           adjusted_coords[(i*22 + 2)  +: 10] = (y_raw <<< 3) + 10'sd240;
           adjusted_coords[(i*22 + 0)  +: 2]  = z_raw[9:8];
       end
   end
endmodule
