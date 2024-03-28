(* fv_strat="flatten" *)
module gen_bp_sbox
#
(
    parameter d=2
)
(
    	// Circuit inputs IOs
	clk,
	i0,
	i1,
	i2,
	i3,
	i4,
	i5,
	i6,
	i7,
	rnd_bus0w,
	rnd_bus1w,
	rnd_bus2w,
`ifdef CANRIGHT_SBOX
        rnd_bus3w,
`endif
	// Circuit outputs IOs
	o0,
	o1,
	o2,
	o3,
	o4,
	o5,
	o6,
	o7
);



`include "design.vh"

// Inputs ports
input clk;
input [d-1:0] i0;
input [d-1:0] i1;
input [d-1:0] i2;
input [d-1:0] i3;
input [d-1:0] i4;
input [d-1:0] i5;
input [d-1:0] i6;
input [d-1:0] i7;
input [rnd_bus0-1:0] rnd_bus0w;
input [rnd_bus1-1:0] rnd_bus1w;
input [rnd_bus2-1:0] rnd_bus2w;
`ifdef CANRIGHT_SBOX
input [rnd_bus3-1:0] rnd_bus3w;
`endif

// Outputs ports
output [d-1:0] o0;
output [d-1:0] o1;
output [d-1:0] o2;
output [d-1:0] o3;
output [d-1:0] o4;
output [d-1:0] o5;
output [d-1:0] o6;
output [d-1:0] o7;

// Generate in order to mux on the instance to use
`ifdef CANRIGHT_SBOX
canright #(.d(d)) sb_inst(
`else
aes_bp #(.d(d)) sb_inst(
`endif
    .clk(clk),
    .i0(i0),
    .i1(i1),
    .i2(i2),
    .i3(i3),
    .i4(i4),
    .i5(i5),
    .i6(i6),
    .i7(i7),
    .rnd_0(rnd_bus0w),
    .rnd_1(rnd_bus1w),
    .rnd_2(rnd_bus2w),
`ifdef CANRIGHT_SBOX
    .rnd_3(rnd_bus3w),
`endif
    .o0(o0),
    .o1(o1),
    .o2(o2),
    .o3(o3),
    .o4(o4),
    .o5(o5),
    .o6(o6),
    .o7(o7)
);

endmodule
