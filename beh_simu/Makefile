

NSHARES?=2
HDL_ROOT_DIR=../hdl
TB_TARGET?=tb_smaesh_hpc
TB_DIR=$(HDL_ROOT_DIR)/tb
TB_FILE=$(TB_DIR)/$(TB_TARGET).v

WORK_ROOT ?=work
WORK ?= ${WORK_ROOT}/nshares_${NSHARES}
WORK_HDL ?= $(WORK)/hdl
WORK_HDL_COMPRESS ?= $(WORK_HDL)/compress_gadgets

COMPRESS_ROOT =../sboxes-compress/compress

MODE ?= 128
TV_DIR=./tvs/files/aes${MODE}
DIR_GENERATED ?= tvs/generated
#TV_FILE_PREF=ECBGFSbox${MODE}
TV_FILE_PREF ?= ECBKeySbox${MODE}
#TV_FILE_PREF=ECBVarKey${MODE}
#TV_FILE_PREF?=ECBVarTxt${MODE}
#TV_FILE_PREF?=ECBdebug

###########################
KATIN=${TV_DIR}/${TV_FILE_PREF}.rsp
FN_TVIN ?= TV_${TV_FILE_PREF}_in.rsp
FN_TVOUT ?= TV_${TV_FILE_PREF}_out.rsp
TVIN=${DIR_GENERATED}/${FN_TVIN}
TVOUT=${DIR_GENERATED}/${FN_TVOUT}


DIR_SBOX=${HDL_ROOT_DIR}/sbox-d${NSHARES}
DIR_SBOX_COMPRESS=../sboxes-compress/work/circuits/canright_aes_sbox_dual_d${NSHARES}_l4

.PHONY: hdl-dir tv

help:
	@echo "Behavioral simulation of the masked core."
	@echo "make simu: run the simulation."
	@echo "make wave: open gtkwave."
	@echo "makefile parameter TB_TARGET: name of the tb module."
	@echo "makefile parameter TV_FILE_PREF: name of the KAT file to use for testvector (without extension)."

${TVIN}:
	mkdir -p ${DIR_GENERATED}
	python3 tvs/parse_KAT_for_TV.py \
	    --file-in ${KATIN} \
	    --dir-out ${DIR_GENERATED} \
	    --fn-in ${FN_TVIN} \
	    --fn-out ${FN_TVOUT} 

tv: ${TVIN}

simu: ${TVIN} simu-build
	vvp ${WORK}/simu-exec-$(TB_TARGET)

wave:
	gtkwave ${WORK}/log-$(TB_TARGET).vcd waves-$(TB_TARGET).gtkw

$(WORK_HDL):
	mkdir -p $(WORK_HDL)

hdl-dir: $(WORK_HDL)
	DIR_HDL=$(shell pwd)/$(WORK_HDL) make -C ${HDL_ROOT_DIR} gather

simu-build: hdl-dir
	cp $(TB_DIR)/* ${WORK}/hdl 
	iverilog \
	    -y ${WORK_HDL} \
	    -I ${WORK_HDL} \
	    -y ${WORK_HDL_COMPRESS} \
	    -I ${WORK_HDL_COMPRESS} \
	    -D TV_IN=\"${TVIN}\" \
	    -D TV_OUT=\"${TVOUT}\" \
	    -D KEY_SIZE=$(MODE)\
	    $(TB_FILE) \
	    -o ${WORK}/simu-exec-$(TB_TARGET) \
	    -D DUMPFILE=\"${WORK}/log-$(TB_TARGET).vcd\" \
	    -D NSHARES=$(NSHARES)\
	    -D behavioral

clean:
	if [ -d ${WORK_ROOT} ]; then rm -rf ${WORK_ROOT}; fi
	if [ -d tvs/generated ]; then rm -rf tvs/generated; fi


.PHONY: clean help wave simu-build simu tv
