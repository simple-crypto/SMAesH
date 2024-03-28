// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// SNI refresh gadget, for d=2,...,16
`ifdef FULLVERIF
  (* fv_prop = "SNI", fv_strat = "assumed", fv_order=d *)
`endif
`ifndef DEFAULTSHARES
  `define DEFAULTSHARES 2
`endif
module MSKref_sni #(parameter d=`DEFAULTSHARES) (in, clk, out, rnd);

`include "MSKref_sni.vh"

(* syn_keep="true", keep="true", fv_type="sharing", fv_latency=ref_rndlat *) input [d-1:0] in;
(* syn_keep="true", keep="true", fv_type="sharing", fv_latency=ref_rndlat+1 *) output reg [d-1:0] out;
(* fv_type="clock" *) input clk;
(* syn_keep="true", keep="true", fv_type= "random", fv_count=1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = ref_n_rnd *)
input [ref_n_rnd-1:0] rnd;

reg [d-1:0] share0;
always @(posedge clk)
  out <= in ^ share0;

if (d == 1) begin
    always @(*) begin
        share0 = 1'b0;
    end
end else if (d == 2) begin
    always @(*) begin
        share0 = {rnd[0], rnd[0]};
    end
end else if (d==3) begin
    always @(posedge clk) begin
        share0 <= {rnd[0]^rnd[1], rnd[1], rnd[0]};
    end
end else if (d==4 || d==5) begin
    wire [d-1:0] r1 = rnd[d-1:0];
    always @(posedge clk) begin
        share0 <= r1[d-1:0] ^ { r1[d-2:0], r1[d-1] };
    end
end

endmodule
