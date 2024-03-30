#!/bin/bash

## Source settings
HDL_ROOT_DIR=../hdl
HDL_SRC_DIR=$HDL_ROOT_DIR/aes_enc128_32bits_hpc
TB_MODULE=tb_aes_enc128_32bits_hpc
TB_DIR=$HDL_ROOT_DIR/tb
TB_PATH=$TB_DIR/$TB_MODULE.v
MAIN_MODULE=MSKaes_32bits_core
# signal starting the first simulation cycle (i.e. latency == 0 for the main module), name in the testbench
IN_VALID=dut.aes_valid_in
# clock signal (in the testbench)
CLOCK=clk
# name of the instance of the main module in the testbench
DUT=dut.aes_core

## workdir
HDL_DIR=work/hdl
VCD_PATH=work/a.vcd
SIM_PATH=work/beh-simu
SYNTH_BASE=work/${MAIN_MODULE}_synth

# Prepare sources
rm -rf work
mkdir -p work
OUT_DIR=$HDL_DIR $HDL_ROOT_DIR/gather_sources.sh $HDL_SRC_DIR
# NB: we use the convention that module X is always in file X.v in this script


####### Execution #######
echo "Starting synthesis..."
OUT_DIR=work MAIN_MODULE=$MAIN_MODULE IMPLEM_DIR=$HDL_DIR ${YOSYS:=yosys} -c ./msk_presynth.tcl || exit
echo "Synthesis finished."

echo "Generating TV..."
TV_FILE_PREF=ECBGFSbox128
TV=tvs/generated/TV_$TV_FILE_PREF
TV_IN=${TV}_in.rsp
TV_OUT=${TV}_out.rsp
BEH_SIMU_DIR=../beh_simu
TV_IN=$BEH_SIMU_DIR/$TV_IN
TV_OUT=$BEH_SIMU_DIR/$TV_OUT

TV_FILE_PREF=$TV_FILE_PREF make -C $BEH_SIMU_DIR tv

echo "Starting simulation..."
# Change this if you want to use another simulator
# -y source directory for .v modules
# -s top-level module (i.e. testbench)
${IVERILOG:=iverilog} \
    -y $HDL_DIR \
    -y $TB_DIR \
    -I $HDL_DIR \
    -I $TB_DIR \
    -s $TB_MODULE \
    -o $SIM_PATH \
    -D TV_IN=\"$TV_IN\" \
    -D TV_OUT=\"$TV_OUT\" \
    -D DUMPFILE=\"$VCD_PATH\" \
    -D CORE_SYNTHESIZED=1 \
    -D RUN_AM=1 \
    -D FULLVERIF=1 \
    $SYNTH_BASE.v $TB_PATH || exit
    #-y $FULLVERIF_LIB_DIR \
    #-I $FULLVERIF_LIB_DIR \
${VVP:=vvp} $SIM_PATH
echo "Simulation finished"

echo "Starting fullverif..."
FV_CMDLINE="${FULLVERIF:=fullverif} --json $SYNTH_BASE.json --vcd $VCD_PATH --tb $TB_MODULE --gname $MAIN_MODULE --in-valid $IN_VALID --clock $CLOCK --dut $DUT"
echo "$FV_CMDLINE"
$FV_CMDLINE
