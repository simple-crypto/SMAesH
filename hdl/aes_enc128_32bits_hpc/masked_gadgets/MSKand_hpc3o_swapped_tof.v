// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked AND HPC2 gadget with swapped inputs (only cross-domain terms).
`ifdef FULLVERIF
(* fv_strat = "flatten", fv_order=d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKand_hpc3o_swapped_tof #(parameter d=`DEFAULTSHARES) (ina, inb, inb_prev, inc, rnd, clk, out);

`include "MSKand_hpc3.vh"

(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina;
(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] inb;
(* fv_type = "sharing", fv_latency = 1 *) input  [d-1:0] inb_prev;
(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] inc;
(* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = hpc3rnd *) input [hpc3rnd-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "sharing", fv_latency = 1 *) output [d-1:0] out;

MSKand_hpc3o_tof #(.d(d)) inner(
    .ina(inb),
    .ina_prev(inb_prev),
    .inb(ina),
    .inc(inc),
    .rnd(rnd),
    .clk(clk),
    .out(out)
);

endmodule
