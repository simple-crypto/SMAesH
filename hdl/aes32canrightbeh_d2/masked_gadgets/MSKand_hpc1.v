// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked AND HPC1 gadget.
`ifdef FULLVERIF
(* fv_prop = "PINI", fv_strat = "assumed", fv_order=d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKand_hpc1 #(parameter d=`DEFAULTSHARES) (ina, inb, rnd, clk, out);

`include "MSKand_hpc1.vh"

(* fv_type = "sharing", fv_latency = 1+ref_rndlat *) input  [d-1:0] ina;
(* fv_type = "sharing", fv_latency = ref_rndlat *) input  [d-1:0] inb;
(* fv_type = "sharing", fv_latency = 2+ref_rndlat *) output [d-1:0] out;
(* fv_type = "clock" *) input clk;
(* fv_type = "random", fv_count=2, fv_rnd_lat_0=0, fv_rnd_count_0=ref_n_rnd, fv_rnd_lat_1=1+ref_rndlat, fv_rnd_count=dom_rnd *)
input [hpc1rnd-1:0] rnd;

wire [d-1:0] inb_ref;

wire [ref_n_rnd-1:0] rnd_ref;
assign rnd_ref = rnd[ref_n_rnd-1:0];

wire [dom_rnd-1:0] rnd_mul;
assign rnd_mul = rnd[hpc1rnd-1:ref_n_rnd];

MSKref_sni #(.d(d)) rfrsh (.in(inb), .clk(clk), .out(inb_ref), .rnd(rnd_ref));
MSKand_dom #(.d(d)) mul (.ina(ina), .inb(inb_ref), .clk(clk), .rnd(rnd_mul), .out(out));

endmodule
