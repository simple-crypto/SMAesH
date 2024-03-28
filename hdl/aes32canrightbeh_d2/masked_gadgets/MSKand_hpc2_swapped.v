// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked AND HPC2 gadget with swapped inputs.
`ifdef FULLVERIF
(* fv_strat = "flatten", fv_order=d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKand_hpc2_swapped #(parameter d=`DEFAULTSHARES) (ina, inb, rnd, clk, out);

`include "MSKand_hpc2.vh"

(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina;
(* fv_type = "sharing", fv_latency = 1 *) input  [d-1:0] inb;
(* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = hpc2rnd *) input [hpc2rnd-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "sharing", fv_latency = 2 *) output [d-1:0] out;

MSKand_hpc2 #(.d(d)) inner(
    .ina(inb),
    .inb(ina),
    .rnd(rnd),
    .clk(clk),
    .out(out)
);

endmodule
