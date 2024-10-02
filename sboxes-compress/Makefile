
WORK ?= work
MODULE_NAME ?= canright_aes_sbox_dual
YOSYS_NETLIST ?= $(WORK)/$(MODULE_NAME).json
CIRCUIT=$(WORK)/$(MODULE_NAME).txt
LAT ?= 4

NSHARES ?= 2

# Python Venv
SHELL=/bin/bash
VE=$(abspath $(WORK)/ve)
VE_INSTALLED=$(VE)/installed
PYTHON_VE=source $(VE)/bin/activate

RES_FILE? = $(WORK)/res/$(MODULE_NAME).v
RES_DIR = $(dir $(RES_FILE))
COMPRESS_FILE=$(WORK)/circuits/canright_aes_sbox_dual_d$(NSHARES)_l$(LAT)/design.v

YOSYS?=yosys

.PHONY: all

all: $(RES_FILE)

$(VE)/pyvenv.cfg:
	mkdir -p work
	python3 -m venv $(VE)

$(VE_INSTALLED): $(VE)/pyvenv.cfg
	${PYTHON_VE}; python -m pip install -r compress/requirements.txt
	touch $(VE_INSTALLED)

FILE_IN=canright_aes_sbox_dual.v
$(YOSYS_NETLIST): $(FILE_IN) build-json-yosys.tcl 
	mkdir -p $(WORK)
	FILE_IN=$(FILE_IN) YOSYS_NETLIST=$(YOSYS_NETLIST) $(YOSYS) -c build-json-yosys.tcl

$(CIRCUIT): $(VE_INSTALLED) $(YOSYS_NETLIST)
	${PYTHON_VE}; python compress/scripts/yosys2compress.py \
	    --netlist-file $(YOSYS_NETLIST) \
	    --top canright_aes_sbox_dual \
	    --compress-file $(CIRCUIT)

$(RES_FILE): $(VE_INSTALLED) $(CIRCUIT)
	${PYTHON_VE}; make -C compress CIRCUIT="$(abspath $(CIRCUIT))" LATS="$(LAT)" DS="$(NSHARES)" WORK=$(WORK) $(COMPRESS_FILE)
	mkdir -p $(RES_DIR)
	cp $(COMPRESS_FILE) $(RES_FILE)
	cp $(COMPRESS_FILE)h $(RES_FILE)h

