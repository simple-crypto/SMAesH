// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Mask a non-sentitive variable x into a sharing (x, 0, ..., 0)
`ifdef FULLVERIF
(* fv_prop = "affine", fv_strat = "isolate", fv_order = d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKcst #(parameter d=`DEFAULTSHARES, parameter count=1) (cst, out);

(* fv_type = "control" *)       input [count-1:0] cst;
(* fv_type = "sharing", fv_count = count, fv_latency = 0 *) output [count*d-1:0] out;

genvar i;
for(i=0; i<count; i=i+1) begin: i_gen_m
    assign out[i*d +: d] = {{(d-1){1'b0}}, cst[i]};
end

endmodule
