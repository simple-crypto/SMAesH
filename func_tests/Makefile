# Makefile

NSHARES?=2
WORK?=$(shell pwd)/work
WORK_CASE?=$(WORK)/nshares_$(NSHARES)

RTL_DIR_HDL?=$(WORK_CASE)/smaesh_hdl_d$(NSHARES)

####### Verilator related
VERILATOR_MDIR=$(WORK_CASE)/verilator
VERILATOR_BUILD_PROC?=1

####### COCOTB related
# defaults
export SIM ?= verilator
export EXTRA_ARGS ?= -j $(VERILATOR_BUILD_PROC)
export TOPLEVEL_LANG ?= verilog
# Scratch directory
export SIM_BUILD ?= $(WORK_CASE)
# Sources related
export VERILOG_INCLUDE_DIRS?= $(RTL_DIR_HDL)
export VERILOG_SOURCES ?= $(RTL_DIR_HDL)/*.v $(RTL_DIR_HDL)/*.sv
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
export TOPLEVEL ?= smaesh_hpc
# MODULE is the basename of the Python test file
export MODULE ?= functionnal_tests
# Logging level
export COCOTB_LOG_LEVEL ?= INFO
# Results
export COCOTB_RESULTS_FILE = $(WORK_CASE)/result.xml

# include cocotb's make rules to take care of the simulator setup
COCOTB_DIR_MAKEFILES=$(shell cocotb-config --makefiles)

simu:
	make -f $(COCOTB_DIR_MAKEFILES)/Makefile.sim

clean:
	@if [ -d $(WORK_CASE) ]; then rm -r $(WORK_CASE); fi
	@if [ -d __pycache__ ]; then rm -r __pycache__; fi

