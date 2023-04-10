# Code samples

* [Description](#Description)
* [Summary](#Summary)

## Description

* Arbitrary collection of code that I wrote for fun or for practice
* Intended to provide prospective employers with a slightly more representative approximation of real-world output than can be inferred during a 20-minute whiteboard session

## Summary

* [Streaming divisibility checker RTL generator and UVM testbench](divisible_by_n_ip_vip/)
    * Python script that generates a Verilog module that takes a bitstream as input, and outputs whether the bitstream thus far is divisible by a user-specified integer divisor
    * Complete UVM testbench and test that verifies DUT and collects coverage
    * Makefile
* [Computer vision edge detector in Python and Verilog](img_edge_detector/)
    * Applies an edge detection operator to an input greyscale image, producing a new greyscale image file with detected edges marked
    * Implemented as both a Python script and a Verilog design
* [SystemVerilog class for sparsely populating memory](base_size_pairs_containers_biased_split.sv)
    * Generic SystemVerilog class that generates a list of non-overlapping [base address, size] pairs to be used to sparsely populate a block of memory

