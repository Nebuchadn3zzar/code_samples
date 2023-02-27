///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Sequencer component of reset agent
///////////////////////////////////////////////////////////////////////////////


class reset_sequencer extends uvm_sequencer #(reset_txn);
    `uvm_component_utils(reset_sequencer);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
endclass : reset_sequencer

