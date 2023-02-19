///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Module that counts the number of times that a positive and valid
//      'divisible' result was encountered
//    * Counter exposed as a register
///////////////////////////////////////////////////////////////////////////////


// Counter module
module div_counter(
    input clk,
    input rst_n,

    // Outputs of divisibility checker module
    input divisible,
    input result_vld,

    // Register bus
    input                     reg_rd_en,
    input                     reg_wr_en,
    input  [`REG_ADDR_SZ-1:0] reg_addr,
    input  [`REG_DATA_SZ-1:0] reg_wr_data,
    output [`REG_DATA_SZ-1:0] reg_rd_data
);
    // Local constants
    localparam CNT_ADDR = `REG_ADDR_SZ'h05;

    // Wire and reg declarations
    wire                   reg_addr_cnt;  // Whether register currently selected
    reg [`REG_DATA_SZ-1:0] div_cnt;

    // Register bus address decode
    assign reg_addr_cnt = (reg_addr == CNT_ADDR);

    // Sequential logic
    always @(posedge clk) begin
        if (~rst_n) begin
            div_cnt <= 'd0;
        end
        else if (reg_wr_en & reg_addr_cnt) begin  // Register write takes priority
            div_cnt[`REG_DATA_SZ-1:0] <= reg_wr_data[`REG_DATA_SZ-1:0];
        end
        else if (divisible & result_vld) begin  // Positive and valid result
            div_cnt <= div_cnt + 1;
        end
    end

    // Register bus read logic
    assign reg_rd_data[`REG_DATA_SZ-1:0] =
        ({`REG_DATA_SZ{reg_rd_en & reg_addr_cnt}} & div_cnt[`REG_DATA_SZ-1:0]);
endmodule : div_counter

