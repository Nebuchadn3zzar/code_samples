////////////////////////////////////////////////////////////////////////////////
// Description:
//    * A simple but fairly complete UVM testbench for a simple "divisible by N" finite state machine
//    * Requires a file 'div_by_define.svh' containing a `define for 'DIV_BY' with the value of N
//    * Supports both UVM 1.1 and UVM 1.2
//
// Everything that's needed to constitute the testbench, contained in one file for faster readability:
//    * div_tb_defines.svh
//    * div_if.sv
//    * tb.sv
//    * div_packet.sv
//    * div_sequencer.sv
//    * div_driver.sv
//    * div_monitor.sv
//    * div_agent.sv
//    * div_ref_model.sv
//    * div_scoreboard.sv
//    * div_cov.sv
//    * my_env.sv
//    * seq_lib.sv
//    * base_test.sv
//
// Limitations:
//    * Currently makes no attempt to guarantee that at least some of the randomly generated values are divisible by
//      N; this is a problem only for large (>50) values of N and small numbers of packets
//    * Does not use RAL, since DUT has no registers
////////////////////////////////////////////////////////////////////////////////


import uvm_pkg::*;
`include "uvm_macros.svh"
`include "div_by_define.svh"


// div_tb_defines.svh
`define MAX_STREAM_LEN 32                           // Maximum length of bitstream to test
`define HEX_DGTS       ((`MAX_STREAM_LEN + 3) / 4)  // Number of hexadecimal digits required to print the longest bitstream value

// div_if.sv
interface div_if();
   logic clk;
   logic rst_n;
   logic bitstream;
   logic bitstream_val;
   logic divisible;
   logic result_val;
endinterface : div_if

// tb.sv
module tb();
   `include "wave_dump.sv"

   // Interface instances
   div_if tb_div_if();

   // Clocks
   reg clk;
   initial begin
      clk <= 1'b0;  // Initial state
      forever #5ns clk = ~clk;  // 100 MHz
   end
   assign tb_div_if.clk = clk;

   // DUT
   divisible_by_N top (
      .clk     (clk),
      .rst_n   (tb_div_if.rst_n),
      .in      (tb_div_if.bitstream),
      .in_val  (tb_div_if.bitstream_val),
      .out     (tb_div_if.divisible),
      .out_val (tb_div_if.result_val)
   );

   // Run test
   initial begin
      // Store handles to physical interfaces into resource database as virtual interface handles
      uvm_config_db#(virtual div_if)::set(null, "uvm_test_top.env.*", "div_vif", tb_div_if);

      run_test();
   end
endmodule : tb

// div_packet.sv
class div_packet extends uvm_sequence_item;
   // Fields
   rand int unsigned                 num_bits;
   rand logic [`MAX_STREAM_LEN-1:0]  data;
   logic                             divisible;

   `uvm_object_utils_begin(div_packet);  // Utility operations such as copy, compare, pack, etc.
      `uvm_field_int(num_bits,  UVM_DEFAULT | UVM_NOCOMPARE);  // UVM_NOCOMPARE: Exclude field from comparisons
      `uvm_field_int(data,      UVM_DEFAULT | UVM_NOCOMPARE);  // UVM_NOCOMPARE: Exclude field from comparisons
      `uvm_field_int(divisible, UVM_DEFAULT);                  // UVM_DEFAULT:   Include field in all utility operations
   `uvm_object_utils_end;

   // Constraints
   constraint num_bits_c {
      num_bits inside {[0:`MAX_STREAM_LEN]};
   }

   function new(string name="div_packet");
      super.new(name);
   endfunction : new
endclass : div_packet

// div_sequencer.sv
class div_sequencer extends uvm_sequencer #(div_packet);
   `uvm_component_utils(div_sequencer);  // Register component with factory

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new
endclass : div_sequencer

// div_driver.sv
class div_driver extends uvm_driver #(div_packet);
   virtual div_if div_vif;  // Virtual interface with DUT

   string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hexadecimal

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
         send_item(req);                    // Drive transaction into DUT
         seq_item_port.item_done();         // Indicate to sequence that driver has completed processing
      end
   endtask : run_phase

   virtual task send_item(div_packet pkt);
      int unsigned bits_remaining = pkt.num_bits;

      // Apply reset before starting to drive new bitstream
      reset();

      `uvm_info("DRV",
                $sformatf("Driving %0d bits of %s (%s)...",
                          pkt.num_bits, $sformatf(hex_fmt_str, pkt.data),
                          $sformatf(hex_fmt_str, pkt.data & (2**pkt.num_bits - 1))),  // Effective data
                UVM_MEDIUM);
      while (bits_remaining > 0) begin
         logic valid = $urandom();  // Randomise whether to drive valid data during this clock

         @(posedge div_vif.clk);
         div_vif.bitstream_val <= valid;
         if (valid) begin
            div_vif.bitstream <= pkt.data[(bits_remaining--) - 1];
         end
      end

      // De-assert 'valid'
      @(posedge div_vif.clk);
      div_vif.bitstream_val <= 1'b0;
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
      div_vif.bitstream_val <= 1'b0;
      repeat (2) @(posedge div_vif.clk);

      // De-assert
      div_vif.rst_n <= 1'b1;
   endtask : reset
endclass : div_driver

// div_monitor.sv
class div_monitor extends uvm_monitor;
   // Ports
   uvm_analysis_port #(div_packet) stim_analysis_port;
   uvm_analysis_port #(div_packet) result_analysis_port;

   virtual div_if div_vif;  // Virtual interface with DUT

   string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hexadecimal

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
      div_packet ap = new();
      int unsigned                bitstream_len_so_far = 0;
      logic [`MAX_STREAM_LEN-1:0] bitstream_val_so_far = 'd0;

      while (1) begin  // Loop indefinitely until reset
         @(posedge div_vif.clk);
         if (!div_vif.rst_n) begin  // DUT is being reset
            break;
         end
         else if (div_vif.bitstream_val) begin  // Input bitstream into DUT is valid
            bitstream_len_so_far++;
            bitstream_val_so_far = (bitstream_val_so_far << 1) | div_vif.bitstream;  // Update bitstream value
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
      div_packet ap = new();

      while (1) begin  // Loop indefinitely until reset
         @(posedge div_vif.clk);
         if (!div_vif.rst_n) begin  // DUT is being reset
            break;
         end
         else if (div_vif.result_val) begin  // Output result from DUT is valid
            ap.divisible = div_vif.divisible;  // Sample DUT output
            `uvm_info("MON", $sformatf("Observed output result %b", ap.divisible), UVM_MEDIUM);
            result_analysis_port.write(ap);
         end
      end
   endtask : sample_result
endclass : div_monitor

// div_agent.sv
class div_agent extends uvm_agent;
   // Ports
   uvm_analysis_port #(div_packet) stim_analysis_port;    // Pass-through port from monitor
   uvm_analysis_port #(div_packet) result_analysis_port;  // Pass-through port from monitor

   // Components
   div_sequencer sqr;
   div_driver    drv;
   div_monitor   mon;

   `uvm_component_utils(div_agent);  // Register component with factory

   function new(string name, uvm_component parent);
      super.new(name, parent);
      stim_analysis_port   = new("stim_analysis_port", this);
      result_analysis_port = new("result_analysis_port", this);
   endfunction : new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // Construct components using factory
      sqr = div_sequencer::type_id::create("sqr", this);
      drv = div_driver::type_id::create("drv", this);
      mon = div_monitor::type_id::create("mon", this);
   endfunction : build_phase

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      // Make connections
      drv.seq_item_port.connect(sqr.seq_item_export);               // Sequencer to driver
      mon.stim_analysis_port.connect(this.stim_analysis_port);      // Pass-through from monitor
      mon.result_analysis_port.connect(this.result_analysis_port);  // Pass-through from monitor
   endfunction : connect_phase
endclass : div_agent

// div_ref_model.sv
class div_ref_model extends uvm_component;
   // Ports
   uvm_analysis_imp  #(div_packet, div_ref_model) analysis_export;
   uvm_analysis_port #(div_packet)                analysis_port;

   string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hexadecimal

   `uvm_component_utils(div_ref_model);  // Register component with factory

   function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
      analysis_port   = new("analysis_port", this);
   endfunction : new

   // Predicts an expected packet from an observed bitstream
   virtual function void write(div_packet stim);
      div_packet ap = new();
      ap.data      = stim.data;
      ap.divisible = ((stim.data % `DIV_BY) == 0);
      `uvm_info("REF_MDL",
                $sformatf("Given stimulus packet with data %s, predicted result %b",
                          $sformatf(hex_fmt_str, ap.data), ap.divisible),
                UVM_MEDIUM);
      analysis_port.write(ap);
   endfunction : write
endclass : div_ref_model

// div_scoreboard.sv
class div_scoreboard extends uvm_component;
   // Ports
   `uvm_analysis_imp_decl(_expected);  // Define analysis imp class for 'expected' imp
   `uvm_analysis_imp_decl(_observed);  // Define analysis imp class for 'observed' imp
   uvm_analysis_imp_expected #(div_packet, div_scoreboard) expected_export;
   uvm_analysis_imp_observed #(div_packet, div_scoreboard) observed_export;

   uvm_event queue_empty = new();                           // Indicates when scoreboard queue has become empty
   div_packet expected_packets[$];                          // Queue of expected packets
   string hex_fmt_str = $sformatf("0x%%0%0dh", `HEX_DGTS);  // Format string for printing in hexadecimal

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
      // In-order scoreboard, so compare against only first item in queue
      div_packet expected = expected_packets.pop_front();
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
         `uvm_error("SB", $sformatf("%0d item(s) remain on the scoreboard!", expected_packets.size()));
      end
   endfunction : extract_phase
endclass : div_scoreboard

// div_cov.sv
covergroup div_stim_cov_group with function sample(div_packet p);
   coverpoint p.num_bits {  // Length of bitstream
      bins a[8] = {[1:`MAX_STREAM_LEN]};
   }
   coverpoint p.data {  // Value of bitstream
      bins a[4] = {[0:$]};
   }
endgroup
covergroup div_result_cov_group with function sample(div_packet p);
   coverpoint p.divisible {  // Divisibility result from DUT
      option.at_least = 1;
   }
endgroup
class div_cov extends uvm_component;
   // Ports
   `uvm_analysis_imp_decl(_stim);    // Define analysis imp class for 'stim' imp
   `uvm_analysis_imp_decl(_result);  // Define analysis imp class for 'result' imp
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

// my_env.sv
class my_env extends uvm_env;
   // Agents
   div_agent agt;

   // Virtual interfaces
   virtual div_if div_vif;

   // Reference model, scoreboard, and coverage component
   div_ref_model  ref_model;
   div_scoreboard sb;
   div_cov        cov_comp;

   `uvm_component_utils(my_env);  // Register component with factory

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // Retrieve virtual interface objects from resource database
      uvm_config_db#(virtual div_if)::get(this, "", "div_vif", div_vif);

      // Pass virtual interface objects down to lower-level components
      uvm_config_db#(virtual div_if)::set(this, "*", "div_vif", div_vif);  // Alternatively, set directly for speed

      // Construct components using factory
      agt       = div_agent::type_id::create("agt", this);
      ref_model = div_ref_model::type_id::create("ref_model", this);
      sb        = div_scoreboard::type_id::create("sb", this);
      cov_comp  = div_cov::type_id::create("cov_comp", this);
   endfunction : build_phase

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      // Make connections
      agt.stim_analysis_port.connect(ref_model.analysis_export);  // Stimulus to reference model, for predictions
      ref_model.analysis_port.connect(sb.expected_export);        // Reference model to scoreboard 'expected' export
      agt.result_analysis_port.connect(sb.observed_export);       // Observed results to scoreboard 'observed' export
      agt.stim_analysis_port.connect(cov_comp.stim_export);       // Stimulus to coverage component
      agt.result_analysis_port.connect(cov_comp.result_export);   // Observed results to coverage component
   endfunction : connect_phase
endclass : my_env

// seq_lib.sv
class div_seq extends uvm_sequence #(div_packet);
   `uvm_object_utils(div_seq);  // Register object with factory

   function new(string name="div_seq");
      super.new(name);
      `ifdef UVM_POST_VERSION_1_1
      set_automatic_phase_objection(1);  // Requires UVM 1.2 or later
      `endif  // UVM_POST_VERSION_1_1
   endfunction : new

   `ifdef UVM_VERSION_1_1
   task pre_start();
      if ((get_parent_sequence() == null) && (starting_phase != null)) begin
         starting_phase.raise_objection(this);
      end
   endtask : pre_start
   task post_start();
      if ((get_parent_sequence() == null) && (starting_phase != null)) begin
         starting_phase.drop_objection(this);
      end
   endtask : post_start
   `endif  // UVM_VERSION_1_1

   virtual task body();
      `uvm_do(req);
   endtask : body
endclass : div_seq

// base_test.sv
class test_base extends uvm_test;
   // Environment
   my_env env;

   // Sequences
   rand div_seq seq;

   rand int unsigned num_values;

   `uvm_component_utils(test_base);  // Register component with factory

   // Constraints
   constraint num_values_c {
      num_values inside {[5:10]};
   }

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      // Construct environment using factory
      env = my_env::type_id::create("env", this);

      // Construct sequence using factory
      seq = div_seq::type_id::create("seq");  // No 'parent', since sequence is an object, not a component
   endfunction : build_phase

   task main_phase(uvm_phase phase);
      super.main_phase(phase);

      phase.raise_objection(this);

      // Randomise number of values to send
      randomize(num_values);
      `uvm_info("TEST", $sformatf("Randomised number of values to send to %0d", num_values), UVM_MEDIUM);

      // Drive some random values
      for (int i = 1; i <= num_values; i++) begin
         `uvm_info("TEST", $sformatf("Driving value %0d of %0d...", i, num_values), UVM_MEDIUM);
         seq.randomize();
         seq.start(env.agt.sqr);
      end

      phase.drop_objection(this);
   endtask : main_phase

   virtual task shutdown_phase(uvm_phase phase);
      // Wait for scoreboard to be empty
      if (env.sb.queue_empty.is_off()) begin  // Queue not yet empty
         `uvm_info("TEST", "Shutdown phase: Waiting for scoreboard to empty...", UVM_MEDIUM);
         phase.raise_objection(this, "Waiting for scoreboard to empty...");
         forever begin
            env.sb.queue_empty.wait_trigger();  // FIXME: This should eventually time out in case the DUT misbehaves
            if (env.sb.queue_empty.is_on()) begin  // Queue is now empty
               phase.drop_objection(this, "Scoreboard is now empty");
            end
         end
      end
   endtask : shutdown_phase
endclass : test_base
