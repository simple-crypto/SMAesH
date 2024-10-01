# Use in order to use the compress-optimized sbox. 
NSHARES?=2
WORK?=work/d$(NSHARES)
WORKDIR=$(abspath $(WORK))

# Python Venv
SHELL=/bin/bash
VE=$(abspath $(WORKDIR)/ve)
VE_INSTALLED=$(VE)/installed
PYTHON_VE=source $(VE)/bin/activate

### Matchi configuration
# Path to the clone repo of matchi verification tool
DIR_MATCHI_ROOT?=$(dir ~/tools/)matchi
# Prefix to the file matchi_cells.v and matchi_cells.lib
MATCHI_CELLS?=$(DIR_MATCHI_ROOT)/matchi_cells
# Path to the mathci bin
MATCHI_BIN?=$(DIR_MATCHI_ROOT)/matchi/target/release/matchi

### HDL configuration
# Directory created containing all the HDL files
DIR_HDL?=$(WORKDIR)/hdl
HDL_DONE = $(DIR_HDL)/.gather

# path where the COMPRESS tool is located (root of the git)
DIR_COMPRESS_ROOT?=./sboxes-compress/compress

##################"
COMPRESS_WORKDIR=$(WORKDIR)/sbox
SBOX_FILE=$(COMPRESS_WORKDIR)/circuits/canright_aes_sbox_dual_d$(NSHARES)_l4/design.v

DIR_COMPRESS_GADGETS=$(DIR_COMPRESS_ROOT)/gadget_library
DIR_SMAESH_HDL=hdl/smaesh_hpc

.PHONY: sbox hdl

## Python venv setting
$(VE)/pyvenv.cfg:
	mkdir -p $(WORKDIR)
	python3 -m venv $(VE)

$(VE_INSTALLED): $(VE)/pyvenv.cfg
	${PYTHON_VE}; python -m pip install -r func_tests/requirements.txt
	touch $(VE_INSTALLED)

## Sbox generation with compress
$(SBOX_FILE):
	make -C sboxes-compress WORK=$(COMPRESS_WORKDIR) DS=$(NSHARES) 

sbox: $(SBOX_FILE)

## HDL directory building
$(HDL_DONE): $(SBOX_FILE) 
	OUT_DIR=${DIR_HDL} ./gather_sources.sh $(DIR_SMAESH_HDL) $(DIR_COMPRESS_GADGETS)/BIN $(DIR_COMPRESS_GADGETS)/MSK
	cp $(SBOX_FILE) $(DIR_HDL)/canright_aes_sbox_dual.v
	cp $(dir $(SBOX_FILE))/design.vh $(DIR_HDL)
	echo "\`define DEFAULTSHARES ${NSHARES}" > $(DIR_HDL)/architecture_default.vh
	touch $(HDL_DONE)

hdl: $(HDL_DONE)

## Functionnal testing
FUNC_LOG=$(WORKDIR)/functests/simu.log
FUNC_SUCCESS=$(WORKDIR)/functests/success
$(FUNC_LOG): $(VE_INSTALLED) $(HDL_DONE)
	mkdir $(dir $(FUNC_LOG))
	$(PYTHON_VE); make -C func_tests NSHARES=$(NSHARES) WORK_CASE=$(WORKDIR)/functests RTL_DIR_HDL=$(DIR_HDL) simu | tee $@

# Mark simulation success (simulation always return a zero exit code).
%/success: %/simu.log
	grep -q -s FAIL=0 $< && touch $@ || exit 1

func-tests: $(FUNC_SUCCESS)

## Formal composition verification using matchi (SCA security)
DIR_FORMAL_VERIF=$(WORKDIR)/formal-verif
formal-tests: $(DIR_HDL)
	$(PYTHON_VE); make -C ./formal_verif NSHARES=$(NSHARES) MATCHI_CELLS=$(MATCHI_CELLS) MATCHI_BIN=$(MATCHI_BIN) WORKDIR=$(DIR_FORMAL_VERIF) HDL_DIR=$(DIR_HDL) matchi-run


clean:
	if [ -d $(WORKDIR) ]; then rm -r $(WORKDIR); fi
