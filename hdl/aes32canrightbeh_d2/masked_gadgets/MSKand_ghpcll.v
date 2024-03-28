// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked AND2 GHPC gadget.
`ifdef FULLVERIF
(* fv_prop = "PINI", fv_strat = "assumed", fv_order=2 *)
`endif
module MSKand_ghpcll #(parameter d=2) (ina, inb, rnd, clk, out);

generate
if (d != 2) begin
    // Invalid parameter.
    inst_irrelevant_d parameter_d_must_be_2();
end
endgenerate

(* fv_type = "sharing", fv_latency = 0 *) input  [1:0] ina;
(* fv_type = "sharing", fv_latency = 0 *) input  [1:0] inb;
(* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = 4 *) input [4-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "random", fv_type = "sharing", fv_latency = 1 *) output [1:0] out;

wire a0 = ina[0];
wire b0 = inb[0];
wire a1 = ina[1];
wire b1 = inb[1];

wire [4-1:0] fx1 = {~a0 & ~b0, ~a0 ^ b0, a0 & ~b0, a0 & b0};
reg [4-1:0] r_fx1;
always @(posedge clk) begin
    r_fx1 <= fx1 ^ rnd;
end


wire [4-1:0] sel = {a1 & b1, a1 & ~b1, ~a1 & b1, ~a1 & ~b1};
reg [4-1:0] sel_d;
always @(posedge clk) begin
    sel_d <= sel;
end

assign out[1] = ^(r_fx1 & sel_d);

reg sel_rnd;
always @(posedge clk) begin
    sel_rnd <= ^(rnd & sel);
end

assign out[0] = sel_rnd;


endmodule
