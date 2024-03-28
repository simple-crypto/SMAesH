// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked AND DOM gadget.
`ifdef FULLVERIF
(* fv_prop = "NI", fv_strat = "assumed", fv_order=d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKand_dom #(parameter d=`DEFAULTSHARES) (ina, inb, rnd, clk, out);

localparam n_rnd=d*(d-1)/2;

(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina, inb;
(* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = n_rnd *) input [n_rnd-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "sharing", fv_latency = 1 *) output [d-1:0] out;

genvar i,j;

// unpack vector to matrix --> easier for randomness hendeling
wire [d-1:0] rnd_mat [d-1:0]; 
for(i=0; i<d; i=i+1) begin: igen
    assign rnd_mat[i][i] = 0;
    for(j=i+1; j<d; j=j+1) begin: jgen
        assign rnd_mat[j][i] = rnd[((i*d)-i*(i+1)/2)+(j-1-i)];
        assign rnd_mat[i][j] = rnd_mat[j][i];
    end
end

for(i=0; i<d; i=i+1) begin: ParProdI
    reg [d-1:0] rfrsh_reg;
    assign out[i] = ^rfrsh_reg;
    for(j=0; j<d; j=j+1) begin: ParProdJ
        wire mult_wire = ina[i] & inb[j];
        wire rfrsh_wire = mult_wire ^ rnd_mat[i][j];
        always @(posedge clk) begin
            rfrsh_reg[j] <= rfrsh_wire;
        end
    end
end

endmodule
