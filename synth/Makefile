GWORKDIR ?= $(shell pwd)/work
NSHARES ?= 2

HDL_ROOT_DIR=../hdl
TOP_MODULE=smaesh_hpc
SYNTH_LIB=stdcells.lib  
SYNTH_SCRIPT=synth.tcl 

######
CASE_WDIR=$(GWORKDIR)/nshares_$(NSHARES)
CASE_HDL_DIR=$(CASE_WDIR)/hdl
CASE_SYNTH_DIR=$(CASE_WDIR)/synth

$(CASE_WDIR):
	mkdir -p $(CASE_WDIR)

$(CASE_HDL_DIR): $(CASE_WDIR)
	DIR_HDL=$(CASE_HDL_DIR) make -C $(HDL_ROOT_DIR) gather

$(CASE_SYNTH_DIR):
	mkdir -p $(CASE_SYNTH_DIR)

synth: $(CASE_HDL_DIR) $(CASE_SYNTH_DIR)
	SYNTH_SRCS="$(shell ls $(CASE_HDL_DIR)/*.v)" VDEFINES="" VINCLUDE=$(CASE_HDL_DIR) SYNTH_TOP=$(TOP_MODULE) SYNTH_LIB=$(SYNTH_LIB) RESDIR=$(CASE_SYNTH_DIR) yosys -c $(SYNTH_SCRIPT)

clean:
	if [ -d $(CASE_WDIR) ]; then rm -r $(CASE_WDIR); fi
