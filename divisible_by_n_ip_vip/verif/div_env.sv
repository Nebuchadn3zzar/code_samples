///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Environment component of streaming divisibility checker UVM testbench
///////////////////////////////////////////////////////////////////////////////


class div_env extends uvm_env;
    // Agents
    div_agent agt;
    reg_agent reg_agt;

    // Register model
    reg_block_counter reg_model;

    // Virtual interfaces
    virtual div_if div_vif;
    virtual reg_if reg_vif;

    // Reference model, scoreboard, and coverage component
    div_ref_model  ref_model;
    div_scoreboard sb;
    div_cov        cov_comp;

    `uvm_component_utils(div_env);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Retrieve virtual interface objects from resource database
        uvm_config_db#(virtual div_if)::get(this, "", "div_vif", div_vif);
        uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", reg_vif);

        // Pass virtual interface objects down to lower-level components via resource database
        // (alternatively, set directly for speed)
        uvm_config_db#(virtual div_if)::set(this, "*", "div_vif", div_vif);
        uvm_config_db#(virtual reg_if)::set(this, "*", "reg_vif", reg_vif);

        // Construct components using factory
        agt       = div_agent::type_id::create("agt", this);
        reg_agt   = reg_agent::type_id::create("reg_agt", this);
        ref_model = div_ref_model::type_id::create("ref_model", this);
        sb        = div_scoreboard::type_id::create("sb", this);
        cov_comp  = div_cov::type_id::create("cov_comp", this);

        // Instantiate register model, create address map, and pass register model handle to
        // sequencer of register agent
        reg_model = reg_block_counter::type_id::create("reg_model", this);
        reg_model.configure(
            .parent   (null),
            .hdl_path ("tb.dut_top.div_counter")
        );
        reg_model.build();  // Create UVM register hierarchy
        reg_model.lock_model();  // Lock register hierarchy and build address map
        uvm_config_db#(reg_block_counter)::set(this, "reg_agt.sqr", "reg_model", reg_model);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Make connections
        agt.stim_analysis_port.connect(ref_model.analysis_export);  // Stimulus to reference model
        ref_model.analysis_port.connect(sb.expected_export);        // Reference model to scoreboard
        agt.result_analysis_port.connect(sb.observed_export);       // Observed results to scoreboard
        agt.stim_analysis_port.connect(cov_comp.stim_export);       // Stimulus to coverage component
        agt.result_analysis_port.connect(cov_comp.result_export);   // Observed results to coverage

        // Associate register transaction adapter with default map of register model
        reg_model.default_map.set_sequencer(reg_agt.sqr, reg_agt.adapter);

        // Enable automatic register model mirror prediction upon register reads and writes
        reg_model.default_map.set_auto_predict(1);
    endfunction : connect_phase
endclass : div_env

