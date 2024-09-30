# Makefile

NSHARES?=2
WORK?=$(shell pwd)/work
WORK_CASE?=$(WORK)/nshares_$(NSHARES)

RTL_DIR_HDL?=$(WORK_CASE)/smaesh_hdl_d$(NSHARES)

####### Verilator related
VERILATOR_MDIR=$(WORK_CASE)/verilator
VERILATOR_BUILD_PROC?=8

####### COCOTB related
# defaults
export SIM ?= icarus
#export EXTRA_ARGS ?= -Wno-NULLPORT -Wno-PINMISSING -Wno-WIDTH -j $(VERILATOR_BUILD_PROC)
export TOPLEVEL_LANG ?= verilog
# Scratch directory
export SIM_BUILD ?= $(WORK_CASE)
# Sources related
export VERILOG_INCLUDE_DIRS?= $(RTL_DIR_HDL)
export VERILOG_SOURCES ?= $(shell ls $(RTL_DIR_HDL)/*.v)
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
export TOPLEVEL ?= smaesh_hpc
# MODULE is the basename of the Python test file
export MODULE ?= functionnal_tests
# Logging level
export COCOTB_LOG_LEVEL ?= INFO

# include cocotb's make rules to take care of the simulator setup
COCOTB_DIR_MAKEFILES=$(shell cocotb-config --makefiles)

$(RTL_DIR_HDL):
	NSHARES=$(NSHARES) DIR_HDL=$(RTL_DIR_HDL) make -C ../hdl all

simu: $(RTL_DIR_HDL)
	make -f $(COCOTB_DIR_MAKEFILES)/Makefile.sim

clean:
	@if [ -d $(WORK_CASE) ]; then rm -r $(WORK_CASE); fi
	@if [ -d __pycache__ ]; then rm -r __pycache__; fi

