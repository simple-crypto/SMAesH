#!/bin/bash

## Source settings
NSHARES=${NSHARES:-2}
KEY_SIZE=${KEY_SIZE:-128}
HDL_ROOT_DIR=../hdl
DIR_MATCHI_ROOT=~/tools/fullverif

## Synthesis related
MAIN_MODULE=MSKaes_32bits_core
## Testbench related
DIR_BEH=../beh_simu
DIR_TB=$HDL_ROOT_DIR/tb
TB_MODULE=tb_MSKaes_32bits_core
TB_PATH=$DIR_TB/$TB_MODULE.v

WORK_DIR=$(pwd)/work

###################
# Reset the working directory
if [ -d $WORK_DIR ]; then rm -r $WORK_DIR; fi
mkdir -p $WORK_DIR

# Create the working HDL directory
WORK_DIR_HDL=$WORK_DIR/hdl
DIR_HDL=$WORK_DIR_HDL make -C $HDL_ROOT_DIR gather

####### Execution ########
#### Synthesis
SYNTH_LOG_FILE=$WORK_DIR/synth.log
echo "Starting synthesis..."
OUT_DIR=$WORK_DIR MAIN_MODULE=$MAIN_MODULE IMPLEM_DIR=$WORK_DIR_HDL NSHARES=$NSHARES DIR_MATCHI_ROOT=$DIR_MATCHI_ROOT ${YOSYS:=yosys} -c ./synth.tcl > $SYNTH_LOG_FILE || exit
echo "Synthesis finished."

#### Simulation
## Config for the simulation
SIM_PATH=$WORK_DIR/simu.out
VCD_PATH=$WORK_DIR/simu.vcd
SYNTH_BASE=$WORK_DIR/${MAIN_MODULE}_synth

## Create the testvector used
DIR_GENERATED=$WORK_DIR/tvs
FN_TVIN=in.rsp
FN_TVOUT=out.rsp
FN_TVIN=$FN_TVIN FN_TVOUT=$FN_TVOUT MODE=$KEY_SIZE DIR_GENERATED=$DIR_GENERATED make -C $DIR_BEH tv

# Full path to the tvs files generated
PATH_TV_IN=$DIR_GENERATED/$FN_TVIN
PATH_TV_OUT=$DIR_GENERATED/$FN_TVOUT

## Creating the simulation 
echo "Starting simulation..."
${IVERILOG:=iverilog} \
    -y $WORK_DIR_HDL \
    -y $DIR_TB \
    -I $WORK_DIR_HDL \
    -I $DIR_TB \
    -s $TB_MODULE \
    -o $SIM_PATH \
    -D TV_IN=\"$PATH_TV_IN\" \
    -D TV_OUT=\"$PATH_TV_OUT\" \
    -D DUMPFILE=\"$VCD_PATH\" \
    -D RUN_AM=1 \
    -D CONTINUOUS=1 \
    -D NSHARES=$NSHARES \
    -D KEY_SIZE=$KEY_SIZE \
    $SYNTH_BASE.v $TB_PATH || exit

## Simulate
${VVP:=vvp} $SIM_PATH
echo "Ending simulation..."

### Run matchi
$DIR_MATCHI_ROOT/matchi/target/release/matchi --json $SYNTH_BASE.json --vcd $VCD_PATH --dut $TB_MODULE.dut --gname $MAIN_MODULE



