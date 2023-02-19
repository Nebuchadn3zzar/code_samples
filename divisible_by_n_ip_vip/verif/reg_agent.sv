///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Agent component of register bus interface
///////////////////////////////////////////////////////////////////////////////


class reg_agent extends uvm_agent;
    // Components
    reg_sequencer sqr;
    reg_driver    drv;

    // Adapter between UVM-abstracted register transactions and bus transactions
    reg_bus_adapter adapter;

    `uvm_component_utils(reg_agent);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Construct components using factory
        sqr = reg_sequencer::type_id::create("sqr", this);
        drv = reg_driver::type_id::create("drv", this);

        // Create adapter between UVM-abstracted register transactions and bus transactions
        adapter = reg_bus_adapter::type_id::create("adapter", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Make connections
        drv.seq_item_port.connect(sqr.seq_item_export);  // Sequencer to driver
    endfunction : connect_phase
endclass : reg_agent

