///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Interface signals between divisibility checker module and testbench
//    * Assertions that enforce expected properties and timing of interface
//      signals
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

    // Assertions
    result_vld_despite_rst:
        assert property (@(posedge clk) !rst_n |-> ##[1:2] !result_vld)
        else `uvm_error("IF", "Result remained valid for more than 1 clock following reset!");
    result_vld_delay:
        assert property (@(posedge clk) bitstream_vld |-> ##1 result_vld)
        else `uvm_error("IF", "Result not valid exactly 1 clock following bitstream valid!");
    result_invld_delay:
        assert property (@(posedge clk) !bitstream_vld |-> ##1 !result_vld)
        else `uvm_error("IF", "Result not invalid exactly 1 clock following bitstream invalid!");
endinterface : div_if

