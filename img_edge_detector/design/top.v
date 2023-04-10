///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Top RTL module that instantiates the following modules:
//       * frame_buf:     Frame buffers containing greyscale bitmaps of input
//                        image, intermediate results, and final output image
//                        with detected edges marked
//       * step_seqr:     Sequences all steps comprising edge detection
//                        operator, starting each step in proper order and at
//                        proper timing
//       * intensity_grd: Computes intensity gradient of image by convolving
//                        Laplacian second derivative approximation kernel
//                        across each pixel of input image
//       * edge_thin:     Applies edge thinning using non-maximum suppression,
//                        to remove pixels not considered to be part of an edge
//       * edge_trk:      Applies edge tracking using double-threshold
//                        hysteresis, to filter out spurious edges caused by
//                        noise and color variation
//       * rectify_clip:  Rectifies negative pixel values and clips at maximum
//                        value, to produce final output edge pixel map
//
// Notes:
//    * Wires carrying intermediate results flattened because Verilog does not
//      support ports being arrays
///////////////////////////////////////////////////////////////////////////////


// Constants
`define IMG_WD 5                    // Width of image, in pixels
`define IMG_HT 5                    // Height of image, in pixels
`define COORD_BITS $clog2(`IMG_WD)  // Bits required to address all pixels (assumes width >= height)
`define WIN_WD 3                    // Width of kernels to be convolved across each pixel of image
`define WIN_HT 3                    // Height of kernels to be convolved across each pixel of image
`define MAX_VAL 255                 // Maximum grey value in input and output images
`define PXL_BITS ($clog2(`MAX_VAL*`WIN_WD*`WIN_HT) + 1)  // Bits required for largest signed value

// Root RTL module
module top(
    input  clk,
    input  rst_n,

    // Control signals
    input  run,
    output done,

    // Interface of frame buffer containing greyscale bitmap of input image
    input                   frame_buf_in_wr_en,
    input [`COORD_BITS-1:0] frame_buf_in_wr_x,
    input [`COORD_BITS-1:0] frame_buf_in_wr_y,
    input [`PXL_BITS-1:0]   frame_buf_in_wr_data_pxl,

    // Interface of frame buffer containing greyscale bitmap of final output image with detected
    // edges marked
    input                    frame_buf_out_rd_en,
    input  [`COORD_BITS-1:0] frame_buf_out_rd_x,
    input  [`COORD_BITS-1:0] frame_buf_out_rd_y,
    output [`PXL_BITS-1:0]   frame_buf_out_rd_data_pxl
);
    // Wire and reg declarations
    wire                                 intns_grd_run;
    wire                                 intns_grd_done;
    wire                                 intns_grd_rd_en;
    wire [`COORD_BITS-1:0]               intns_grd_rd_x;
    wire [`COORD_BITS-1:0]               intns_grd_rd_y;
    wire [`WIN_HT*`WIN_WD*`PXL_BITS-1:0] intns_grd_rd_data_flat;
    wire                                 intns_grd_wr_en;
    wire [`COORD_BITS-1:0]               intns_grd_wr_x;
    wire [`COORD_BITS-1:0]               intns_grd_wr_y;
    wire [`PXL_BITS-1:0]                 intns_grd_wr_data_pxl;
    wire                                 edge_thin_run;
    wire                                 edge_thin_done;
    wire                                 edge_thin_rd_en;
    wire [`COORD_BITS-1:0]               edge_thin_rd_x;
    wire [`COORD_BITS-1:0]               edge_thin_rd_y;
    wire [`WIN_HT*`WIN_WD*`PXL_BITS-1:0] edge_thin_rd_data_flat;
    wire                                 edge_thin_wr_en;
    wire [`COORD_BITS-1:0]               edge_thin_wr_x;
    wire [`COORD_BITS-1:0]               edge_thin_wr_y;
    wire [`PXL_BITS-1:0]                 edge_thin_wr_data_pxl;
    wire                                 edge_trk_run;
    wire                                 edge_trk_done;
    wire                                 edge_trk_rd_en;
    wire [`COORD_BITS-1:0]               edge_trk_rd_x;
    wire [`COORD_BITS-1:0]               edge_trk_rd_y;
    wire [`WIN_HT*`WIN_WD*`PXL_BITS-1:0] edge_trk_rd_data_flat;
    wire                                 edge_trk_wr_en;
    wire [`COORD_BITS-1:0]               edge_trk_wr_x;
    wire [`COORD_BITS-1:0]               edge_trk_wr_y;
    wire [`PXL_BITS-1:0]                 edge_trk_wr_data_pxl;
    wire                                 rectify_clip_run;
    wire                                 rectify_clip_done;
    wire                                 rectify_clip_rd_en;
    wire [`COORD_BITS-1:0]               rectify_clip_rd_x;
    wire [`COORD_BITS-1:0]               rectify_clip_rd_y;
    wire [`WIN_HT*`WIN_WD*`PXL_BITS-1:0] rectify_clip_rd_data_flat;
    wire                                 rectify_clip_wr_en;
    wire [`COORD_BITS-1:0]               rectify_clip_wr_x;
    wire [`COORD_BITS-1:0]               rectify_clip_wr_y;
    wire [`PXL_BITS-1:0]                 rectify_clip_wr_data_pxl;
    wire [`WIN_HT*`WIN_WD*`PXL_BITS-1:0] frame_buf_out_rd_data_flat;

    // Step sequencer
    step_seqr step_seqr (
        .clk               (clk),
        .rst_n             (rst_n),
        .run               (run),
        .intns_grd_run     (intns_grd_run),
        .intns_grd_done    (intns_grd_done),
        .edge_thin_run     (edge_thin_run),
        .edge_thin_done    (edge_thin_done),
        .edge_trk_run      (edge_trk_run),
        .edge_trk_done     (edge_trk_done),
        .rectify_clip_run  (rectify_clip_run),
        .rectify_clip_done (rectify_clip_done),
        .done              (done)
    );

    // Frame buffer containing input image
    frame_buf #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS)
    ) frame_buf_in (
        .clk          (clk),
        .rst_n        (rst_n),
        .rd_en        (intns_grd_rd_en),
        .rd_x         (intns_grd_rd_x),
        .rd_y         (intns_grd_rd_y),
        .rd_data_flat (intns_grd_rd_data_flat),
        .wr_en        (frame_buf_in_wr_en),
        .wr_x         (frame_buf_in_wr_x),
        .wr_y         (frame_buf_in_wr_y),
        .wr_data_pxl  (frame_buf_in_wr_data_pxl)
    );

    // Intensity gradient kernel
    intensity_grd #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS)
    ) intensity_grd (
        .clk          (clk),
        .rst_n        (rst_n),
        .run          (intns_grd_run),
        .done         (intns_grd_done),
        .rd_en        (intns_grd_rd_en),
        .rd_x         (intns_grd_rd_x),
        .rd_y         (intns_grd_rd_y),
        .rd_data_flat (intns_grd_rd_data_flat),
        .wr_en        (intns_grd_wr_en),
        .wr_x         (intns_grd_wr_x),
        .wr_y         (intns_grd_wr_y),
        .wr_data_pxl  (intns_grd_wr_data_pxl)
    );

    // Frame buffer containing result of intensity gradient step
    frame_buf #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS)
    ) frame_buf_intns_grd (
        .clk          (clk),
        .rst_n        (rst_n),
        .rd_en        (edge_thin_rd_en),
        .rd_x         (edge_thin_rd_x),
        .rd_y         (edge_thin_rd_y),
        .rd_data_flat (edge_thin_rd_data_flat),
        .wr_en        (intns_grd_wr_en),
        .wr_x         (intns_grd_wr_x),
        .wr_y         (intns_grd_wr_y),
        .wr_data_pxl  (intns_grd_wr_data_pxl)
    );

    // Edge thinning kernel
    edge_thin #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS)
    ) edge_thin (
        .clk          (clk),
        .rst_n        (rst_n),
        .run          (edge_thin_run),
        .done         (edge_thin_done),
        .rd_en        (edge_thin_rd_en),
        .rd_x         (edge_thin_rd_x),
        .rd_y         (edge_thin_rd_y),
        .rd_data_flat (edge_thin_rd_data_flat),
        .wr_en        (edge_thin_wr_en),
        .wr_x         (edge_thin_wr_x),
        .wr_y         (edge_thin_wr_y),
        .wr_data_pxl  (edge_thin_wr_data_pxl)
    );

    // Frame buffer containing result of edge thinning step
    frame_buf #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS)
    ) frame_buf_edge_thin (
        .clk          (clk),
        .rst_n        (rst_n),
        .rd_en        (edge_trk_rd_en),
        .rd_x         (edge_trk_rd_x),
        .rd_y         (edge_trk_rd_y),
        .rd_data_flat (edge_trk_rd_data_flat),
        .wr_en        (edge_thin_wr_en),
        .wr_x         (edge_thin_wr_x),
        .wr_y         (edge_thin_wr_y),
        .wr_data_pxl  (edge_thin_wr_data_pxl)
    );

    // Edge tracking kernel
    edge_trk #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS)
    ) edge_trk (
        .clk          (clk),
        .rst_n        (rst_n),
        .run          (edge_trk_run),
        .done         (edge_trk_done),
        .rd_en        (edge_trk_rd_en),
        .rd_x         (edge_trk_rd_x),
        .rd_y         (edge_trk_rd_y),
        .rd_data_flat (edge_trk_rd_data_flat),
        .wr_en        (edge_trk_wr_en),
        .wr_x         (edge_trk_wr_x),
        .wr_y         (edge_trk_wr_y),
        .wr_data_pxl  (edge_trk_wr_data_pxl)
    );

    // Frame buffer containing result of edge tracking step
    frame_buf #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS)
    ) frame_buf_edge_trk (
        .clk          (clk),
        .rst_n        (rst_n),
        .rd_en        (rectify_clip_rd_en),
        .rd_x         (rectify_clip_rd_x),
        .rd_y         (rectify_clip_rd_y),
        .rd_data_flat (rectify_clip_rd_data_flat),
        .wr_en        (edge_trk_wr_en),
        .wr_x         (edge_trk_wr_x),
        .wr_y         (edge_trk_wr_y),
        .wr_data_pxl  (edge_trk_wr_data_pxl)
    );

    // Recifier and clipper
    rectify_clip #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS),
        .MAX_VAL    (`MAX_VAL)
    ) rectify_clip (
        .clk          (clk),
        .rst_n        (rst_n),
        .run          (rectify_clip_run),
        .done         (rectify_clip_done),
        .rd_en        (rectify_clip_rd_en),
        .rd_x         (rectify_clip_rd_x),
        .rd_y         (rectify_clip_rd_y),
        .rd_data_flat (rectify_clip_rd_data_flat),
        .wr_en        (rectify_clip_wr_en),
        .wr_x         (rectify_clip_wr_x),
        .wr_y         (rectify_clip_wr_y),
        .wr_data_pxl  (rectify_clip_wr_data_pxl)
    );

    // Frame buffer containing result of rectification and clipping step
    frame_buf #(
        .IMG_WD     (`IMG_WD),
        .IMG_HT     (`IMG_HT),
        .COORD_BITS (`COORD_BITS),
        .WIN_WD     (`WIN_WD),
        .WIN_HT     (`WIN_HT),
        .PXL_BITS   (`PXL_BITS)
    ) frame_buf_rectify_clip (
        .clk          (clk),
        .rst_n        (rst_n),
        .rd_en        (frame_buf_out_rd_en),
        .rd_x         (frame_buf_out_rd_x),
        .rd_y         (frame_buf_out_rd_y),
        .rd_data_flat (frame_buf_out_rd_data_flat),
        .wr_en        (rectify_clip_wr_en),
        .wr_x         (rectify_clip_wr_x),
        .wr_y         (rectify_clip_wr_y),
        .wr_data_pxl  (rectify_clip_wr_data_pxl)
    );

    // Output wire assignments
    localparam WIN_CTR_Y = `WIN_HT / 2;  // Distance from center pixel to top/bottom edge of window
    localparam WIN_CTR_X = `WIN_WD / 2;  // Distance from center pixel to left/right edge of window
    localparam WIN_CTR_Y_OFST = WIN_CTR_Y * (`PXL_BITS * `WIN_WD);  // Bit offset of center pixel
    localparam WIN_CTR_X_OFST = WIN_CTR_X * `PXL_BITS;              // Bit offset of center pixel
    assign frame_buf_out_rd_data_pxl =
        frame_buf_out_rd_data_flat[(WIN_CTR_Y_OFST + WIN_CTR_X_OFST) +: `PXL_BITS];
endmodule : top

