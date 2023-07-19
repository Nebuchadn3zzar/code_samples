///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Driver component of register bus interface agent
///////////////////////////////////////////////////////////////////////////////


class reg_driver extends uvm_driver #(reg_rw_item);
    virtual reg_if reg_vif;  // Virtual interface with DUT

    `uvm_component_utils(reg_driver);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_resource_db#(virtual reg_if)::read_by_name(
            get_full_name(), "reg_vif", reg_vif, this
        )) begin
            `uvm_fatal("CFG_DRV", "No register bus virtual interface object passed!");
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            seq_item_port.get_next_item(req);  // Blocking 'get'
            send_item(req);  // Drive transaction into DUT
            seq_item_port.item_done();  // Indicate to sequence that driver has completed processing
        end
    endtask : run_phase

    virtual task send_item(reg_rw_item tr);
        @(posedge reg_vif.clk);
        reg_vif.reg_rd_en <= (tr.kind == UVM_READ);
        reg_vif.reg_wr_en <= (tr.kind == UVM_WRITE);
        reg_vif.reg_addr  <= tr.addr;
        if (tr.kind == UVM_WRITE) begin
            reg_vif.reg_wr_data <= tr.data;  // Drive write data
            @(posedge reg_vif.clk);
        end
        else if (tr.kind == UVM_READ) begin
            @(posedge reg_vif.clk);
            tr.data = reg_vif.reg_rd_data;  // Sample read data
        end
        reg_vif.reg_rd_en <= 0;  // De-assert read enable
        reg_vif.reg_wr_en <= 0;  // De-assert write enable
        `uvm_info("DRV",
                  $sformatf("Drove %s register transaction with address 0x%0h, data 0x%0h",
                            tr.kind.name, tr.addr, tr.data),
                  UVM_MEDIUM);
    endtask : send_item
endclass : reg_driver

