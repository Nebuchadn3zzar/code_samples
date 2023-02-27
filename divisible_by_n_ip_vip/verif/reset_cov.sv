///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Coverage model definitions for resets of streaming divisibility checker
//      module
//    * Coverage collection component
///////////////////////////////////////////////////////////////////////////////


// Reset duration
covergroup reset_cov_group with function sample(reset_txn tr);
    coverpoint tr.reset_duration {  // Length of reset, in clock cycles
        bins a[4] = {[1:$]};
    }
endgroup

// Coverage collection component
class reset_cov extends uvm_component;
    // Ports
    `uvm_analysis_imp_decl(_reset)  // Define analysis imp class for 'reset' imp
    uvm_analysis_imp_reset #(reset_txn, reset_cov) reset_export;

    reset_cov_group cov_reset;

    `uvm_component_utils(reset_cov);  // Register component with factory

    function new (string name, uvm_component parent);
        super.new(name, parent);

        reset_export = new("reset_export", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cov_reset = new();
    endfunction : build_phase

    // Collects coverage on reset duration
    virtual function void write_reset(reset_txn tr);
        cov_reset.sample(tr);
    endfunction : write_reset
endclass

