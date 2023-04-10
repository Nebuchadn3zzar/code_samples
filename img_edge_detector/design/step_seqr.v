///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Sequences all steps comprising edge detection operator, starting each
//      step in proper order and at proper timing
///////////////////////////////////////////////////////////////////////////////


// Step sequencer module
module step_seqr (
    input clk,
    input rst_n,

    // Control signals
    input  run,
    output intns_grd_run,
    input  intns_grd_done,
    output edge_thin_run,
    input  edge_thin_done,
    output edge_trk_run,
    input  edge_trk_done,
    output rectify_clip_run,
    input  rectify_clip_done,
    output done
);
    // Local constants
    localparam NUM_STATES         = 6;
    localparam NUM_STATE_BITS     = $clog2(NUM_STATES);
    localparam STATE_IDLE         = NUM_STATE_BITS'(0);
    localparam STATE_INTNS_GRD    = NUM_STATE_BITS'(1);
    localparam STATE_EDGE_THIN    = NUM_STATE_BITS'(2);
    localparam STATE_EDGE_TRK     = NUM_STATE_BITS'(3);
    localparam STATE_RECTIFY_CLIP = NUM_STATE_BITS'(4);
    localparam STATE_DONE         = NUM_STATE_BITS'(5);

    // Wire and reg declarations
    reg [NUM_STATE_BITS-1:0] state;

    // Sequential logic
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            state <= STATE_IDLE;  // Initialise to idle state
        end
        else if ((state == STATE_IDLE) & run) begin
            state <= STATE_INTNS_GRD;  // Advance to intensity gradient step
        end
        else if (intns_grd_run & intns_grd_done) begin
            state <= STATE_EDGE_THIN;  // Advance to edge thinning step
        end
        else if (edge_thin_run & edge_thin_done) begin
            state <= STATE_EDGE_TRK;  // Advance to edge tracking step
        end
        else if (edge_trk_run & edge_trk_done) begin
            state <= STATE_RECTIFY_CLIP;  // Advance to rectification and clipping step
        end
        else if (rectify_clip_run & rectify_clip_done) begin
            state <= STATE_DONE;  // Advance to done state
        end
    end

    // Output wire assignments
    assign intns_grd_run    = (state == STATE_INTNS_GRD);
    assign edge_thin_run    = (state == STATE_EDGE_THIN);
    assign edge_trk_run     = (state == STATE_EDGE_TRK);
    assign rectify_clip_run = (state == STATE_RECTIFY_CLIP);
    assign done             = (state == STATE_DONE);
endmodule : step_seqr

