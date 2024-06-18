///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Manual testbench of image edge detector RTL design
//    * To be replaced with a SystemVerilog UVM testbench
///////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ns

module tb();
    // Clocks
    reg clk;
    initial begin
        clk <= 1'b0;  // Initial state
        forever #5ns clk = ~clk;  // 100 MHz
    end

    // Resets
    reg rst;
    initial begin
        rst <= 1'b0;  // Initial state
        @(posedge clk);
        rst <= 1'b1;  // Assert reset
        @(posedge clk);
        rst <= 1'b0;  // De-assert reset
    end

    // DUT
    reg run;
    reg done;
    top dut_top (
        .clk                       (clk),
        .rst_n                     (~rst),
        .run                       (run),
        .done                      (done),
        .frame_buf_in_wr_en        (),
        .frame_buf_in_wr_x         (),
        .frame_buf_in_wr_y         (),
        .frame_buf_in_wr_data_pxl  (),
        .frame_buf_out_rd_en       (),
        .frame_buf_out_rd_x        (),
        .frame_buf_out_rd_y        (),
        .frame_buf_out_rd_data_pxl ()
    );

    // Run simulation
    initial begin
        $display("%0t: Testbench start", $time);

        // Waveform dumping configuration
        $dumpfile("waves.vcd");
        $dumpvars();  // All
        $dumpon;

        // Force 5x5 input image into memory
        dut_top.frame_buf_in.img_buf[00][00] = 'd250;
        dut_top.frame_buf_in.img_buf[00][01] = 'd000;
        dut_top.frame_buf_in.img_buf[00][02] = 'd000;
        dut_top.frame_buf_in.img_buf[00][03] = 'd000;
        dut_top.frame_buf_in.img_buf[00][04] = 'd000;
        dut_top.frame_buf_in.img_buf[01][00] = 'd000;
        dut_top.frame_buf_in.img_buf[01][01] = 'd251;
        dut_top.frame_buf_in.img_buf[01][02] = 'd000;
        dut_top.frame_buf_in.img_buf[01][03] = 'd000;
        dut_top.frame_buf_in.img_buf[01][04] = 'd000;
        dut_top.frame_buf_in.img_buf[02][00] = 'd000;
        dut_top.frame_buf_in.img_buf[02][01] = 'd000;
        dut_top.frame_buf_in.img_buf[02][02] = 'd252;
        dut_top.frame_buf_in.img_buf[02][03] = 'd000;
        dut_top.frame_buf_in.img_buf[02][04] = 'd000;
        dut_top.frame_buf_in.img_buf[03][00] = 'd000;
        dut_top.frame_buf_in.img_buf[03][01] = 'd000;
        dut_top.frame_buf_in.img_buf[03][02] = 'd000;
        dut_top.frame_buf_in.img_buf[03][03] = 'd253;
        dut_top.frame_buf_in.img_buf[03][04] = 'd000;
        dut_top.frame_buf_in.img_buf[04][00] = 'd000;
        dut_top.frame_buf_in.img_buf[04][01] = 'd000;
        dut_top.frame_buf_in.img_buf[04][02] = 'd000;
        dut_top.frame_buf_in.img_buf[04][03] = 'd000;
        dut_top.frame_buf_in.img_buf[04][04] = 'd254;

        // Run for a pre-determined length of time
        run = 1'b1;
        #(1ns * 1500);

        $display("%0t: Testbench end", $time);
        $display("%0t: DUT reports done %0d", $time, done);

        $dumpflush;
        $finish;
    end
endmodule : tb

