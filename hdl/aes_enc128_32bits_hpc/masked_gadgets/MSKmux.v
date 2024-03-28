// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked 2-input MUX (non-sensitive control signal).
`ifdef FULLVERIF
(* fv_prop = "_mux", fv_strat = "assumed", fv_order = d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKmux #(parameter d=`DEFAULTSHARES, parameter count=1) (sel, in_true, in_false, out);

(* fv_type = "control" *) input sel;
(* fv_type = "sharing", fv_latency = 0, fv_count=count *) input  [count*d-1:0] in_true;
(* fv_type = "sharing", fv_latency = 0, fv_count=count *) input  [count*d-1:0] in_false;
(* fv_type = "sharing", fv_latency = 0, fv_count=count *) output [count*d-1:0] out;

assign out = sel ? in_true : in_false;

endmodule
