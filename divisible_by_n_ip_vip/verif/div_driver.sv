///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Driver component of streaming divisibility checker agent
///////////////////////////////////////////////////////////////////////////////


class div_driver extends uvm_driver #(div_packet);
    virtual div_if div_vif;  // Virtual interface with DUT

    string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hex

    `uvm_component_utils(div_driver);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual div_if)::get(this, "", "div_vif", div_vif)) begin
            `uvm_fatal("DRVCFG", "No virtual interface object passed!");
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);  // Blocking 'get'
            send_item(req);  // Drive transaction into DUT
            seq_item_port.item_done();  // Indicate to sequence that driver has completed processing
        end
    endtask : run_phase

    virtual task send_item(div_packet pkt);
        int unsigned bits_remaining = pkt.num_bits;

        // Apply reset before starting to drive new bitstream
        reset();

        `uvm_info("DRV",
                  $sformatf("Driving %0d bits of %s (mod %0d = %0d)...",
                            pkt.num_bits, $sformatf(hex_fmt_str, pkt.data), `DIV_BY, pkt.modulo),
                  UVM_MEDIUM);
        while (bits_remaining > 0) begin
            logic valid = $urandom();  // Randomise whether to drive valid data during this clock

            @(posedge div_vif.clk);
            div_vif.bitstream_vld <= valid;
            if (valid) begin
                div_vif.bitstream <= pkt.data[(bits_remaining--) - 1];
            end
        end

        // De-assert 'valid'
        @(posedge div_vif.clk);
        div_vif.bitstream_vld <= 1'b0;
    endtask : send_item

    // Asserts reset
    virtual task reset();
        // Initially de-assert
        div_vif.rst_n <= 1'b1;

        // Assert for 2 clocks
        `uvm_info("DRV", $sformatf("Applying reset for 2 clocks..."), UVM_MEDIUM);
        @(posedge div_vif.clk);
        div_vif.rst_n         <= 1'b0;
        div_vif.bitstream     <= 1'b0;
        div_vif.bitstream_vld <= 1'b0;
        repeat (2) @(posedge div_vif.clk);

        // De-assert
        div_vif.rst_n <= 1'b1;
    endtask : reset
endclass : div_driver

