///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Library of sequences executed by tests for validating streaming
//      divisibility checker
///////////////////////////////////////////////////////////////////////////////


// Sequence for application of reset
class reset_seq extends uvm_sequence #(reset_txn);
    `uvm_object_utils(reset_seq);  // Register object with factory

    function new(string name="reset_seq");
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
endclass : reset_seq

// Base sequence for streaming divisibility checker module
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

// Base sequence for register bus interface
class reg_seq_base extends uvm_sequence #(reg_rw_item);
    `uvm_object_utils(reg_seq_base);  // Register object with factory

    function new(string name="reg_seq_base");
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
endclass : reg_seq_base

// Register sequence for counter register block
class counter_reg_seq extends uvm_reg_sequence #(reg_seq_base);
    reg_block_counter reg_model;
    uvm_status_e      status;
    uvm_reg_data_t    data;

    `uvm_object_utils(counter_reg_seq);  // Register object with factory

    function new(string name="counter_reg_seq");
        super.new(name);
    endfunction : new

    task pre_start();
        // Retrieve register model handle from resource database
        if (!uvm_resource_db#(reg_block_counter)::read_by_name(
            get_sequencer().get_full_name(), "reg_model", reg_model, this
        )) begin
            `uvm_fatal("CFG_SEQ", "Failed to retrieve 'reg_model' handle from resource database!");
        end
    endtask : pre_start

    virtual task body();
        uvm_reg_data_t front_door_data;
        uvm_reg_data_t back_door_data;

        // Read via front door, checking read value against predicted mirror value
        reg_model.div_cnt.mirror(status, UVM_CHECK, UVM_FRONTDOOR, .parent(this));
        front_door_data = reg_model.div_cnt.get_mirrored_value();  // New mirrored value
        `uvm_info("REG_SEQ",
                  $sformatf("Read data 0x%0h from 'div_cnt' register via front door",
                            front_door_data),
                  UVM_MEDIUM);

        // Read via back door, checking read value against predicted mirror value
        reg_model.div_cnt.mirror(status, UVM_CHECK, UVM_BACKDOOR, .parent(this));
        back_door_data = reg_model.div_cnt.get_mirrored_value();  // New mirrored value
        `uvm_info("REG_SEQ",
                  $sformatf("Read data 0x%0h from 'div_cnt' register via back door",
                            back_door_data),
                  UVM_MEDIUM);
        if (front_door_data != back_door_data) begin
            `uvm_error("REG_SEQ",
                       $sformatf("Front door read data 0x%0h does not match back door data 0x%0h!",
                                 front_door_data, back_door_data));
        end

        data = front_door_data;  // "Return" data read via front door
    endtask : body
endclass : counter_reg_seq

