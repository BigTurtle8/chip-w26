module translator(
 input  wire [299:0] coords,          // 10 points * 30 bits (X:10, Y:10, Z:10)
 output reg  [219:0] adjusted_coords  // 10 points * 22 bits (X:10, Y:10, Z_depth:2)
);


 integer i;
  // Internal wires for signed math
 reg signed [9:0] x_raw, y_raw, z_raw;


 always @(*) begin
   for (i = 0; i < 10; i = i + 1) begin
       // 1. Unpack the 30-bit "World" coordinates
       x_raw = coords[(i*30) + 29 : (i*30) + 20];
       y_raw = coords[(i*30) + 19 : (i*30) + 10];
       z_raw = coords[(i*30) + 9  : (i*30) + 0];


       // 2. Map X and Y to the Screen (Scale by 8, then center)
       // X screen (10 bits)
       adjusted_coords[(i*22) + 21 : (i*22) + 12] = (x_raw <<< 3) + 10'sd320;
      
       // Y screen (10 bits)
       adjusted_coords[(i*22) + 11 : (i*22) + 2]  = (y_raw <<< 3) + 10'sd240;


       // 3. Extract Z-depth (2 bits)
       // We take the top 2 bits of Z to decide brightness.
       // If Z is unsigned 0-1023, bits [9:8] represent the "highest" values.
       adjusted_coords[(i*22) + 1 : (i*22) + 0] = z_raw[9:8];
   end
 end
endmodule
