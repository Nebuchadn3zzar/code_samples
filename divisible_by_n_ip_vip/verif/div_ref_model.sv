///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Reference model of streaming divisibility checker module
///////////////////////////////////////////////////////////////////////////////


class div_ref_model extends uvm_component;
    // Ports
    uvm_analysis_imp  #(div_packet, div_ref_model) analysis_export;
    uvm_analysis_port #(div_packet)                analysis_port;

    string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hex

    `uvm_component_utils(div_ref_model);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);

        analysis_export = new("analysis_export", this);
        analysis_port   = new("analysis_port", this);
    endfunction : new

    // Predicts an expected packet from an observed bitstream
    virtual function void write(div_packet stim);
        div_packet res_pkt = div_packet::type_id::create("res_pkt", this);
        res_pkt.data      = stim.data;
        res_pkt.divisible = ((stim.data % `DIV_BY) == 0);
        `uvm_info("REF_MDL",
                  $sformatf("Given stimulus packet with data %s, predicted result %b",
                            $sformatf(hex_fmt_str, res_pkt.data), res_pkt.divisible),
                  UVM_MEDIUM);
        analysis_port.write(res_pkt);
    endfunction : write
endclass : div_ref_model

