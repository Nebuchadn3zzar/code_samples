///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Simple frame buffer with 1 read port and 1 write port
//    * Reads a WxH window centered on pixel at given coordinates,
//      automatically duplicating edge pixels to handle edges and corners
//    * Writes a single pixel at given coordinates
///////////////////////////////////////////////////////////////////////////////


// Frame buffer module
module frame_buf #(
    parameter IMG_WD     = 0,  // Width of frame buffer, in pixels
    parameter IMG_HT     = 0,  // Height of frame buffer, in pixels
    parameter COORD_BITS = 0,  // Bits required to address all pixels in frame buffer
    parameter WIN_WD     = 0,  // Width of read window
    parameter WIN_HT     = 0,  // Height of read window
    parameter PXL_BITS   = 0   // Bits required to represent largest signed intermediate value
) (
    input clk,
    input rst_n,

    // Read port
    input                                   rd_en,
    input      [COORD_BITS-1:0]             rd_x,
    input      [COORD_BITS-1:0]             rd_y,
    output reg [WIN_HT*WIN_WD*PXL_BITS-1:0] rd_data_flat,  // Flattened window of pixels

    // Write port
    input                         wr_en,
    input        [COORD_BITS-1:0] wr_x,
    input        [COORD_BITS-1:0] wr_y,
    input signed [PXL_BITS-1:0]   wr_data_pxl  // Single pixel
);
    // Local constants
    localparam WIN_CTR_X = WIN_WD / 2;  // Distance from center pixel to left/right edge of window
    localparam WIN_CTR_Y = WIN_HT / 2;  // Distance from center pixel to top/bottom edge of window

    // Wire and reg declarations
    reg signed [PXL_BITS-1:0] img_buf[0:IMG_HT-1][0:IMG_WD-1];  // 2D frame buffer
    reg signed [PXL_BITS-1:0] rd_data[0:WIN_HT-1][0:WIN_WD-1];  // Read window, unflattened

    // Sequential logic
    always @(posedge clk) begin
        if (wr_en) begin  // Write single pixel
            img_buf[wr_y][wr_x] <= wr_data_pxl;
        end
    end

    // Combinational logic
    always @(*) begin
        // Map from unflattened 2D array to flattened read data port
        for (int y = 0; y < WIN_HT; ++y) begin
            for (int x = 0; x < WIN_WD; ++x) begin
                automatic int y_ofst = y * (PXL_BITS * WIN_WD);
                automatic int x_ofst = x * PXL_BITS;

                rd_data_flat[(y_ofst + x_ofst) +: PXL_BITS] = rd_data[y][x];
            end
        end
    end

    // Read logic, consisting of one 'generate' block per pixel in read window
    for (genvar win_y = -WIN_CTR_Y; win_y <= WIN_CTR_Y; ++win_y) begin  // Each row
        for (genvar win_x = -WIN_CTR_X; win_x <= WIN_CTR_X; ++win_x) begin  // Each column
            // Modified version of 'COORD_BITS' that handles addition of window size as well as
            // negative values
            localparam COORD_TGT_BITS = ($clog2(IMG_WD + WIN_CTR_X) + 1);

            // Wire and reg declarations
            wire signed [COORD_TGT_BITS-1:0] y_tgt;
            wire signed [COORD_TGT_BITS-1:0] x_tgt;
            wire signed [COORD_TGT_BITS-1:0] y_eff;
            wire signed [COORD_TGT_BITS-1:0] x_eff;

            // Calculate coordinates of pixel at or adjacent to requested read coordinates
            assign y_tgt = rd_y + win_y;  // Possibly out of bounds
            assign x_tgt = rd_x + win_x;  // Possibly out of bounds

            // If either target coordinate is out of bounds, adjust to nearest edge, effectively
            // duplicating edge pixels to handle edges and corners
            assign y_eff = (y_tgt < 0)            ? COORD_TGT_BITS'(0)  // Beyond top edge
                         : (y_tgt > (IMG_HT - 1)) ? IMG_HT - 1          // Beyond bottom edge
                         :                          y_tgt;              // Within bounds; use as is
            assign x_eff = (x_tgt < 0)            ? COORD_TGT_BITS'(0)  // Beyond left edge
                         : (x_tgt > (IMG_WD - 1)) ? IMG_WD - 1          // Beyond right edge
                         :                          x_tgt;              // Within bounds; use as is

            // Read pixel at final adjusted coordinates
            assign rd_data[win_y + WIN_CTR_Y][win_x + WIN_CTR_X] = rd_en ? img_buf[y_eff][x_eff]
                                                                         : PXL_BITS'(0);
        end
    end
endmodule : frame_buf

