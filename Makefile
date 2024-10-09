# Use in order to use the compress-optimized sbox. 
NSHARES?=2
WORK?=work/d$(NSHARES)
WORKDIR=$(abspath $(WORK))

# Python Venv
SHELL=/bin/bash
VE=$(abspath $(WORKDIR)/ve)
VE_INSTALLED=$(VE)/installed
PYTHON_VE=source $(VE)/bin/activate

### HDL configuration
# Directory created containing all the HDL files
DIR_HDL?=$(WORKDIR)/hdl
HDL_DONE = $(DIR_HDL)/.gather

# path where the COMPRESS tool is located (root of the git)
DIR_COMPRESS_ROOT?=./sboxes-compress/compress

##################"
COMPRESS_WORKDIR=$(WORKDIR)/compress
SBOX_FILE=$(WORKDIR)/sbox/canright_aes_sbox_dual.v

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

$(SBOX_FILE): sboxes-compress/canright_aes_sbox_dual.v
	cd sboxes-compress; SBOX_FILE=$(SBOX_FILE) WORK=$(COMPRESS_WORKDIR) NSHARES=$(NSHARES) ./compress.sh

sbox: $(SBOX_FILE)

$(HDL_DONE): $(SBOX_FILE)
	OUT_DIR=${DIR_HDL} ./gather_sources.sh $(DIR_SMAESH_HDL) $(DIR_COMPRESS_GADGETS)/BIN $(DIR_COMPRESS_GADGETS)/MSK
	cp $(SBOX_FILE) $(SBOX_FILE)h $(DIR_HDL)
	echo "\`define DEFAULTSHARES ${NSHARES}" > $(DIR_HDL)/architecture_default.vh
	touch $(HDL_DONE)

hdl: $(HDL_DONE)

## Functionnal testing
FUNC_LOG=$(WORKDIR)/functests/simu.log
FUNC_SUCCESS=$(WORKDIR)/functests/success
$(FUNC_LOG): $(VE_INSTALLED) $(HDL_DONE)
	mkdir -p $(dir $(FUNC_LOG))
	$(PYTHON_VE); make -C func_tests NSHARES=$(NSHARES) WORK_CASE=$(WORKDIR)/functests RTL_DIR_HDL=$(DIR_HDL) simu | tee $@

# Mark simulation success (simulation always return a zero exit code).
%/success: %/simu.log
	grep -q -s FAIL=0 $< && touch $@ || exit 1

func-tests: $(FUNC_SUCCESS)

## Formal composition verification using matchi (SCA security)
KEY_SIZE = 128 192 256
DIR_FORMAL_VERIF=$(WORKDIR)/formal-verif

### Matchi configuration
# Path to the clone repo of matchi verification tool
# Prefix to the file matchi_cells.v and matchi_cells.lib
MATCHI_CELLS?=$(DIR_MATCHI_ROOT)/matchi_cells
# Path to the mathci bin
MATCHI_BIN?=$(DIR_MATCHI_ROOT)/matchi/target/release/matchi

matchi_configured: 
	@set e; if [ -z $${DIR_MATCHI_ROOT+x} ]; then echo "DIR_MATCHI_ROOT must be set for formal verification" && exit 1; else echo "DIR_MATCHI_ROOT=${DIR_MATCHI_ROOT}"; fi

FORMAL_VERIF_DONE=$(DIR_FORMAL_VERIF)/.formal_verif
$(FORMAL_VERIF_DONE): $(VE_INSTALLED) $(HDL_DONE) matchi_configured
	# Verify encryption
	$(foreach ksize,$(KEY_SIZE),$(PYTHON_VE); make -C ./formal_verif NSHARES=$(NSHARES) KEY_SIZE=$(ksize) INVERSE=0 MATCHI_CELLS=$(MATCHI_CELLS) MATCHI_BIN=$(MATCHI_BIN) WORKDIR=$(DIR_FORMAL_VERIF) HDL_DIR=$(DIR_HDL) matchi-run || exit 1;)
	# Verify decryption
	$(foreach ksize,$(KEY_SIZE),$(PYTHON_VE); make -C ./formal_verif NSHARES=$(NSHARES) KEY_SIZE=$(ksize) INVERSE=1 MATCHI_CELLS=$(MATCHI_CELLS) MATCHI_BIN=$(MATCHI_BIN) WORKDIR=$(DIR_FORMAL_VERIF) HDL_DIR=$(DIR_HDL) matchi-run || exit 1;)
	touch $(FORMAL_VERIF_DONE)

formal-tests: $(FORMAL_VERIF_DONE)

### Linting check
LINT_SUCCESS=$(DIR_HDL)/.lint-success

$(LINT_SUCCESS): $(HDL_DONE)
	@set e; (cd $(DIR_HDL) && verilator --lint-only smaesh_hpc.v && touch $(LINT_SUCCESS) || exit 1)  

lint-tests: $(LINT_SUCCESS)

clean:
	if [ -d $(WORKDIR) ]; then rm -r $(WORKDIR); fi
