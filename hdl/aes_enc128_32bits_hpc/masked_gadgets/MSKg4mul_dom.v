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
module MSKg4mul_dom #(parameter d=`DEFAULTSHARES) (ina0, ina1, inb0, inb1, rnd, clk, out0, out1);

localparam n_rnd=2*d*(d-1)/2;

(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina0, ina1, inb0, inb1;
(* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = n_rnd *) input [n_rnd-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "sharing", fv_latency = 1 *) output [d-1:0] out0, out1;

genvar i,j;

// unpack vector to matrix --> easier for randomness hendeling
wire [1:0] rnd_mat [d-1:0][d-1:0];

for(i=0; i<d; i=i+1) begin: igen
    assign rnd_mat[i][i] = 2'b0;
    for(j=i+1; j<d; j=j+1) begin: jgen
        integer offset = ((i*d)-i*(i+1)/2)+(j-1-i);
        assign rnd_mat[j][i] = rnd[2*offset +: 2];
        assign rnd_mat[i][j] = rnd_mat[j][i];
    end
end

genvar k;
generate 
for(i=0; i<d; i=i+1) begin: ParProdI
    reg [d-1:0] rfrsh_reg0, rfrsh_reg1;
    for(j=0; j<d; j=j+1) begin: ParProdJ
        wire [1:0] mult_wire;
        G4_mul mul(
            .x({ina1[i],ina0[i]}),
            .y({inb1[j],inb0[j]}),
            .z(mult_wire)
        );
        wire [1:0] rfrsh_wire = mult_wire ^ rnd_mat[i][j];
        always @(posedge clk) begin
            rfrsh_reg0[j] <= rfrsh_wire[0];
            rfrsh_reg1[j] <= rfrsh_wire[1];
        end
    end
    assign out0[i] = ^rfrsh_reg0;
    assign out1[i] = ^rfrsh_reg1;
end
endgenerate

endmodule
