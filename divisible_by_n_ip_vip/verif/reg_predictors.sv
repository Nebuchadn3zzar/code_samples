///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Register predictor components that update register model mirror values
//      based on transactions explicitly observed on physical busses
//    * Analysis imp of UVM register predictor typically receives a register
//      bus transaction and converts it to a UVM-abstracted register
//      transaction using an adapter, but in the case of this DUT, purpose of
//      predictors is solely to update mirror of counter register upon each
//      observed reset application or observed positive and valid 'divisible'
//      result (neither of which is a register bus transaction)
///////////////////////////////////////////////////////////////////////////////


// Upon each observed reset application, resets mirror of counter register to 0
class rst2reg_predict extends uvm_reg_predictor #(reset_txn);
    reg_block_counter reg_model;

    `uvm_component_utils(rst2reg_predict);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void write(reset_txn tr);  // Overrides 'uvm_reg_predictor' implementation
        `uvm_info("PRED",
                  $sformatf("Resetting mirror of counter register from %0d to 0...",
                            reg_model.div_cnt.get_mirrored_value()),
                  UVM_HIGH);

        // Directly predict new mirror value of counter register
        if (!reg_model.div_cnt.predict(0, .kind(UVM_PREDICT_DIRECT))) begin
            `uvm_error("PRED",
                       $sformatf("Prediction of mirror value of counter register failed!"));
        end
    endfunction : write
endclass : rst2reg_predict

// Upon each observed positive and valid 'divisible' result, increments mirror value of counter
// register
class div2reg_predict extends uvm_reg_predictor #(div_packet);
    reg_block_counter reg_model;

    `uvm_component_utils(div2reg_predict);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void write(div_packet tr);  // Overrides 'uvm_reg_predictor' implementation
        int cnt_before;  // Mirror value of counter register before incrementing

        if (tr.divisible) begin  // Increment of mirrored value required
            cnt_before = reg_model.div_cnt.get_mirrored_value();  // Current value
            `uvm_info("PRED",
                      $sformatf("Incrementing mirror of counter register from %0d to %0d...",
                                cnt_before, cnt_before + 1),
                      UVM_HIGH);

            // Directly predict new mirror value of counter register
            if (!reg_model.div_cnt.predict(cnt_before + 1, .kind(UVM_PREDICT_DIRECT))) begin
                `uvm_error("PRED",
                           $sformatf("Prediction of mirror value of counter register failed!"));
            end
        end
    endfunction : write
endclass : div2reg_predict

