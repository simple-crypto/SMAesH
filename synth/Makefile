WORKDIR ?= work
NSHARES ?= 2
HDL_ROOT_DIR=../hdl
TOP_MODULE= aes_enc128_32bits_hpc
SYNTH_LIB= stdcells.lib  
SYNTH_SCRIPT= synth.tcl 
SBOX_DIR=${HDL_ROOT_DIR}/sbox-d${NSHARES}

SYNTH_DIR= ${WORKDIR}/synth_d${NSHARES}
HDL_DIR= ${SYNTH_DIR}/hdl
RESDIR=${SYNTH_DIR}/area 

# Simu related
TB_DIR=$(HDL_ROOT_DIR)/tb
TB_MODULE=tb_aes_enc128_32bits_hpc
TV_FILE_PREF=ECBGFSbox128
SIMU_WORK_DIR=$(SYNTH_DIR)/simu
SIMU_HDL_DIR=$(SIMU_WORK_DIR)/hdl
BEH_SIMU_DIR=../beh_simu
TVIN=${BEH_SIMU_DIR}/tvs/generated/TV_${TV_FILE_PREF}_in.rsp
TVOUT=${BEH_SIMU_DIR}/tvs/generated/TV_${TV_FILE_PREF}_out.rsp
SINGLE_FILE_MODULE=smaesh_v2_d${NSHARES}.v
SIMU_TB_HDL_DIR=${SIMU_WORK_DIR}/tb-hdl
.PHONY: clean

$(HDL_DIR):
	mkdir -p $(HDL_DIR)
	OUT_DIR=$(HDL_DIR) ../hdl/gather_sources.sh ${HDL_ROOT_DIR}/aes_enc128_32bits_hpc ${SBOX_DIR}

area: $(HDL_DIR)
	mkdir -p $(RESDIR)
	SYNTH_SRCS="$(shell ls $(HDL_DIR)/*.v)" VDEFINES="" VINCLUDE=$(HDL_DIR) SYNTH_TOP=$(TOP_MODULE) SYNTH_LIB=$(SYNTH_LIB) RESDIR=$(RESDIR) yosys -c $(SYNTH_SCRIPT) 

synth-simu-build: 
	TV_FILE_PREF=$(TV_FILE_PREF) make -C ${BEH_SIMU_DIR} tv
	mkdir -p $(SIMU_HDL_DIR)
	mkdir -p $(SIMU_TB_HDL_DIR)
	cp stdcells.v $(SIMU_HDL_DIR)
	cp ${SYNTH_DIR}/area/design.v  ${SIMU_HDL_DIR}/${SINGLE_FILE_MODULE}
	cp ${TB_DIR}/* ${SIMU_TB_HDL_DIR}
	cp ${HDL_ROOT_DIR}/aes_enc128_32bits_hpc/masked_gadgets/shares2shbus.v ${SIMU_TB_HDL_DIR}
	cp ${HDL_ROOT_DIR}/aes_enc128_32bits_hpc/masked_gadgets/shbus2shares.v ${SIMU_TB_HDL_DIR}
	iverilog \
		-y ${SIMU_HDL_DIR} \
		-I ${SIMU_HDL_DIR} \
		-y ${SIMU_TB_HDL_DIR} \
		-I ${SIMU_TB_HDL_DIR} \
		-o ${SIMU_WORK_DIR}/simu-exec \
		-D DUMPFILE=\"${SIMU_WORK_DIR}/log.vcd\" \
		-D NSHARES=${NSHARES} \
		-D TV_IN=\"${TVIN}\" \
		-D TV_OUT=\"${TVOUT}\" \
		${SIMU_HDL_DIR}/stdcells.v \
		${SIMU_HDL_DIR}/${SINGLE_FILE_MODULE} \
		${SIMU_TB_HDL_DIR}/${TB_MODULE}.v 

simu: area synth-simu-build
	vvp ${SIMU_WORK_DIR}/simu-exec

clean:
	if [ -d $(SYNTH_DIR) ]; then rm -r $(SYNTH_DIR); fi
