///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Monitor component of reset agent
///////////////////////////////////////////////////////////////////////////////


class reset_monitor extends uvm_monitor;
    // Ports
    uvm_analysis_port #(reset_txn) ap;

    virtual div_if div_vif;  // Virtual interface with DUT

    `uvm_component_utils(reset_monitor);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap = new("ap", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual div_if)::get(this, "", "div_vif", div_vif)) begin
            `uvm_fatal("DRVCFG", "No virtual interface object passed!");
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        fork
            forever sample_reset();
        join_none
    endtask : run_phase

    // Samples reset applications to DUT
    virtual task sample_reset();
        int unsigned reset_duration = 0;
        reset_txn rst_txn = reset_txn::type_id::create("rst_txn", this);

        while (1) begin  // Loop indefinitely
            @(posedge div_vif.clk);
            if (!div_vif.rst_n) begin  // DUT is being reset
                ++reset_duration;  // Increment observed duration of reset application
            end
            else begin  // DUT is no longer being reset
                break;
            end
        end

        if (reset_duration > 0) begin
            rst_txn.reset_duration = reset_duration;
            `uvm_info("MON",
                      $sformatf("Observed reset of duration %0d clocks", rst_txn.reset_duration),
                      UVM_MEDIUM);
            ap.write(rst_txn);
        end
    endtask : sample_reset
endclass : reset_monitor

