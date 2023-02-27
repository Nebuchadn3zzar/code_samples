////////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Library of UVM tests for validating streaming divisibility checker
////////////////////////////////////////////////////////////////////////////////


// Sends stimulus whose values should cover an even distribution of possible
// values that can fit within bitstreams of length `MAX_STREAM_LEN
class test_base extends uvm_test;
    // Environment
    div_env env;

    // Sequences
    rand reset_seq       rst_seq;
    rand div_seq         seq;
    rand counter_reg_seq reg_seq;

    rand int unsigned num_values;
    int unsigned      cur_val_idx;  // Index of current bitstream value being driven

    `uvm_component_utils(test_base);  // Register component with factory

    // Constraints
    constraint num_values_c {
        num_values inside {[5:10]};
    }

    function new(string name, uvm_component parent);
        super.new(name, parent);

        cur_val_idx = 1;  // Initialise index of current bitstream value being driven
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Construct environment using factory
        env = div_env::type_id::create("env", this);

        // Construct sequences using factory
        rst_seq = reset_seq::type_id::create("rst_seq");
        seq     = div_seq::type_id::create("seq");
        reg_seq = counter_reg_seq::type_id::create("reg_seq");
    endfunction : build_phase

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);

        // Randomise number of values to send
        if (!randomize(num_values)) begin
            `uvm_fatal("TEST", "Failed to randomise 'num_values'!");
        end
        `uvm_info("TEST",
                  $sformatf("Randomised number of values to send to %0d", num_values),
                  UVM_MEDIUM);
    endfunction : start_of_simulation_phase

    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);

        phase.raise_objection(this);

        // Apply reset
        `uvm_info("TEST",
                  $sformatf("Applying reset %0d of %0d...", cur_val_idx, num_values),
                  UVM_MEDIUM);
        if (!rst_seq.randomize()) begin
            `uvm_fatal("TEST", "Failed to randomise 'rst_seq'!");
        end
        rst_seq.start(env.rst_agt.sqr);

        phase.drop_objection(this);
    endtask : reset_phase

    virtual task main_phase(uvm_phase phase);
        super.main_phase(phase);

        phase.raise_objection(this);

        // Drive bitstream into DUT
        `uvm_info("TEST",
                  $sformatf("Driving bitstream value %0d of %0d...", cur_val_idx, num_values),
                  UVM_MEDIUM);
        if (!seq.randomize()) begin
            `uvm_fatal("TEST", "Failed to randomise 'seq'!");
        end
        seq.start(env.div_agt.sqr);

        phase.drop_objection(this);
    endtask : main_phase

    virtual task shutdown_phase(uvm_phase phase);
        // Wait for scoreboard to be empty
        if (env.div_sb.queue_empty.is_off()) begin  // Queue not yet empty
            `uvm_info("TEST", "Shutdown phase: Waiting for scoreboard to empty...", UVM_MEDIUM);
            phase.raise_objection(this, "Waiting for scoreboard to empty...");
            fork
                forever begin
                    env.div_sb.queue_empty.wait_trigger();
                    if (env.div_sb.queue_empty.is_on()) begin  // Queue is now empty
                        `uvm_info("TEST", "Shutdown phase: Scoreboard is now empty", UVM_MEDIUM);
                        phase.drop_objection(this, "Scoreboard is now empty");
                    end
                end
                begin
                    int timeout_us = 20;
                    #(1us * timeout_us);
                    `uvm_fatal("TEST",
                               $sformatf("Timed out after waiting %0d us for scoreboard to empty!",
                                         timeout_us));
                end
            join_any
            disable fork;
        end
    endtask : shutdown_phase

    virtual task post_shutdown_phase(uvm_phase phase);
        super.post_shutdown_phase(phase);

        phase.raise_objection(this);

        // Using register abstraction layer, mirror counter of number of times that a positive
        // and valid 'divisible' result was encountered since last reset, which automatically
        // checks read value against register model predicted mirror value
        `uvm_info("TEST",
                  $sformatf("Checking count of divisible results in bitstream %0d of %0d...",
                            cur_val_idx, num_values),
                  UVM_MEDIUM);
        if (!reg_seq.randomize()) begin
            `uvm_fatal("TEST", "Failed to randomise 'reg_seq'!");
        end
        reg_seq.start(env.reg_agt.sqr);

        phase.drop_objection(this);

        // If more bitstream values to send, jump back to pre-reset phase
        if (cur_val_idx < num_values) begin
            `uvm_info("TEST",
                      $sformatf("%0d of %0d bitstream values sent; jumping to pre-reset phase...",
                                cur_val_idx, num_values),
                      UVM_MEDIUM);
            ++cur_val_idx;  // Increment index of current bitstream value being driven
            phase.jump(uvm_pre_reset_phase::get());
        end
    endtask : post_shutdown_phase
endclass : test_base

// Sends stimulus whose values are mostly evenly divisible by N, rather than evenly distributed
class test_mostly_divisible extends test_base;
    `uvm_component_utils(test_mostly_divisible);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Factory overrides
        set_type_override_by_type(div_packet::get_type(), div_packet_mostly_divisible::get_type());
    endfunction : build_phase
endclass : test_mostly_divisible

// Runs all built-in UVM register functionality tests
class test_reg_built_in extends uvm_test;
    // Environment
    div_env env;

    // Sequences
    rand uvm_reg_mem_built_in_seq reg_seq;

    `uvm_component_utils(test_reg_built_in);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Construct environment using factory
        env = div_env::type_id::create("env", this);

        // Construct sequence using factory
        reg_seq = uvm_reg_mem_built_in_seq::type_id::create("reg_seq");
    endfunction : build_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        reg_block_counter reg_model;

        super.end_of_elaboration_phase(phase);

        // Retrieve register model handle from resource database
        if (!uvm_config_db#(reg_block_counter)::get(env.reg_agt.sqr, "", "reg_model", reg_model)) begin
            `uvm_fatal("TEST", "Failed to retrieve 'reg_model' handle from resource database!");
        end

        // Set register model that built-in register sequence is to test
        reg_seq.model = reg_model;
    endfunction : end_of_elaboration_phase

    virtual task main_phase(uvm_phase phase);
        super.main_phase(phase);

        phase.raise_objection(this);

        // Start sequence that contains all built-in register tests
        `uvm_info("TEST",
                  "Starting sequence that contains all built-in register tests...",
                  UVM_MEDIUM);
        reg_seq.start(env.reg_agt.sqr);

        phase.drop_objection(this);
    endtask : main_phase
endclass : test_reg_built_in

