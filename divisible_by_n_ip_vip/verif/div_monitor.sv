///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Monitor component of streaming divisibility checker agent
///////////////////////////////////////////////////////////////////////////////


class div_monitor extends uvm_monitor;
    // Ports
    uvm_analysis_port #(div_packet) stim_ap;
    uvm_analysis_port #(div_packet) result_ap;

    virtual div_if div_vif;  // Virtual interface with DUT

    string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hex

    `uvm_component_utils(div_monitor);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);

        stim_ap   = new("stim_ap", this);
        result_ap = new("result_ap", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if (!uvm_resource_db#(virtual div_if)::read_by_name(
            get_full_name(), "div_vif", div_vif, this
        )) begin
            `uvm_fatal("CFG_MON", "No divisibility checker virtual interface object passed!");
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        fork
            forever sample_stim();
            forever sample_result();
        join_none
    endtask : run_phase

    // Samples input bitstream into DUT
    virtual task sample_stim();
        div_packet stim_pkt = div_packet::type_id::create("stim_pkt", this);
        int unsigned                bitstream_len_so_far = 0;
        logic [`MAX_STREAM_LEN-1:0] bitstream_val_so_far = 'd0;

        while (1) begin  // Loop indefinitely until reset
            @(posedge div_vif.clk);
            if (!div_vif.rst_n) begin  // DUT is being reset
                break;
            end
            else if (div_vif.bitstream_vld) begin  // Input bitstream into DUT is valid
                bitstream_len_so_far++;
                bitstream_val_so_far = (bitstream_val_so_far << 1) | div_vif.bitstream;  // Update
                stim_pkt.num_bits = bitstream_len_so_far;
                stim_pkt.data     = bitstream_val_so_far;
                `uvm_info("MON",
                          $sformatf("Observed input bitstream of length %0d, value %s",
                                    stim_pkt.num_bits, $sformatf(hex_fmt_str, stim_pkt.data)),
                          UVM_MEDIUM);
                stim_ap.write(stim_pkt);
            end
        end
    endtask : sample_stim

    // Samples output result from DUT
    virtual task sample_result();
        div_packet res_pkt = div_packet::type_id::create("res_pkt", this);

        while (1) begin  // Loop indefinitely until reset
            @(posedge div_vif.clk);
            if (!div_vif.rst_n) begin  // DUT is being reset
                break;
            end
            else if (div_vif.result_vld) begin  // Output result from DUT is valid
                res_pkt.divisible = div_vif.divisible;  // Sample DUT output
                `uvm_info("MON",
                          $sformatf("Observed output result %b", res_pkt.divisible),
                          UVM_MEDIUM);
                result_ap.write(res_pkt);
            end
        end
    endtask : sample_result
endclass : div_monitor

