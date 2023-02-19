///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Sequencer component of streaming divisibility checker agent
///////////////////////////////////////////////////////////////////////////////


class div_sequencer extends uvm_sequencer #(div_packet);
    `uvm_component_utils(div_sequencer);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
endclass : div_sequencer

