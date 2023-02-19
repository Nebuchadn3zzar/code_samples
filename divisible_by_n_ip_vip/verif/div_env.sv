///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Environment component of streaming divisibility checker UVM testbench
///////////////////////////////////////////////////////////////////////////////


class div_env extends uvm_env;
    // Agents
    div_agent agt;

    // Virtual interfaces
    virtual div_if div_vif;

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

        // Pass virtual interface objects down to lower-level components via resource database
        // (alternatively, set directly for speed)
        uvm_config_db#(virtual div_if)::set(this, "*", "div_vif", div_vif);

        // Construct components using factory
        agt       = div_agent::type_id::create("agt", this);
        ref_model = div_ref_model::type_id::create("ref_model", this);
        sb        = div_scoreboard::type_id::create("sb", this);
        cov_comp  = div_cov::type_id::create("cov_comp", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Make connections
        agt.stim_analysis_port.connect(ref_model.analysis_export);  // Stimulus to reference model
        ref_model.analysis_port.connect(sb.expected_export);        // Reference model to scoreboard
        agt.result_analysis_port.connect(sb.observed_export);       // Observed results to scoreboard
        agt.stim_analysis_port.connect(cov_comp.stim_export);       // Stimulus to coverage component
        agt.result_analysis_port.connect(cov_comp.result_export);   // Observed results to coverage
    endfunction : connect_phase
endclass : div_env

