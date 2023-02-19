///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Interface between divisibility checker module and testbench
///////////////////////////////////////////////////////////////////////////////


interface div_if();
    logic clk;
    logic rst_n;

    // Inputs of divisibility checker module
    logic bitstream;
    logic bitstream_vld;

    // Outputs of divisibility checker module
    logic divisible;
    logic result_vld;
endinterface : div_if

