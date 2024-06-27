# Use yosys as a verilog parser and elaborator, to get a non-masked netlist of
# the Canright S-box.
set FILE_IN $::env(FILE_IN)
set FILE_OUT $::env(YOSYS_NETLIST)
yosys read_verilog $FILE_IN
yosys setattr -mod -set keep_hierarchy 1 G4_mul G16_mul 
yosys proc
yosys flatten
yosys techmap
yosys opt
yosys write_json -compat-int $FILE_OUT 
