///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Library of sequences executed by tests for validating streaming
//      divisibility checker
///////////////////////////////////////////////////////////////////////////////


// Base sequence for streaming divisibility checker module
class div_seq extends uvm_sequence #(div_packet);
    `uvm_object_utils(div_seq);  // Register object with factory

    function new(string name="div_seq");
        super.new(name);
        `ifdef UVM_POST_VERSION_1_1
        set_automatic_phase_objection(1);  // Requires UVM 1.2 or later
        `endif  // UVM_POST_VERSION_1_1
    endfunction : new

    `ifdef UVM_VERSION_1_1
    task pre_start();
        if ((get_parent_sequence() == null) && (starting_phase != null)) begin
            starting_phase.raise_objection(this);
        end
    endtask : pre_start
    task post_start();
        if ((get_parent_sequence() == null) && (starting_phase != null)) begin
            starting_phase.drop_objection(this);
        end
    endtask : post_start
    `endif  // UVM_VERSION_1_1

    virtual task body();
        `uvm_do(req);
    endtask : body
endclass : div_seq

