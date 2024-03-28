// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked XOR gate.
`ifdef FULLVERIF
(* fv_prop = "affine", fv_strat = "composite", fv_order = d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKxnor #(parameter d=`DEFAULTSHARES, parameter count=1) (ina, inb, out);

(* fv_type = "sharing", fv_latency = 0, fv_count=count *) input  [count*d-1:0] ina, inb;
(* fv_type = "sharing", fv_latency = 0, fv_count=count *) output [count*d-1:0] out;

wire [count*d-1:0] tmp;

MSKxor #(.d(d), .count(count)) xorg(.ina(ina), .inb(inb), .out(tmp));
MSKinv #(.d(d)) notg (.in(tmp), .out(out));

endmodule
