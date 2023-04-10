///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Source file include list for Verilog design of computer vision edge
//      detector
///////////////////////////////////////////////////////////////////////////////


// Sub-module definitions
`include "frame_buf.v"
`include "step_seqr.v"
`include "intensity_grd.v"
`include "edge_thin.v"
`include "edge_trk.v"
`include "rectify_clip.v"

// Top RTL module that instantiates above sub-modules
`include "top.v"

// Testbench
`include "tb.v"

