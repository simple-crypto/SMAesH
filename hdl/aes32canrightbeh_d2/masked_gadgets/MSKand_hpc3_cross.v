// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked AND HPC3 gadget (only corss-domain terms).
`ifdef FULLVERIF
(* fv_prop = "PINI", fv_strat = "assumed", fv_order=d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKand_hpc3_cross #(parameter d=`DEFAULTSHARES) (ina, inb, rnd, clk, out);

`include "MSKand_hpc3.vh"
localparam mat_rnd = hpc3rnd/2;

(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina;
(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] inb;
(* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = hpc3rnd *) input [hpc3rnd-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "random", fv_type = "sharing", fv_latency = 1 *) output [d-1:0] out;
                                      
wire [d-1:0] ina_prev;
bin_REG #(.W(d)) REGin_ina_prev (
    .clk(clk),
    .in(ina),
    .out(ina_prev)
);

MSKand_hpc3_cross_er #(.d(d)) inner(ina, ina_prev, inb, rnd, clk, out);

endmodule
