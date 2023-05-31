///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Environment component of streaming divisibility checker UVM testbench
///////////////////////////////////////////////////////////////////////////////


class div_env extends uvm_env;
    // Agents
    reset_agent rst_agt;
    div_agent   div_agt;
    reg_agent   reg_agt;

    // Register model
    reg_block_counter reg_model;

    // Virtual interfaces
    virtual div_if div_vif;
    virtual reg_if reg_vif;

    // Reference model and scoreboard components
    div_ref_model  ref_model;
    div_scoreboard div_sb;

    // Predictors that update register model mirror of counter register in response to observed
    // transactions on physical busses
    rst2reg_predict rst2reg;  // Derived class because 'write()' function is overridden
    div2reg_predict div2reg;  // Derived class because 'write()' function is overridden

    `uvm_component_utils(div_env);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Retrieve virtual interface objects from resource database
        if (!uvm_resource_db#(virtual div_if)::read_by_name(
            get_full_name(), "div_vif", div_vif, this
        )) begin
            `uvm_fatal("CFG_ENV", "No divisibility checker virtual interface object passed!");
        end
        if (!uvm_resource_db#(virtual reg_if)::read_by_name(
            get_full_name(), "reg_vif", reg_vif, this
        )) begin
            `uvm_fatal("CFG_ENV", "No register bus virtual interface object passed!");
        end

        // Pass virtual interface objects down to lower-level components via resource database
        // (alternatively, set directly for speed)
        uvm_resource_db#(virtual div_if)::set({get_full_name(), ".*"}, "div_vif", div_vif, this);
        uvm_resource_db#(virtual reg_if)::set({get_full_name(), ".*"}, "reg_vif", reg_vif, this);

        // Construct components using factory
        rst_agt   = reset_agent::type_id::create("rst_agt", this);
        div_agt   = div_agent::type_id::create("div_agt", this);
        reg_agt   = reg_agent::type_id::create("reg_agt", this);
        ref_model = div_ref_model::type_id::create("ref_model", this);
        div_sb    = div_scoreboard::type_id::create("div_sb", this);
        rst2reg   = rst2reg_predict::type_id::create("rst2reg", this);
        div2reg   = div2reg_predict::type_id::create("div2reg", this);

        // Instantiate register model, create address map, and pass register model handle to
        // sequencer of register agent
        reg_model = reg_block_counter::type_id::create("reg_model", this);
        reg_model.configure(
            .parent   (null),
            .hdl_path ("tb.dut_top.div_counter")
        );
        reg_model.build();  // Create UVM register hierarchy
        reg_model.lock_model();  // Lock register hierarchy and build address map
        uvm_resource_db#(reg_block_counter)::set(
            {get_full_name(), ".reg_agt.sqr"}, "reg_model", reg_model, this
        );
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Make connections
        rst_agt.ap.connect(rst2reg.bus_in);                       // Observed resets to predictor
        div_agt.stim_ap.connect(ref_model.analysis_export);       // Stimulus to reference model
        ref_model.analysis_port.connect(div_sb.expected_export);  // Reference model to scoreboard
        div_agt.result_ap.connect(div_sb.observed_export);        // Observed results to scoreboard
        div_agt.result_ap.connect(div2reg.bus_in);                // Observed results to predictor

        // Associate register transaction adapter with default map of register model
        reg_model.default_map.set_sequencer(reg_agt.sqr, reg_agt.adapter);

        // Enable automatic register model mirror prediction upon register reads and writes
        reg_model.default_map.set_auto_predict(1);

        // Setup necessary for direct updating of mirror of counter register in response to
        // observed reset application or observed positive and valid 'divisible' result
        rst2reg.reg_model = reg_model;  // Pass handle to register model of counter block
        div2reg.reg_model = reg_model;  // Pass handle to register model of counter block
    endfunction : connect_phase
endclass : div_env

