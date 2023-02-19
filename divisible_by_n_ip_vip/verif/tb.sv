///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Top module of streaming divisibility checker UVM testbench
///////////////////////////////////////////////////////////////////////////////


module tb();
    `include "wave_dump.sv"

    // Interface instances
    div_if tb_div_if();

    // Clocks
    reg clk;
    initial begin
        clk <= 1'b0;  // Initial state
        forever #5ns clk = ~clk;  // 100 MHz
    end
    assign tb_div_if.clk = clk;

    // DUT
    top dut_top (
        .clk   (clk),
        .rst_n (tb_div_if.rst_n),

        .in      (tb_div_if.bitstream),
        .in_vld  (tb_div_if.bitstream_vld),
        .out     (tb_div_if.divisible),
        .out_vld (tb_div_if.result_vld)
    );

    // Run test
    initial begin
        // Store handles to physical interfaces into resource database as virtual interface handles
        uvm_config_db#(virtual div_if)::set(null, "uvm_test_top.env.*", "div_vif", tb_div_if);

        run_test();
    end
endmodule : tb

