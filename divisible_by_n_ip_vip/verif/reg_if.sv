///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Interface between register bus and testbench
///////////////////////////////////////////////////////////////////////////////


interface reg_if();
    logic clk;  // Not connected to DUT; solely for register bus driver

    // Register bus
    logic                    reg_rd_en;
    logic                    reg_wr_en;
    logic [`REG_ADDR_SZ-1:0] reg_addr;
    logic [`REG_DATA_SZ-1:0] reg_wr_data;
    logic [`REG_DATA_SZ-1:0] reg_rd_data;
endinterface : reg_if

