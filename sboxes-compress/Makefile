
WORK ?= work
MODULE_NAME ?= canright_aes_sbox_dual
YOSYS_NETLIST ?= $(WORK)/$(MODULE_NAME).json
CIRCUIT=$(WORK)/$(MODULE_NAME).txt
LATS ?= 4
DS ?= 2 3 4

AREA_REPORT = $(WORK)/$(MODULE_NAME)_area.csv

BEH_SIMU_TB ?= tb_sbox_dual.v 
BEH_SIMU_DIR ?= $(WORK)/beh-simu

.PHONY: all clean area

all: $(AREA_REPORT)

clean:
	-rm -r $(WORK) / 2> /dev/null

FILE_IN=canright_aes_sbox_dual.v
$(YOSYS_NETLIST): $(FILE_IN) build-json-yosys.tcl 
	mkdir -p $(WORK)
	FILE_IN=$(FILE_IN) YOSYS_NETLIST=$(YOSYS_NETLIST) yosys -c build-json-yosys.tcl

$(CIRCUIT): $(YOSYS_NETLIST)
	python compress/scripts/yosys2compress.py \
	    --netlist-file $(YOSYS_NETLIST) \
	    --top canright_aes_sbox_dual \
	    --compress-file $(CIRCUIT)

$(AREA_REPORT): $(CIRCUIT)
	make -C compress CIRCUIT="$(abspath $(CIRCUIT))" LATS="$(LATS)" DS="$(DS)" WORK=$(abspath $(WORK)) area

$(BEH_SIMU_DIR):
	mkdir -p $(BEH_SIMU_DIR)

beh-simu-umsk: $(BEH_SIMU_DIR)
	iverilog tb_sbox_dual.v -y . -o $(BEH_SIMU_DIR)/umsk.out && vvp $(BEH_SIMU_DIR)/umsk.out 


area: $(AREA_REPORT)
