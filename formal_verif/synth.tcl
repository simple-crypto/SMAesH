set IMPLEM_DIR $::env(IMPLEM_DIR)
set MAIN_MODULE $::env(MAIN_MODULE)
set OUT_DIR $::env(OUT_DIR)

set MAIN_PATH $IMPLEM_DIR/$MAIN_MODULE.v
set MATCHI_DIR $::env(DIR_MATCHI_ROOT)
set LIB $MATCHI_DIR/matchi_cells
set LIB_V $LIB.v
set LIB $LIB.lib

# Read verilog, load sub-modules and build the hierarchy.
yosys verilog_defaults -add -I$IMPLEM_DIR -DMATCHI=1
yosys read_verilog $MAIN_PATH
yosys hierarchy -check -libdir $IMPLEM_DIR -top $MAIN_MODULE

# Remove verilog high-level constructs, in favor of netlists
yosys proc;
# Map yosys RTL library to yosys Gate library.
yosys techmap
# Map gates to our "matchi_cells" library.
yosys dfflibmap -liberty $LIB
yosys abc -liberty $LIB
yosys clean

# Include our gate library in the netlist.
# This procedure is done to have the correct "port_directions" attribute on the
# cells.
yosys read_verilog $LIB_V
yosys proc
yosys hierarchy -check -top $MAIN_MODULE

# Output the result in verilog (for simulation) and json (for analysis).
yosys write_json $OUT_DIR/${MAIN_MODULE}_synth.json

yosys write_verilog -norename $OUT_DIR/${MAIN_MODULE}_synth.v;
yosys write_verilog -noattr -norename $OUT_DIR/${MAIN_MODULE}_synth_noattr.v;
yosys write_verilog -attr2comment -norename $OUT_DIR/${MAIN_MODULE}_synth_attr2comment.v;


