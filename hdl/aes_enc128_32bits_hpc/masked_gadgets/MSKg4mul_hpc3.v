// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked HPC3 G(4) multiplication
`ifdef FULLVERIF
(* fv_prop = "PINI", fv_strat = "assumed", fv_order=d *)
`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKg4mul_hpc3 #(parameter d=`DEFAULTSHARES) (ina0, ina1, inb0, inb1, ina0_prev, ina1_prev, rnd, clk, out0, out1);
`include "MSKand_hpc3.vh"
localparam mat_rnd = hpc3rnd/2;

(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina0, ina1;
(* fv_type = "sharing", fv_latency = 1 *) input  [d-1:0] ina0_prev, ina1_prev;
(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] inb0, inb1;
(* fv_type = "clock" *) input clk;
(* fv_type = "sharing", fv_latency = 1 *) output [d-1:0] out0, out1;
(* fv_type = "random", fv_count=1, fv_rnd_lat_0=0, fv_rnd_count_0=2*hpc3rnd *)
input [2*hpc3rnd-1:0] rnd;

wire [d-1:0] inb0_ref, inb1_ref;
                                      
genvar i,j;

// unpack vector to matrix --> easier for randomness handling
wire [2*mat_rnd-1:0] rnd0 = rnd[0 +: 2*mat_rnd];
wire [2*mat_rnd-1:0] rnd1 = rnd[2*mat_rnd +:2* mat_rnd];
wire [1:0] rnd_mat0 [d-1:0][d-1:0]; 
wire [1:0] rnd_mat1 [d-1:0][d-1:0]; 
for(i=0; i<d; i=i+1) begin: rnd_mat_i
    assign rnd_mat0[i][i] = 2'b0;
    assign rnd_mat1[i][i] = 2'b0;
    for(j=i+1; j<d; j=j+1) begin: rnd_mat_j
        integer offset = ((i*d)-i*(i+1)/2)+(j-1-i);
        assign rnd_mat0[j][i] = rnd0[2*offset +: 2];
        assign rnd_mat1[j][i] = rnd1[2*offset +: 2];
        // The next line is equivalent to
        // assign rnd_mat[i][j] = rnd_mat[j][i];
        // but we changed it for Verilator efficient simulation -> Avoid UNOPFLAT Warning (x2 simulation perfs enabled)
        assign rnd_mat0[i][j] = rnd0[2*offset +: 2];
        assign rnd_mat1[i][j] = rnd1[2*offset +: 2];
    end
end

for(i=0; i<d; i=i+1) begin: ParProdI
    wire [d-2:0] u0, u1, v0, v1;
    assign out0[i] = ^u0 ^ ^v0;
    assign out1[i] = ^u1 ^ ^v1;
    for(j=0; j<d; j=j+1) begin: ParProdJ
        if (i != j) begin: NotEq
            localparam j2 = j < i ?  j : j-1;
            wire [1:0] u_j2_comb, mul1_in, mul1_out;
            // j2 == 0: u = Reg[a*(rnd0+b) + rnd1]
            // j2 != 0: u = Reg[a*rnd0 + rnd1]
            if (j2 == 0) begin
                assign mul1_in = {inb1[i], inb0[i]} ^ rnd_mat0[i][j];
            end else begin
                assign mul1_in = rnd_mat0[i][j];
            end
            G4_mul g4mul_inst1(
                .x({ina1[i], ina0[i]}),
                .y(mul1_in),
                .z(mul1_out)
            );
            assign u_j2_comb = mul1_out ^ rnd_mat1[i][j];
            bin_REG #(.W(2)) REGin_u(
                .clk(clk),
                .in(u_j2_comb),
                .out({u1[j2],u0[j2]})
            );
            // v = a*Reg[b+rnd0]
            wire [1:0] v_j2_comb = {inb1[j],inb0[j]} ^ rnd_mat0[i][j];
            wire [1:0] v_j2;
            bin_REG #(.W(2)) REGin_v2(
                .clk(clk),
                .in(v_j2_comb),
                .out(v_j2)
            );
            G4_mul g4mul_inst2(
                .x({ina1_prev[i], ina0_prev[i]}),
                .y(v_j2),
                .z({v1[j2],v0[j2]})
            );
        end
    end
end



endmodule
