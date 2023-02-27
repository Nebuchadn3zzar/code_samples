///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Coverage model definitions for both stimulus and output of streaming
//      divisibility checker module
//    * Coverage collection component
///////////////////////////////////////////////////////////////////////////////


// Stimulus into module
covergroup div_stim_cov_group with function sample(div_packet p);
    coverpoint p.num_bits {  // Length of bitstream
        bins a[8] = {[1:`MAX_STREAM_LEN]};
    }
    coverpoint p.data {  // Value of bitstream
        bins a[4] = {[0:$]};
    }
endgroup

// Output of module
covergroup div_result_cov_group with function sample(div_packet p);
    coverpoint p.divisible {  // Divisibility result from DUT
        option.at_least = 1;
    }
endgroup

// Coverage collection component
class div_cov extends uvm_component;
    // Ports
    `uvm_analysis_imp_decl(_stim)    // Define analysis imp class for 'stim' imp
    `uvm_analysis_imp_decl(_result)  // Define analysis imp class for 'result' imp
    uvm_analysis_imp_stim   #(div_packet, div_cov) stim_export;
    uvm_analysis_imp_result #(div_packet, div_cov) result_export;

    div_stim_cov_group   cov_stim;
    div_result_cov_group cov_result;

    `uvm_component_utils(div_cov);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
        stim_export   = new("stim_export", this);
        result_export = new("result_export", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cov_stim   = new();
        cov_result = new();
    endfunction : build_phase

    // Collects coverage on stimulus
    virtual function void write_stim(div_packet stim);
        cov_stim.sample(stim);
    endfunction : write_stim

    // Collects coverage on divisibility result
    virtual function void write_result(div_packet result);
        cov_result.sample(result);
    endfunction : write_result
endclass

