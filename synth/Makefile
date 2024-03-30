WORKDIR ?= work
NSHARES ?= 2
HDL_ROOT_DIR=../hdl
TOP_MODULE= aes_enc128_32bits_hpc
SYNTH_LIB= stdcells.lib  
SYNTH_SCRIPT= synth.tcl 
SBOX_DIR=${HDL_ROOT_DIR}/sbox-d${NSHARES}

SYNTH_DIR= $(WORKDIR)/synth_d$(NSHARES)
HDL_DIR= $(SYNTH_DIR)/hdl
RESDIR= $(SYNTH_DIR)/area 



.PHONY: clean

$(HDL_DIR):
	mkdir -p $(HDL_DIR)
	OUT_DIR=$(HDL_DIR) ../hdl/gather_sources.sh ${HDL_ROOT_DIR}/aes_enc128_32bits_hpc ${SBOX_DIR}

area: $(HDL_DIR)
	mkdir -p $(RESDIR)
	SYNTH_SRCS="$(shell ls $(HDL_DIR)/*.v)" VDEFINES="" VINCLUDE=$(HDL_DIR) SYNTH_TOP=$(TOP_MODULE) SYNTH_LIB=$(SYNTH_LIB) RESDIR=$(RESDIR) yosys -c $(SYNTH_SCRIPT) 

clean:
	if [ -d $(SYNTH_DIR) ]; then rm -r $(SYNTH_DIR); fi
