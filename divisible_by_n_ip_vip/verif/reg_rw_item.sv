///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Sequence item class for register bus interface
///////////////////////////////////////////////////////////////////////////////


class reg_rw_item extends uvm_sequence_item;
    // Fields
    rand uvm_access_e             kind;
    rand logic [`REG_ADDR_SZ-1:0] addr;
    rand logic [`REG_DATA_SZ-1:0] data;
    uvm_status_e                  status;

    `uvm_object_utils_begin(reg_rw_item);  // Utility operations such as copy, compare, pack, etc.
        `uvm_field_enum(uvm_access_e, kind,   UVM_DEFAULT);  // Include in all utility operations
        `uvm_field_int (addr,                 UVM_DEFAULT);  // Include in all utility operations
        `uvm_field_int (data,                 UVM_DEFAULT);  // Include in all utility operations
        `uvm_field_enum(uvm_status_e, status, UVM_DEFAULT);  // Include in all utility operations
    `uvm_object_utils_end;

    function new(string name="reg_rw_item");
        super.new(name);
    endfunction : new
endclass : reg_rw_item

