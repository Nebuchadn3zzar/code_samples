///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Driver component of reset agent
///////////////////////////////////////////////////////////////////////////////


class reset_driver extends uvm_driver #(reset_txn);
    virtual div_if div_vif;  // Virtual interface with divisibility checker module of DUT
    virtual reg_if reg_vif;  // Virtual interface with register bus of DUT

    `uvm_component_utils(reset_driver);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_resource_db#(virtual div_if)::read_by_name(
            get_full_name(), "div_vif", div_vif, this
        )) begin
            `uvm_fatal("CFG_DRV", "No divisibility checker virtual interface object passed!");
        end
        if (!uvm_resource_db#(virtual reg_if)::read_by_name(
            get_full_name(), "reg_vif", reg_vif, this
        )) begin
            `uvm_fatal("CFG_DRV", "No register bus virtual interface object passed!");
        end
    endfunction : build_phase

    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);

        // Initialise DUT input signals to idle values
        div_vif.bitstream     <= 1'b0;
        div_vif.bitstream_vld <= 1'b0;
        reg_vif.reg_rd_en     <= 1'b0;
        reg_vif.reg_wr_en     <= 1'b0;
        reg_vif.reg_addr      <= `REG_ADDR_SZ'(0);
        reg_vif.reg_wr_data   <= `REG_DATA_SZ'(0);

        forever begin
            seq_item_port.get_next_item(req);  // Blocking 'get'
            send_item(req);  // Drive transaction into DUT
            seq_item_port.item_done();  // Indicate to sequence that driver has completed processing
        end
    endtask : reset_phase

    virtual task send_item(reset_txn txn);
        // Initially de-assert reset
        div_vif.rst_n <= 1'b1;
        @(posedge div_vif.clk);

        // Assert reset for specified duration
        `uvm_info("DRV",
                  $sformatf("Applying reset for %0d clocks...", txn.reset_duration),
                  UVM_MEDIUM);
        @(posedge div_vif.clk);
        div_vif.rst_n <= 1'b0;
        repeat (txn.reset_duration) @(posedge div_vif.clk);

        // De-assert reset
        div_vif.rst_n <= 1'b1;
        @(posedge div_vif.clk);
    endtask : send_item
endclass : reset_driver

