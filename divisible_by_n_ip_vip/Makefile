################################################################################
# Description:
#    * Makefile for "divisible by N" IP and "VIP"
#
# Arguments:
#    * DIV_BY=N        (for setting N to something other than the default of 3)
#    * UVM_VER=uvm-X.Y (for using UVM 1.1 if UVM 1.2 is not available)
#    * SEED=S          (for simulating using a seed other than the default of 1)
#
# Examples:
#    * make help
#         * Lists each available make target and its purpose
#    * make DIV_BY=5
#         * Generates a "divisible by 5" finite state machine in Verilog
#         * Writes a `define for 'DIV_BY' so that testbench knows what to expect from DUT
#         * Compiles design and testbench
#         * Runs a simulation to test the generated FSM
#         * Generates a coverage report in HTML format
#    * make ip DIV_BY=3
#         * Generates a "divisible by 3" finite state machine in Verilog
#    * make compile UVM_VER=uvm-1.1
#         * Compiles design and testbench using UVM 1.1 libraries instead of UVM 1.2
#    * make sim SEED=1234
#         * Runs a simulation with seed 1234
#
# Limitations:
#    * This is not really a Makefile, as it makes no attempt to manage dependencies; effectively just a collection of
#      aliases and variables
#    * 'compile', 'sim', and 'cov' targets require Synopsys VCS
################################################################################


GEN_FSM_SCRIPT     = gen_divisible_by_N_fsm.pl
DIV_BY             = 3  # Default value; meant to be overridden by user (i.e. 'make DIV_BY=5')
OUT_VERILOG_FILE   = divisible_by_N.v
OUT_TB_DEFINE_FILE = div_by_define.svh
TB_FILE 	 	 	    = div_uvm_tb.sv

TEST_NAME    = test_base
UVM_DEFINES  = UVM_NO_DEPRECATED+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR
UVM_VER      = uvm-1.2
COMPILE_ARGS = -sverilog -timescale="1ns/1ns" -l compile.log -ntb_opts $(UVM_VER) $(OUT_VERILOG_FILE) $(TB_FILE)
SEED         = 1
RUN_ARGS     = -l simv.log +UVM_TESTNAME=$(TEST_NAME) +UVM_VERBOSITY=UVM_MEDIUM

# Target: all     - [Default] Makes both IP & "VIP", compiles design & testbench, runs sim, generates coverage report
.PHONY: all
all: ip vip compile sim cov

# Target: ip      - Generates a "divisible by N" finite state machine in Verilog, N being value of 'DIV_BY' macro
.PHONY: ip
ip:
	perl $(GEN_FSM_SCRIPT) -n $(DIV_BY) -o $(OUT_VERILOG_FILE)

# Target: vip     - Writes a `define for 'DIV_BY' so that testbench knows what to expect from the DUT
.PHONY: vip
vip:
	echo "\`define DIV_BY $(DIV_BY)  // DUT is a \"divisible-by-N\" FSM; \`DIV_BY = N" > $(OUT_TB_DEFINE_FILE)

# Target: compile - Compiles design and testbench
.PHONY: compile
compile:
	vcs $(COMPILE_ARGS)

# Target: sim     - Runs a simulation using VCS
.PHONY: sim
sim:
	./simv +ntb_random_seed=$(SEED) $(RUN_ARGS)

# Target: cov     - Generates a coverage report in HTML format
.PHONY: cov
cov:
	urg -dir simv.vdb

# Target: clean   - Removes all generated files for starting over
.PHONY: clean
clean:
	-rm -rf $(OUT_VERILOG_FILE) $(OUT_TB_DEFINE_FILE) simv* csrc* *.log *.h *.fsdb *.vpd *.vcd novas.* verdi* \
   urgReport ucli.key

# Target: help    - Lists each available make target and its purpose
.PHONY: help
help:
	grep "^# Target:" [Mm]akefile

# Target: debug   - Prints all macros and their values, for debugging purposes
.PHONY: debug
debug:
	@echo "GEN_FSM_SCRIPT     = $(GEN_FSM_SCRIPT)"
	@echo "DIV_BY             = $(DIV_BY)"
	@echo "OUT_VERILOG_FILE   = $(OUT_VERILOG_FILE)"
	@echo "OUT_TB_DEFINE_FILE = $(OUT_TB_DEFINE_FILE)"
	@echo "TB_FILE            = $(TB_FILE)"
	@echo "TEST_NAME          = $(TEST_NAME)"
	@echo "UVM_DEFINES        = $(UVM_DEFINES)"
	@echo "UVM_VER            = $(UVM_VER)"
	@echo "COMPILE_ARGS       = $(COMPILE_ARGS)"
	@echo "SEED               = $(SEED)"
	@echo "RUN_ARGS           = $(RUN_ARGS)"

