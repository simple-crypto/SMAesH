

PYTHON_VERSION?=3.12
UV_EXEC?=uv
WORK ?= work-python$(PYTHON_VERSION)
MODULE_NAME ?= canright_aes_sbox_dual
YOSYS_NETLIST ?= $(WORK)/$(MODULE_NAME).json
CIRCUIT=$(WORK)/$(MODULE_NAME).txt
LAT ?= 4

NSHARES ?= 2

# Python Venv
SHELL=/bin/bash
VE=$(abspath $(WORK)/ve)
VE_INSTALLED=$(VE)/installed
ACTIVATE_VE=$(VE)/bin/activate

RES_FILE? = $(WORK)/res/$(MODULE_NAME).v
RES_DIR = $(dir $(RES_FILE))
COMPRESS_FILE=$(WORK)/circuits/canright_aes_sbox_dual_d$(NSHARES)_l$(LAT)/design.v

YOSYS?=yosys

.PHONY: all

all: $(RES_FILE)


$(VE)/pyvenv.cfg:
	set -e; (mkdir -p work && $(UV_EXEC) venv $(VE) -p $(PYTHON_VERSION)) || exit 1

$(VE_INSTALLED): $(VE)/pyvenv.cfg
	set -e; (source ${ACTIVATE_VE} && $(UV_EXEC) pip install -r compress/requirements.txt) || exit 1

FILE_IN=canright_aes_sbox_dual.v
$(YOSYS_NETLIST): $(FILE_IN) build-json-yosys.tcl 
	mkdir -p $(WORK)
	FILE_IN=$(FILE_IN) YOSYS_NETLIST=$(YOSYS_NETLIST) $(YOSYS) -c build-json-yosys.tcl

$(CIRCUIT): $(YOSYS_NETLIST) | $(VE_INSTALLED) 
	set -e; (source ${ACTIVATE_VE} && python compress/scripts/yosys2compress.py \
	    --netlist-file $(YOSYS_NETLIST) \
	    --top canright_aes_sbox_dual \
	    --compress-file $(CIRCUIT)) || exit 1

$(RES_FILE): $(CIRCUIT) | $(VE_INSTALLED) 
	set -e;(source ${ACTIVATE_VE} && make -C compress CIRCUIT="$(abspath $(CIRCUIT))" LATS="$(LAT)" DS="$(NSHARES)" WORK=$(WORK) $(COMPRESS_FILE)) || exit 1
	mkdir -p $(RES_DIR)
	cp $(COMPRESS_FILE) $(RES_FILE)
	cp $(COMPRESS_FILE)h $(RES_FILE)h

