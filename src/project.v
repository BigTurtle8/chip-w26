`default_nettype none

module tt_um_lorenz_attractor_vga (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // 1. VGA Signal Wires
    wire hsync, vsync, video_active;
    wire [9:0] pix_x, pix_y;

    // 2. Data Buses
    wire [29:0]  current_point;     // X, Y, Z from Calculator
    wire [299:0] stored_points;     // 10 points * 30 bits
    wire [219:0] adjusted_coords;   // 10 points * 22 bits (X:10, Y:10, Z_depth:2)
    wire valid_calc, storage_ready;

    // 3. Sub-Modules
    
    // Generates the Lorentz math
    calculator my_calc (
        .clk(clk), 
        .rst_n(rst_n),
        .ready(storage_ready),
        .valid(valid_calc),
        .out_xyz(current_point)
    );

    // Circular Buffer (Shift Register)
    point_storage my_storage (
        .clk(clk), 
        .rst_n(rst_n),
        .valid_in(valid_calc),
        .point_in(current_point),
        .ready_out(storage_ready),
        .full_bus_out(stored_points)
    );

    // Conversions: 3D -> 2D + Depth
    translator my_translator (
        .coords(stored_points),
        .adjusted_coords(adjusted_coords)
    );

    // VGA Timing Generator 
    hvsync_generator hvsync (
        .clk(clk), 
        .reset(~rst_n),
        .hsync(hsync), 
        .vsync(vsync),
        .display_on(video_active),
        .xpos(pix_x), 
        .ypos(pix_y)
    );

    // 4. Drawing Logic (The "Pixel Shader")
    reg [5:0] pixel_rgb;
    integer i;
    
    reg [9:0] pt_x, pt_y;
    reg [1:0] z_depth;

    always @(*) begin
        pixel_rgb = 6'b000000; // Default: Black
        
        if (video_active) begin
            for (i = 0; i < 10; i = i + 1) begin
                // Unpack adjusted coords for this specific point
                pt_x    = adjusted_coords[(i*22)+21 : (i*22)+12];
                pt_y    = adjusted_coords[(i*22)+11 : (i*22)+2];
                z_depth = adjusted_coords[(i*22)+1  : (i*22)+0];

                // Check if current scanning pixel is "on" this point (2x2 area)
                if (pix_x >= pt_x && pix_x <= pt_x + 1 &&
                    pix_y >= pt_y && pix_y <= pt_y + 1) begin
                    
                    // Use Z-depth to set brightness (grayscale)
                    pixel_rgb = {z_depth, z_depth, z_depth};
                end
            end
        end
    end

    // 5. Output Assignment (TinyVGA PMOD standard)
    assign uo_out = {
        hsync, 
        pixel_rgb[1], 
        pixel_rgb[3], 
        pixel_rgb[5],
        vsync, 
        pixel_rgb[0], 
        pixel_rgb[2], 
        pixel_rgb[4]
    };

    // 6. Tiny Tapeout Boilerplate to prevent warnings
    wire _unused = &{ui_in, uio_in, ena, 1'b0};
    assign uio_out = 8'h0;
    assign uio_oe  = 8'h0;

endmodule