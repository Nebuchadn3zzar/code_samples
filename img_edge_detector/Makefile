################################################################################
# Author: Will Chen
#
# Description:
#    * Makefile for computer vision edge detector RTL design and testbench
#
# Examples:
#    * make help
#       * Lists each available make target and its purpose
#    * make compile
#       * Compiles design and testbench
#    * make sim
#       * Runs simulation using selected simulator
#
# Notes:
#    * Currently supports only Icarus Verilog simulator
################################################################################


# Constants
RTL_PATH      = design
VERIF_PATH    = verif
RTL_FILE_LIST = $(RTL_PATH)/rtl.f
VERIF_TB_HDR  = $(VERIF_PATH)/tb.svh

# Variable defaults, ignored if already specified on command line
SIMULATOR ?= icarus

# Compile/run variables
ifeq ($(SIMULATOR), icarus)  # Icarus Verilog
	COMPILE_ARGS = -g2005-sv -s tb -D NO_SV_AUTO_VAR
	COMPILE_OUT  = a.out
	RUN_ARGS     = -l sim.log
endif
COMPILE_ARGS += -f $(RTL_FILE_LIST) $(VERIF_TB_HDR)

# Target: all     - [Default] Compiles design and testbench, and runs simulation
.PHONY: all
all: compile sim

# Target: compile - Compiles design and testbench
.PHONY: compile
compile_prereqs = $(shell find $(RTL_PATH) -type f) \
                  $(shell find $(VERIF_PATH) -type f)
compile $(COMPILE_OUT): $(compile_prereqs)
ifeq ($(SIMULATOR), icarus)  # Icarus Verilog
	iverilog $(COMPILE_ARGS)
endif

# Target: sim     - Runs a simulation using selected simulator
.PHONY: sim
sim: $(COMPILE_OUT)
ifeq ($(SIMULATOR), icarus)  # Icarus Verilog
	vvp $(RUN_ARGS) $(COMPILE_OUT)
endif

# Target: clean   - Deletes logs and compilation/simulation artifacts
.PHONY: clean
clean:
	rm -f *.log
	rm -f $(COMPILE_OUT)
	rm -f *.vcd

# Target: help    - Lists each available make target and its purpose
.PHONY: help
help:
	grep "^# Target: " $(word 1, $(MAKEFILE_LIST))

# Target: debug   - Prints variables and their values, for debugging purposes
.PHONY: debug
debug:
	@echo "RTL_PATH      = $(RTL_PATH)"
	@echo "VERIF_PATH    = $(VERIF_PATH)"
	@echo "RTL_FILE_LIST = $(RTL_FILE_LIST)"
	@echo "VERIF_TB_HDR  = $(VERIF_TB_HDR)"
	@echo "SIMULATOR     = $(SIMULATOR)"
	@echo "COMPILE_ARGS  = $(COMPILE_ARGS)"
	@echo "COMPILE_OUT   = $(COMPILE_OUT)"
	@echo "RUN_ARGS      = $(RUN_ARGS)"

