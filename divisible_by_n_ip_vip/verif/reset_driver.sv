///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Driver component of reset agent
///////////////////////////////////////////////////////////////////////////////


class reset_driver extends uvm_driver #(reset_txn);
    virtual div_if div_vif;  // Virtual interface with DUT

    `uvm_component_utils(reset_driver);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual div_if)::get(this, "", "div_vif", div_vif)) begin
            `uvm_fatal("DRVCFG", "No virtual interface object passed!");
        end
    endfunction : build_phase

    virtual task reset_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);  // Blocking 'get'
            send_item(req);  // Drive transaction into DUT
            seq_item_port.item_done();  // Indicate to sequence that driver has completed processing
        end
    endtask : reset_phase

    virtual task send_item(reset_txn txn);
        // Initially de-assert
        div_vif.rst_n <= 1'b1;
        @(posedge div_vif.clk);

        // Assert for specified duration
        `uvm_info("DRV",
                  $sformatf("Applying reset for %0d clocks...", txn.reset_duration),
                  UVM_MEDIUM);
        @(posedge div_vif.clk);
        div_vif.rst_n         <= 1'b0;
        div_vif.bitstream     <= 1'b0;
        div_vif.bitstream_vld <= 1'b0;
        repeat (txn.reset_duration) @(posedge div_vif.clk);

        // De-assert
        div_vif.rst_n <= 1'b1;
        @(posedge div_vif.clk);
    endtask : send_item
endclass : reset_driver

