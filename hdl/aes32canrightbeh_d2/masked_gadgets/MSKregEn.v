// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked register with enable signal.
// Due to variable latency, this cannot be verified as an isolated block by
// fullVerif, hence we flatten it.
`ifdef FULLVERIF
(* fv_strat = "flatten" *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKregEn #(parameter d=`DEFAULTSHARES, parameter count=1) (clk, en, in, out);

input clk;
input en;
input  [count*d-1:0] in;
output [count*d-1:0] out;

wire [count*d-1:0] reg_in;

MSKmux #(.d(d), .count(count)) mux (.sel(en), .in_true(in), .in_false(out), .out(reg_in));
MSKreg #(.d(d), .count(count)) state_reg (.clk(clk), .in(reg_in), .out(out));

endmodule
