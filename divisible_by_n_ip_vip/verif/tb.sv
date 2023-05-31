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
    reg_if tb_reg_if();

    // Clocks
    reg clk;
    initial begin
        clk <= 1'b0;  // Initial state
        forever #5ns clk = ~clk;  // 100 MHz
    end
    assign tb_div_if.clk = clk;
    assign tb_reg_if.clk = clk;  // Not connected to DUT; solely for register bus driver

    // DUT
    top dut_top (
        .clk   (clk),
        .rst_n (tb_div_if.rst_n),

        .in      (tb_div_if.bitstream),
        .in_vld  (tb_div_if.bitstream_vld),
        .out     (tb_div_if.divisible),
        .out_vld (tb_div_if.result_vld),

        .reg_rd_en   (tb_reg_if.reg_rd_en),
        .reg_wr_en   (tb_reg_if.reg_wr_en),
        .reg_addr    (tb_reg_if.reg_addr),
        .reg_wr_data (tb_reg_if.reg_wr_data),
        .reg_rd_data (tb_reg_if.reg_rd_data)
    );

    // Run test
    initial begin
        // Store handles to physical interfaces into resource database as virtual interface handles
        uvm_resource_db#(virtual div_if)::set("uvm_test_top.env", "div_vif", tb_div_if);
        uvm_resource_db#(virtual reg_if)::set("uvm_test_top.env", "reg_vif", tb_reg_if);

        run_test();
    end
endmodule : tb

