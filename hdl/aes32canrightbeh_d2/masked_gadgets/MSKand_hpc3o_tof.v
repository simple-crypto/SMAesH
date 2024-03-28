// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked AND HPC3 gadget.
`ifdef FULLVERIF
(* fv_prop = "PINI", fv_strat = "assumed", fv_order=d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKand_hpc3o_tof #(parameter d=`DEFAULTSHARES) (ina, ina_prev, inb, inc, rnd, clk, out);

`include "MSKand_hpc3.vh"
localparam mat_rnd = hpc3rnd/2;

(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina;
(* fv_type = "sharing", fv_latency = 1 *) input  [d-1:0] ina_prev;
(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] inb;
(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] inc;
(* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = hpc3rnd *) input [hpc3rnd-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "sharing", fv_latency = 1 *) output [d-1:0] out;
                                      
genvar i,j;

// unpack vector to matrix --> easier for randomness handling
wire [mat_rnd-1:0] rnd0 = rnd[0 +: mat_rnd];
wire [mat_rnd-1:0] rnd1 = rnd[mat_rnd +: mat_rnd];
wire [d-1:0] rnd_mat0 [d-1:0]; 
wire [d-1:0] rnd_mat1 [d-1:0]; 
for(i=0; i<d; i=i+1) begin: rnd_mat_i
    assign rnd_mat0[i][i] = 0;
    assign rnd_mat1[i][i] = 0;
    for(j=i+1; j<d; j=j+1) begin: rnd_mat_j
        assign rnd_mat0[j][i] = rnd0[((i*d)-i*(i+1)/2)+(j-1-i)];
        assign rnd_mat1[j][i] = rnd1[((i*d)-i*(i+1)/2)+(j-1-i)];
        // The next line is equivalent to
        // assign rnd_mat[i][j] = rnd_mat[j][i];
        // but we changed it for Verilator efficient simulation -> Avoid UNOPFLAT Warning (x2 simulation perfs enabled)
        assign rnd_mat0[i][j] = rnd0[((i*d)-i*(i+1)/2)+(j-1-i)];
        assign rnd_mat1[i][j] = rnd1[((i*d)-i*(i+1)/2)+(j-1-i)];
    end
end

for(i=0; i<d; i=i+1) begin: ParProdI
    wire [d-2:0] u, v;
    assign out[i] = ^u ^ ^v;
    for(j=0; j<d; j=j+1) begin: ParProdJ
        if (i != j) begin: NotEq
            localparam j2 = j < i ?  j : j-1;
            wire u_j2_comb, u0_j2_comb, u0_j2_comb_tof;
            wire op_and_a;
            // j2 == 0: u = Reg[a*(rnd0+b) + rnd1]
            // j2 != 0: u = Reg[a*rnd0 + rnd1]
            if (j2 == 0) begin
                assign u_j2_comb = (ina[i] & (rnd_mat0[i][j] ^ inb[i])) ^ inc[i] ^ rnd_mat1[i][j];
            end else begin
                assign u_j2_comb = (ina[i] & rnd_mat0[i][j]) ^ rnd_mat1[i][j];
            end
            bin_REG #(.W(1)) REGin_u(
                .clk(clk),
                .in(u_j2_comb),
                .out(u[j2])
            );
            // v = a*Reg[b+rnd0]
            wire v_j2_comb = inb[j] ^ rnd_mat0[i][j];
            wire v_j2;
            bin_REG #(.W(1)) REGin_v2(
                .clk(clk),
                .in(v_j2_comb),
                .out(v_j2)
            );
            assign v[j2] = ina_prev[i] & v_j2;
        end
    end
end

endmodule
