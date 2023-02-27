///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Agent component of reset agent
///////////////////////////////////////////////////////////////////////////////


class reset_agent extends uvm_agent;
    // Ports
    uvm_analysis_port #(reset_txn) ap;  // Pass-through port from monitor

    // Components
    reset_sequencer sqr;
    reset_driver    drv;
    reset_monitor   mon;
    reset_cov       cov;

    `uvm_component_utils(reset_agent);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap = new("ap", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Construct components using factory
        sqr = reset_sequencer::type_id::create("sqr", this);
        drv = reset_driver::type_id::create("drv", this);
        mon = reset_monitor::type_id::create("mon", this);
        cov = reset_cov::type_id::create("cov", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Make connections
        drv.seq_item_port.connect(sqr.seq_item_export);  // Sequencer to driver
        mon.ap.connect(cov.reset_export);                // Observed resets to coverage
        mon.ap.connect(this.ap);                         // Pass-through from monitor
    endfunction : connect_phase
endclass : reset_agent

