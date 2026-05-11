module register (
	input wire clk,
	input wire rst,
	input wire we,
	input wire [7:0] in,
	output wire [7:0] out
);

	reg [7:0] data;
	always @(posedge clk) begin
		if (rst) begin
			data <= 8'd3; // MUST CHANGE LATER!!! BACK TO 8'd0
		end else if (we) begin
			data <= in;
		end else begin
            data <= data;
        end
    end 

	assign out = data;

endmodule