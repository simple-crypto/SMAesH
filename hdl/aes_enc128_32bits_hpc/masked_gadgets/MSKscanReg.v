// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked register with enable signal and input mux.
// Due to variable latency, this cannot be verified as an isolated block by
// fullVerif, hence we flatten it.
(* fv_strat = "flatten" *)
module MSKscanReg #(parameter d=1, parameter count=1) (clk, en, scan_en, in_d, in_scan, out_q);

input clk;
input en;
input scan_en;
input  [count*d-1:0] in_d;
input  [count*d-1:0] in_scan;
output [count*d-1:0] out_q;

wire [count*d-1:0] reg_in;
MSKmux #(.d(d), .count(count)) mux (.sel(scan_en), .in_true(in_scan), .in_false(in_d), .out(reg_in));
MSKregEn #(.d(d), .count(count)) regen (.clk(clk), .en(en), .in(reg_in), .out(out_q));

endmodule
