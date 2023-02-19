///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Sequencer component of register bus interface agent
///////////////////////////////////////////////////////////////////////////////


class reg_sequencer extends uvm_sequencer #(reg_rw_item);
    `uvm_component_utils(reg_sequencer);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
endclass : reg_sequencer

