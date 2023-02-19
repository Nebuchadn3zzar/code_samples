///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Monitor component of streaming divisibility checker agent
///////////////////////////////////////////////////////////////////////////////


class div_monitor extends uvm_monitor;
    // Ports
    uvm_analysis_port #(div_packet) stim_analysis_port;
    uvm_analysis_port #(div_packet) result_analysis_port;

    virtual div_if div_vif;  // Virtual interface with DUT

    string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hex

    `uvm_component_utils(div_monitor);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
        stim_analysis_port   = new("stim_analysis_port", this);
        result_analysis_port = new("result_analysis_port", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual div_if)::get(this, "", "div_vif", div_vif)) begin
            `uvm_fatal("DRVCFG", "No virtual interface object passed!");
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
        div_packet ap = div_packet::type_id::create("ap", this);
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
                ap.num_bits = bitstream_len_so_far;
                ap.data     = bitstream_val_so_far;
                `uvm_info("MON",
                          $sformatf("Observed input bitstream of length %0d, value %s",
                                    ap.num_bits, $sformatf(hex_fmt_str, ap.data)),
                          UVM_MEDIUM);
                stim_analysis_port.write(ap);
            end
        end
    endtask : sample_stim

    // Samples output result from DUT
    virtual task sample_result();
        div_packet ap = div_packet::type_id::create("ap", this);

        while (1) begin  // Loop indefinitely until reset
            @(posedge div_vif.clk);
            if (!div_vif.rst_n) begin  // DUT is being reset
                break;
            end
            else if (div_vif.result_vld) begin  // Output result from DUT is valid
                ap.divisible = div_vif.divisible;  // Sample DUT output
                `uvm_info("MON", $sformatf("Observed output result %b", ap.divisible), UVM_MEDIUM);
                result_analysis_port.write(ap);
            end
        end
    endtask : sample_result
endclass : div_monitor

