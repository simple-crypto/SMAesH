# Use in order to use the compress-optimized sbox. 
NSHARES?=2
WORK?=work/d$(NSHARES)
WORKDIR=$(abspath $(WORK))

# Python Venv
SHELL=/bin/bash
VE=$(abspath $(WORKDIR)/ve)
VE_INSTALLED=$(VE)/installed
PYTHON_VE=source $(VE)/bin/activate

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

# Functionnal testing
FUNC_LOG=$(WORKDIR)/functests/simu.log
FUNC_SUCCESS=$(WORKDIR)/functests/success
$(FUNC_LOG): $(VE_INSTALLED) $(HDL_DONE)
	mkdir -p $(dir $(FUNC_LOG))
	$(PYTHON_VE); make -C func_tests NSHARES=$(NSHARES) WORK_CASE=$(WORKDIR)/functests RTL_DIR_HDL=$(DIR_HDL) simu | tee $@

# Mark simulation success (simulation always return a zero exit code).
%/success: %/simu.log
	grep -q -s FAIL=0 $< && touch $@ || exit 1

func-tests: $(FUNC_SUCCESS)


clean:
	if [ -d $(DIR_HDL) ]; then rm -r $(DIR_HDL); fi
