///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Applies edge thinning using non-maximum suppression to each pixel of an
//      image, to remove pixels not considered to be part of an edge
//    * Source frame buffer and destination frame buffer must be distinct
//      instances
///////////////////////////////////////////////////////////////////////////////


// Edge thinning kernel
module edge_thin #(
    parameter IMG_WD     = 0,  // Width of image, in pixels
    parameter IMG_HT     = 0,  // Height of image, in pixels
    parameter COORD_BITS = 0,  // Bits required to address all pixels in image
    parameter WIN_WD     = 0,  // Width of non-maximum suppression kernel
    parameter WIN_HT     = 0,  // Height of non-maximum suppression kernel
    parameter PXL_BITS   = 0   // Bits required to represent largest signed intermediate value
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
    reg                         strongest_x_pos;  // Whether pixel is strongest positive in X axis
    reg                         strongest_x_neg;  // Whether pixel is strongest negative in X axis
    reg                         strongest_y_pos;  // Whether pixel is strongest positive in Y axis
    reg                         strongest_y_neg;  // Whether pixel is strongest negative in Y axis
    reg                         preserve_pxl;  // Whether pixel ultimately is to be preserved
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

        // Determine edge strength in X axis
        strongest_x_pos = (rd_data[1][1] >= rd_data[1][0]) &
                          (rd_data[1][1] >= rd_data[1][2]);
        strongest_x_neg = (rd_data[1][1] <= rd_data[1][0]) &
                          (rd_data[1][1] <= rd_data[1][2]);

        // Determine edge strength in Y axis
        strongest_y_pos = (rd_data[1][1] >= rd_data[0][1]) &
                          (rd_data[1][1] >= rd_data[2][1]);
        strongest_y_neg = (rd_data[1][1] <= rd_data[0][1]) &
                          (rd_data[1][1] <= rd_data[2][1]);

        // Preserve pixel only if edge strength largest compared to adjacent pixels
        preserve_pxl = strongest_x_pos | strongest_x_neg |
                       strongest_y_pos | strongest_y_neg;
        result = {PXL_BITS{preserve_pxl}} & rd_data[WIN_CTR_Y][WIN_CTR_X];
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
endmodule : edge_thin

