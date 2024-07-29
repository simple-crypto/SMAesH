

NSHARES?=2
HDL_ROOT_DIR=../hdl
HDL_SRC_DIR=$(HDL_ROOT_DIR)/aes_enc128_32bits_hpc
TB_TARGET?=tb_aes_enc128_32bits_hpc
TB_DIR=$(HDL_ROOT_DIR)/tb
TB_FILE=$(TB_DIR)/$(TB_TARGET).v

WORK_ROOT ?=work
WORK ?= ${WORK_ROOT}/nshares_${NSHARES}
WORK_HDL ?= $(WORK)/hdl
WORK_HDL_COMPRESS ?= $(WORK_HDL)/compress_gadgets

COMPRESS_ROOT =../sboxes-compress/compress

MODE ?= 128
TV_DIR=./tvs/files/aes${MODE}
DIR_GENERATED=tvs/generated
#TV_FILE_PREF=ECBGFSbox${MODE}
TV_FILE_PREF ?= ECBKeySbox${MODE}
#TV_FILE_PREF=ECBVarKey${MODE}
#TV_FILE_PREF?=ECBVarTxt${MODE}
#TV_FILE_PREF?=ECBdebug

###########################
KATIN=${TV_DIR}/${TV_FILE_PREF}.rsp
TVIN=${DIR_GENERATED}/TV_${TV_FILE_PREF}_in.rsp
TVOUT=${DIR_GENERATED}/TV_${TV_FILE_PREF}_out.rsp


DIR_SBOX=${HDL_ROOT_DIR}/sbox-d${NSHARES}
DIR_SBOX_COMPRESS=../sboxes-compress/work/circuits/canright_aes_sbox_dual_d${NSHARES}_l4


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
	    --dir-out ${DIR_GENERATED}

tv: ${TVIN}

simu: ${TVIN} simu-build
	vvp ${WORK}/simu-exec-$(TB_TARGET)

wave:
	gtkwave ${WORK}/log-$(TB_TARGET).vcd waves-$(TB_TARGET).gtkw

$(WORK_HDL):
	mkdir -p ${WORK_HDL}

hdl-dir: $(WORK_HDL)
	OUT_DIR=${WORK_HDL} $(HDL_ROOT_DIR)/gather_sources.sh $(HDL_SRC_DIR) $(DIR_SBOX) 
	mkdir -p ${WORK_HDL_COMPRESS}
	OUT_DIR=${WORK_HDL_COMPRESS} $(HDL_ROOT_DIR)/gather_sources.sh $(COMPRESS_ROOT)/gadget_library/BIN $(COMPRESS_ROOT)/gadget_library/MSK
	cp $(DIR_SBOX_COMPRESS)/canright_aes_sbox_dual.v ${WORK_HDL}
	cp $(DIR_SBOX_COMPRESS)/design.vh ${WORK_HDL}

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
