///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Scoreboard component of streaming divisibility checker module
///////////////////////////////////////////////////////////////////////////////


class div_scoreboard extends uvm_component;
    // Ports
    `uvm_analysis_imp_decl(_expected)  // Define analysis imp class for 'expected' imp
    `uvm_analysis_imp_decl(_observed)  // Define analysis imp class for 'observed' imp
    uvm_analysis_imp_expected #(div_packet, div_scoreboard) expected_export;
    uvm_analysis_imp_observed #(div_packet, div_scoreboard) observed_export;

    uvm_event queue_empty = new();  // Indicates when scoreboard queue has become empty
    div_packet expected_packets[$];  // Queue of expected packets
    string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hex

    `uvm_component_utils(div_scoreboard);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_export = new("expected_export", this);
        observed_export = new("observed_export", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        queue_empty.trigger();  // Initially trigger, since queue is initially indeed empty
    endfunction : build_phase

    // Pushes a predicted packet onto queue of expected packets
    virtual function void write_expected(div_packet exp);
        expected_packets.push_back(exp);
        queue_empty.reset(.wakeup(1));  // Now that queue is non-empty, turn off event
    endfunction : write_expected

    // Compares an observed packet against list of expected packets
    virtual function void write_observed(div_packet obs);
        div_packet expected;

        // Check that at least one candidate exists in list of expected packets
        if (expected_packets.size() == 0) begin
            `uvm_error("SB",
                       $sformatf("Observed packet, but none expected: Data %s, result %b",
                                 $sformatf(hex_fmt_str, obs.data), obs.divisible));
            return;
        end

        // In-order scoreboard, so compare against only first item in queue
        expected = expected_packets.pop_front();
        if (obs.compare(expected)) begin  // Successful match
            `uvm_info("SB",
                      $sformatf("Successfully matched observed packet against expected (data %s, result %b)",
                                $sformatf(hex_fmt_str, expected.data), expected.divisible),
                      UVM_MEDIUM);
        end
        else begin  // Mismatch
            `uvm_error("SB",
                       $sformatf("For data %s, expected result %b, but observed %b!",
                                 $sformatf(hex_fmt_str, expected.data), expected.divisible, obs.divisible));
        end

        // If queue is now empty, trigger 'queue empty' event
        if (!expected_packets.size()) begin
            queue_empty.trigger();
        end
    endfunction : write_observed

    virtual function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);

        // Check that no items remain on the scoreboard
        if (expected_packets.size() > 0) begin
            `uvm_error("SB",
                       $sformatf("%0d item(s) remain on the scoreboard!",
                                 expected_packets.size()));
        end
    endfunction : extract_phase
endclass : div_scoreboard

