///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Register model of streaming divisibility checker design
//    * Typically generated from RALF or IP-XACT, but manually defined here
///////////////////////////////////////////////////////////////////////////////


// Counter register within counter module
class reg_div_cnt extends uvm_reg;
    // Fields
    rand uvm_reg_field div_cnt;  // Times a positive and valid 'divisible' result was encountered

    `uvm_object_utils(reg_div_cnt);  // Register object with factory

    function new(string name="reg_div_cnt");
        super.new(name, .n_bits(16), .has_coverage(UVM_CVR_FIELD_VALS));
    endfunction : new

    virtual function void build();
        div_cnt = uvm_reg_field::type_id::create("div_cnt");
        div_cnt.configure(
            .parent                  (this),
            .size                    (16),
            .lsb_pos                 (8'h00),
            .access                  ("RW"),
            .volatile                (0),
            .reset                   (16'h0000),
            .has_reset               (1),
            .is_rand                 (0),
            .individually_accessible (1)
        );
    endfunction : build
endclass : reg_div_cnt

// Counter register block
class reg_block_counter extends uvm_reg_block;
    // Registers
    rand reg_div_cnt div_cnt;  // Counter register within counter module

    `uvm_object_utils(reg_block_counter);  // Register object with factory

    function new(string name="reg_block_counter");
        super.new(name);
    endfunction : new

    virtual function void build();
        // Counter register
        div_cnt = reg_div_cnt::type_id::create("div_cnt");
        div_cnt.configure(
            .blk_parent (this),
            .hdl_path   ("div_cnt")
        );
        div_cnt.build();

        // Create map, add registers, and lock model
        default_map = create_map(
            .name      ("default_map"),
            .base_addr (8'h00),
            .n_bytes   (2),
            .endian    (UVM_LITTLE_ENDIAN)
        );
        default_map.add_reg(
            .rg     (div_cnt),
            .offset (8'h05),
            .rights ("RW")
        );
        lock_model();  // Lock model and build address map
    endfunction : build
endclass : reg_block_counter

