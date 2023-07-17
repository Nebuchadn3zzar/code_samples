################################################################################
# Author: Will Chen
#
# Description:
#    * Makefile for streaming divisibility checker RTL generator and UVM
#      testbench
#
# Arguments:
#    * DIV_BY=N:        Sets divisor N to a value other than default of 3
#    * UVM_VER=uvm-X.Y: Uses UVM 1.1 if UVM 1.2 not available
#    * TEST=test_name:  Runs a test other than default of 'test_base'
#    * SEED=S:          Simulates using a seed other than default of 1
#
# Examples:
#    * make help
#         * Lists each available make target and its purpose
#    * make DIV_BY=5
#         * Generates a 'divisible by 5' finite state machine in Verilog
#         * Writes a 'DIV_BY' `define to inform testbench of fixed integer
#           divisor that DUT was generated for
#         * Compiles design and testbench
#         * Runs a simulation (default 'test_base') to test the generated FSM
#         * Generates a coverage report in HTML format
#    * make ip DIV_BY=3
#         * Generates a 'divisible by 3' finite state machine in Verilog
#    * make compile UVM_VER=uvm-1.1
#         * Compiles design and testbench using UVM 1.1 libraries instead of
#           UVM 1.2
#    * make sim TEST=test_mostly_divisible SEED=1234
#         * Runs the test 'test_mostly_divisible' with a seed of 1234
#
# Notes:
#    * 'compile', 'sim', and 'cov' targets require Synopsys VCS
################################################################################


# Constants
DIV_BY             = 3  # Default value; meant to be overridden by user (i.e. 'make DIV_BY=5')
GEN_FSM_SCRIPT     = design/gen_divisible_by_N_fsm.py
OUT_RTL_FSM_FILE   = design/rtl/divisible_by_N.v
OUT_TB_DEFINE_FILE = verif/div_by_define.svh
RTL_DIR            = design/rtl
RTL_SOURCES        = $(RTL_DIR)/top.v $(RTL_DIR)/divisible_by_N.v $(RTL_DIR)/div_counter.v
TB_INCL_FILE       = verif/div_uvm_tb.svh

# Compile/run constants
TEST         = test_base
UVM_DEFINES  = UVM_NO_DEPRECATED+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR
UVM_VER      = uvm-1.2
COMPILE_ARGS = -sverilog -timescale="1ns/1ns" -l compile.log -ntb_opts $(UVM_VER) $(RTL_SOURCES) $(TB_INCL_FILE)
SEED         = 1
RUN_ARGS     = -l simv.log +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM


################################################################################
# Collection of human-friendly aliases for actual files and actions
################################################################################

# Target: all     - [Default] Makes and compiles "IP" and "VIP", runs sim, generates coverage report
.PHONY: all
all: ip vip compile sim cov

# Target: ip      - Generates a divisibility checker FSM for fixed integer divisor N in Verilog
.PHONY: ip
ip: $(OUT_RTL_FSM_FILE)

# Target: vip     - Writes a 'DIV_BY' `define to inform testbench of divisor that DUT was generated for
.PHONY: vip
vip: $(OUT_TB_DEFINE_FILE)

# Target: compile - Compiles design and testbench
.PHONY: compile
compile: simv

# Target: sim     - Runs a simulation using VCS
.PHONY: sim
sim: run_sim

# Target: cov     - Generates a coverage report in HTML format
.PHONY: cov
cov: gen_cov_report


################################################################################
# Dependencies between files, and implementations of actions
################################################################################

# Design files
$(OUT_RTL_FSM_FILE): $(GEN_FSM_SCRIPT)
	python3 $(GEN_FSM_SCRIPT) $(DIV_BY) $(OUT_RTL_FSM_FILE)

# Testbench files
$(OUT_TB_DEFINE_FILE):
	echo "\`define DIV_BY $(DIV_BY)  // Integer divisor that DUT was generated for" > $(OUT_TB_DEFINE_FILE)

# Simulator executable
simv: $(OUT_RTL_FSM_FILE) $(OUT_TB_DEFINE_FILE)
	vcs $(COMPILE_ARGS)

# Run simulation
.PHONY: run_sim
run_sim: simv
	./simv +ntb_random_seed=$(SEED) $(RUN_ARGS)

# Coverage report
.PHONY: gen_cov_report
gen_cov_report:
	urg -dir simv.vdb


################################################################################
# Other miscellaneous targets
################################################################################

# Target: clean   - Removes all generated files for starting over
.PHONY: clean
clean:
	-rm -rf $(OUT_RTL_FSM_FILE) $(OUT_TB_DEFINE_FILE) simv* csrc* *.log *.h *.fsdb *.vpd *.vcd \
    novas.* verdi* urgReport ucli.key

# Target: help    - Lists each available make target and its purpose
.PHONY: help
help:
	grep "^# Target:" [Mm]akefile

# Target: debug   - Prints all macros and their values, for debugging purposes
.PHONY: debug
debug:
	@echo "DIV_BY             = $(DIV_BY)"
	@echo "GEN_FSM_SCRIPT     = $(GEN_FSM_SCRIPT)"
	@echo "OUT_RTL_FSM_FILE   = $(OUT_RTL_FSM_FILE)"
	@echo "OUT_TB_DEFINE_FILE = $(OUT_TB_DEFINE_FILE)"
	@echo "RTL_DIR            = $(RTL_DIR)"
	@echo "RTL_SOURCES        = $(RTL_SOURCES)"
	@echo "TB_INCL_FILE       = $(TB_INCL_FILE)"
	@echo "TEST               = $(TEST)"
	@echo "UVM_DEFINES        = $(UVM_DEFINES)"
	@echo "UVM_VER            = $(UVM_VER)"
	@echo "COMPILE_ARGS       = $(COMPILE_ARGS)"
	@echo "SEED               = $(SEED)"
	@echo "RUN_ARGS           = $(RUN_ARGS)"

