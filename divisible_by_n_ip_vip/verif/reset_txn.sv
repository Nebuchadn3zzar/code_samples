///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Sequence item classes for reset agent
///////////////////////////////////////////////////////////////////////////////


class reset_txn extends uvm_sequence_item;
    // Fields
    rand int unsigned reset_duration;  // Duration of reset, in clock cycles

    `uvm_object_utils_begin(reset_txn);  // Utility operations such as copy, compare, pack, etc.
        `uvm_field_int(reset_duration, UVM_DEFAULT);  // Include in all utility operations
    `uvm_object_utils_end;

    // Constraints
    constraint reset_duration_c {
        reset_duration inside {[2:5]};
    }

    function new(string name="reset_txn");
        super.new(name);
    endfunction : new
endclass : reset_txn

