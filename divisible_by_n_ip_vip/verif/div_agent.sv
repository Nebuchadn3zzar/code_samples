///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Agent component of streaming divisibility checker module
///////////////////////////////////////////////////////////////////////////////


class div_agent extends uvm_agent;
    // Ports
    uvm_analysis_port #(div_packet) stim_analysis_port;    // Pass-through port from monitor
    uvm_analysis_port #(div_packet) result_analysis_port;  // Pass-through port from monitor

    // Components
    div_sequencer sqr;
    div_driver    drv;
    div_monitor   mon;

    `uvm_component_utils(div_agent);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
        stim_analysis_port   = new("stim_analysis_port", this);
        result_analysis_port = new("result_analysis_port", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Construct components using factory
        sqr = div_sequencer::type_id::create("sqr", this);
        drv = div_driver::type_id::create("drv", this);
        mon = div_monitor::type_id::create("mon", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Make connections
        drv.seq_item_port.connect(sqr.seq_item_export);               // Sequencer to driver
        mon.stim_analysis_port.connect(this.stim_analysis_port);      // Pass-through from monitor
        mon.result_analysis_port.connect(this.result_analysis_port);  // Pass-through from monitor
    endfunction : connect_phase
endclass : div_agent
