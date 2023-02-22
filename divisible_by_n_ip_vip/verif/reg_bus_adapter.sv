///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Adapter between UVM-abstracted register transactions and register bus
//      transactions
///////////////////////////////////////////////////////////////////////////////


class reg_bus_adapter extends uvm_reg_adapter;
    `uvm_object_utils(reg_bus_adapter);  // Register object with factory

    function new(string name="reg_bus_adapter");
        super.new(name);
    endfunction : new

    // Adapter from UVM-abstracted register transaction to bus transaction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        reg_rw_item tr = reg_rw_item::type_id::create("tr");  // Bus transaction
        tr.kind = rw.kind;
        tr.addr = rw.addr;
        tr.data = rw.data;
        `uvm_info("REG2BUS",
                  $sformatf("Converted to %s bus transaction with address 0x%0h, data 0x%0h",
                            tr.kind.name, tr.addr, tr.data),
                  UVM_HIGH);
        return tr;
    endfunction : reg2bus

    // Adapter from bus transaction to UVM-abstracted register transaction
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        reg_rw_item tr;
        if (!$cast(tr, bus_item)) begin
            `uvm_fatal("BUS2REG",
                       "Given 'bus_item' is of invalid type; failed to cast to 'reg_rw_item'!")
        end
        rw.kind = tr.kind;
        rw.addr = tr.addr;
        rw.data = tr.data;
        rw.status = UVM_IS_OK;
        `uvm_info("BUS2REG",
                  $sformatf("Converted to %s register transaction with address 0x%0h, data 0x%0h",
                            rw.kind.name, rw.addr, rw.data),
                  UVM_HIGH);
    endfunction : bus2reg
endclass : reg_bus_adapter

