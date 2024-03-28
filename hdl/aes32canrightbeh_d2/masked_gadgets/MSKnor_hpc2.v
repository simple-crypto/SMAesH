(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module MSKnor_hpc2 #(parameter d=2) (ina, inb, rnd, clk, out);

`include "MSKand_hpc2.vh"

(* syn_keep = "true", keep = "true", fv_type = "sharing", fv_latency = 1 *) input  [d-1:0] ina;
(* syn_keep = "true", keep = "true", fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] inb;
(* syn_keep = "true", keep = "true", fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = hpc2rnd *) input [hpc2rnd-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "sharing", fv_latency = 2 *) output [d-1:0] out;

wire [d-1:0] not_a, not_b;

MSKinv #(.d(d)) nota (.in(ina), .out(not_a));
MSKinv #(.d(d)) notb (.in(inb), .out(not_b));
MSKand_hpc2 #(.d(d)) andg (.ina(not_a), .inb(not_b), .rnd(rnd), .clk(clk), .out(out));

endmodule
