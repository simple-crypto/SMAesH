# Makefile

# Some setting of the run
NSHARES?=2
KEY_SIZE?=128
INVERSE?=0

# Path to the clone repo of matchi verification tool
# Prefix to the file matchi_cells.v and matchi_cells.lib
MATCHI_CELLS?=$(dir $(DIR_MATCHI_ROOT))matchi_cells
# Path to the mathci bin
MATCHI_BIN?=$(DIR_MATCHI_ROOT)/matchi/target/release/matchi

WORK?=work
WORKDIR?=$(dir $(WORK))$(WORK)

WORK_SYNTH=$(WORKDIR)/d$(NSHARES)-synth
WORK_CASE=$(WORKDIR)/d$(NSHARES)-KSIZE$(KEY_SIZE)-INVERSE$(INVERSE)

HDL_DIR?=./hdl # Expected to fail as is, passed from top level

####### Synthesis
### Synthesis related
SYNTH_LOG_FILE=$(WORK_SYNTH)/synth.log
SYNTH_MAIN_MODULE=MSKaes_32bits_core
SYNTH_NETLIST_JSON=$(WORK_SYNTH)/$(SYNTH_MAIN_MODULE)_synth.json
YOSYS?=yosys
SYNTH_SCRIPT=./synth.tcl
SYNTH_NETLIST_VERILOG=$(WORK_SYNTH)/$(SYNTH_MAIN_MODULE)_synth_noattr_renamed.v
$(SYNTH_NETLIST_JSON): 
	mkdir -p $(dir $(SYNTH_LOG_FILE))
	OUT_DIR=$(WORK_SYNTH) MAIN_MODULE=$(SYNTH_MAIN_MODULE) IMPLEM_DIR=$(HDL_DIR) NSHARES=$(NSHARES) MATCHI_CELLS=$(MATCHI_CELLS) $(YOSYS) -c $(SYNTH_SCRIPT) > $(SYNTH_LOG_FILE) || exit 1 

synth: $(SYNTH_NETLIST_JSON)

########### Behavioral simulation with cocotb
## used to generate the simulation vcd

####### COCOTB related
### Verilator related
VERILATOR_MDIR=$(WORK_CASE)/verilator
VERILATOR_BUILD_PROC?=1

# defaults
export SIM ?= verilator
export EXTRA_ARGS ?= -Wno-NULLPORT -Wno-PINMISSING -Wno-WIDTH -j $(VERILATOR_BUILD_PROC) --trace --trace-depth 3 --trace-structs -DCORE_SYNTHESIZED=1 -y $(HDL_DIR)
export TOPLEVEL_LANG ?= verilog
# Scratch directory
export SIM_BUILD ?= $(WORK_SYNTH)
# Sources related
export VERILOG_INCLUDE_DIRS?= $(HDL_DIR)
export VERILOG_SOURCES ?= $(SYNTH_NETLIST_VERILOG) $(HDL_DIR)/smaesh_hpc.v 
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
export TOPLEVEL ?= smaesh_hpc
# MODULE is the basename of the Python test file
export MODULE ?= matchi_simu
# Logging level
export COCOTB_LOG_LEVEL ?= INFO
# Results
export COCOTB_RESULTS_FILE = $(WORK_CASE)/result.xml

# Export custom env
export NSHARES
export KEY_SIZE
export INVERSE

# include cocotb's make rules to take care of the simulator setup
COCOTB_DIR_MAKEFILES=$(shell cocotb-config --makefiles)

### Rules for simulation
BEH_SIMU_LOG=$(WORK_CASE)/beh_simu.log
GEN_BEH_SIMU_VCD=dump.vcd
BEH_SIMU_VCD=$(WORK_CASE)/beh_simu.vcd

$(BEH_SIMU_LOG): $(SYNTH_NETLIST_JSON)
	mkdir -p $(WORK_CASE)
	make -f $(COCOTB_DIR_MAKEFILES)/Makefile.sim | tee $@

$(BEH_SIMU_VCD): $(BEH_SIMU_LOG)
	grep -q -s FAIL=0 $< && cp $(GEN_BEH_SIMU_VCD) $(BEH_SIMU_VCD) || exit 1

simu: $(BEH_SIMU_VCD)

### MATCHI RUN
MATCHI_VCD=$(WORK_CASE)/matchi.vcd
MATCHI_SUCCESS=$(WORK_CASE)/.matchi_success
MATCHI_LOG=$(WORK_CASE)/matchi_log

$(MATCHI_SUCCESS): $(BEH_SIMU_VCD)
	$(MATCHI_BIN) \
	    --json $(SYNTH_NETLIST_JSON) \
	    --vcd $(BEH_SIMU_VCD) \
	    --dut top.smaesh_hpc.aes_core \
	    --gname $(SYNTH_MAIN_MODULE) \
	    --output-vcd $(MATCHI_VCD) > $(MATCHI_LOG) 2> $(MATCHI_LOG).error && touch $(MATCHI_SUCCESS) || exit 1

matchi-run: $(MATCHI_SUCCESS)

clean:
	@if [ -d $(WORK_CASE) ]; then rm -r $(WORK_CASE); fi
	@if [ -d $(WORK_SYNTH) ]; then rm -r $(WORK_SYNTH); fi

