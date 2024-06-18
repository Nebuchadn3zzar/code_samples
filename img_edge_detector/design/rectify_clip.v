///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Rectifies negative pixel values and clips at maximum value, to produce
//      final output edge pixel map
//    * Source frame buffer and destination frame buffer must be distinct
//      instances
///////////////////////////////////////////////////////////////////////////////


// Rectification and clipping kernel
module rectify_clip #(
    parameter IMG_WD     = 0,  // Width of image, in pixels
    parameter IMG_HT     = 0,  // Height of image, in pixels
    parameter COORD_BITS = 0,  // Bits required to address all pixels in image
    parameter WIN_WD     = 0,  // Width of frame buffer read window
    parameter WIN_HT     = 0,  // Height of frame buffer read window
    parameter PXL_BITS   = 0,  // Bits required to represent largest signed intermediate value
    parameter MAX_VAL    = 0   // Maximum grey value in input and output images
) (
    input clk,
    input rst_n,

    // Control signals
    input  run,
    output done,

    // Source frame buffer interface
    output                              rd_en,
    output [COORD_BITS-1:0]             rd_x,
    output [COORD_BITS-1:0]             rd_y,
    input  [WIN_HT*WIN_WD*PXL_BITS-1:0] rd_data_flat,  // Read window, flattened

    // Destination frame buffer interface
    output                         wr_en,
    output        [COORD_BITS-1:0] wr_x,
    output        [COORD_BITS-1:0] wr_y,
    output signed [PXL_BITS-1:0]   wr_data_pxl
);
    // Local constants
    localparam WIN_CTR_X = WIN_WD / 2;  // Distance from center pixel to left/right edge of window
    localparam WIN_CTR_Y = WIN_HT / 2;  // Distance from center pixel to top/bottom edge of window

    // Wire and reg declarations
    reg signed [PXL_BITS-1:0]   rd_data[0:WIN_HT-1][0:WIN_WD-1];  // Read window, unflattened
    reg        [COORD_BITS-1:0] cur_x;
    reg        [COORD_BITS-1:0] cur_y;
    reg signed [PXL_BITS-1:0]   rd_pxl;  // Value of center pixel in read window, for convenience
    reg                         neg;     // Whether center pixel has a negative value
    reg signed [PXL_BITS-1:0]   abs;     // Absolute value of center pixel
    reg signed [PXL_BITS-1:0]   result;

    // Sequential logic
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            cur_x <= COORD_BITS'(0);  // Begin at or return to left-most X position
            cur_y <= COORD_BITS'(0);  // Begin at or return to top-most Y position
        end
        else if (run & ~done & (cur_x == IMG_WD - 1)) begin  // End of row reached
            cur_x <= COORD_BITS'(0);  // Return to left-most X position
            cur_y <= cur_y + 1;  // Advance to next row
        end
        else if (run & ~done) begin  // Not yet at end of row nor image
            cur_x <= cur_x + 1;  // Advance to next column in row
        end
    end

    // Combinational logic
    always @(*) begin
        // Map from flattened frame buffer read port to unflattened internal 2D array
        for (int y = 0; y < WIN_HT; ++y) begin
            for (int x = 0; x < WIN_WD; ++x) begin
`ifdef NO_SV_AUTO_VAR  // Compiler does not support SystemVerilog automatic variables
                rd_data[y][x] = rd_data_flat[((y * (PXL_BITS * WIN_WD)) + (x * PXL_BITS)) +: PXL_BITS];
`else  // NO_SV_AUTO_VAR not defined
                automatic int y_ofst = y * (PXL_BITS * WIN_WD);
                automatic int x_ofst = x * PXL_BITS;

                rd_data[y][x] = rd_data_flat[(y_ofst + x_ofst) +: PXL_BITS];
`endif  // NO_SV_AUTO_VAR
            end
        end

        // Extract center pixel out of read window for convenience, discarding all other pixels
        rd_pxl = rd_data[WIN_CTR_Y][WIN_CTR_X];

        // If center pixel is negative, rectify
        neg = rd_pxl[PXL_BITS-1];  // Sign bit
        abs = neg ? (~rd_pxl + 1) : rd_pxl;  // Two's complement negation

        // Clip at maximum grey value
        result = (abs > MAX_VAL) ? MAX_VAL : abs;
    end

    // Output wire assignments
    assign done = (cur_x == IMG_WD - 1) & (cur_y == IMG_HT - 1);
    assign rd_en = run;
    assign rd_x = cur_x;
    assign rd_y = cur_y;
    assign wr_en = run;
    assign wr_x = cur_x;
    assign wr_y = cur_y;
    assign wr_data_pxl = result;
endmodule : rectify_clip

