///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Interface signals between register bus and testbench
//    * Assertions that enforce expected properties of interface signals
///////////////////////////////////////////////////////////////////////////////


interface reg_if();
    logic clk;  // Not connected to DUT; solely for register bus driver

    // Register bus
    logic                    reg_rd_en;
    logic                    reg_wr_en;
    logic [`REG_ADDR_SZ-1:0] reg_addr;
    logic [`REG_DATA_SZ-1:0] reg_wr_data;
    logic [`REG_DATA_SZ-1:0] reg_rd_data;

    // Assertions
    concurrent_rd_wr:
        assert property (@(posedge clk) !(reg_rd_en && reg_wr_en))
        else `uvm_error("REG_IF",
                        $sformatf("Register bus concurrent read and write of address 0x%0h!",
                                  reg_addr));
endinterface : reg_if

