

NSHARES?=2
HDL_ROOT_DIR=../hdl
HDL_SRC_DIR=$(HDL_ROOT_DIR)/aes_enc128_32bits_hpc
TB_TARGET?=tb_aes_enc128_32bits_hpc
TB_DIR=$(HDL_ROOT_DIR)/tb
TB_FILE=$(TB_DIR)/$(TB_TARGET).v
WORK_ROOT ?=work
WORK = ${WORK_ROOT}/nshares_${NSHARES}

TV_DIR=./tvs/files
DIR_GENERATED=tvs/generated
#TV_FILE_PREF=ECBGFSbox128
TV_FILE_PREF ?= ECBKeySbox128
#TV_FILE_PREF=ECBVarKey128
#TV_FILE_PREF?=ECBVarTxt128

###########################
KATIN=${TV_DIR}/${TV_FILE_PREF}.rsp
TVIN=${DIR_GENERATED}/TV_${TV_FILE_PREF}_in.rsp
TVOUT=${DIR_GENERATED}/TV_${TV_FILE_PREF}_out.rsp
DIR_SBOX=${HDL_ROOT_DIR}/sbox-d${NSHARES}

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

simu-build:
	mkdir -p ${WORK}
	OUT_DIR=${WORK}/hdl $(HDL_ROOT_DIR)/gather_sources.sh $(HDL_SRC_DIR) $(DIR_SBOX)
	cp $(TB_DIR)/* ${WORK}/hdl 
	iverilog \
	    -y ${WORK}/hdl \
	    -I ${WORK}/hdl \
	    -D TV_IN=\"${TVIN}\" \
	    -D TV_OUT=\"${TVOUT}\" \
	    $(TB_FILE) \
	    -o ${WORK}/simu-exec-$(TB_TARGET) \
	    -D DUMPFILE=\"${WORK}/log-$(TB_TARGET).vcd\" \
	    -D NSHARES=$(NSHARES)\
	    -D behavioral

clean:
	if [ -d ${WORK_ROOT} ]; then rm -rf ${WORK_ROOT}; fi
	if [ -d tvs/generated ]; then rm -rf tvs/generated; fi


.PHONY: clean help wave simu-build simu tv
