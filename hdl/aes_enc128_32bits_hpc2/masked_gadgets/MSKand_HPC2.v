// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked AND HPC2 gadget.
(* fv_prop = "PINI", fv_strat = "assumed", fv_order=d *)
module MSKand_HPC2 #(parameter d=2) (ina, inb, rnd, clk, out);

`include "MSKand_HPC2.vh"

(* fv_type = "sharing", fv_latency = 1 *) input  [d-1:0] ina;
(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] inb;
(* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = and_pini_nrnd *) input [and_pini_nrnd-1:0] rnd;
(* fv_type = "clock" *) input clk;
(* fv_type = "random", fv_type = "sharing", fv_latency = 2 *) output [d-1:0] out;
                                      
genvar i,j;

// unpack vector to matrix --> easier for randomness handling
//reg [and_pini_nrnd-1:0] rnd_prev;
wire [and_pini_nrnd-1:0] rnd_prev;
bin_REG #(.W(and_pini_nrnd)) REGin_rnd_prev (
    .clk(clk),
    .in(rnd),
    .out(rnd_prev)
);

wire [d-1:0] rnd_mat [d-1:0]; 
wire [d-1:0] rnd_mat_prev [d-1:0]; 
for(i=0; i<d; i=i+1) begin: igen
    assign rnd_mat[i][i] = 0;
    assign rnd_mat_prev[i][i] = 0;
    for(j=i+1; j<d; j=j+1) begin: jgen
        assign rnd_mat[j][i] = rnd[((i*d)-i*(i+1)/2)+(j-1-i)];
        // The next line is equivalent to
        //assign rnd_mat[i][j] = rnd_mat[j][i];
        // but we changed it for Verilator efficient simulation -> Avoid UNOPFLAT Warning (x2 simulation perfs enabled)
        assign rnd_mat[i][j] = rnd[((i*d)-i*(i+1)/2)+(j-1-i)];
        assign rnd_mat_prev[j][i] = rnd_prev[((i*d)-i*(i+1)/2)+(j-1-i)];
        // The next line is equivalent to
        //assign rnd_mat_prev[i][j] = rnd_mat_prev[j][i];
        // but we changed it for Verilator efficient simulation -> Avoid UNOPFLAT Warning (x2 simulation perfs enabled)
        assign rnd_mat_prev[i][j] = rnd_prev[((i*d)-i*(i+1)/2)+(j-1-i)];
    end
end

wire [d-1:0] not_ina;
bin_NOT #(.W(d)) NOTin_not_ina (
    .in(ina),
    .out(not_ina)
);
wire [d-1:0] inb_prev;
bin_REG #(.W(d)) REGin_inb_prev (
    .clk(clk),
    .in(inb),
    .out(inb_prev)
);

for(i=0; i<d; i=i+1) begin: ParProdI
    wire [d-2:0] u, v, w;
    wire aibi;
    wire aibi_comb;
    bin_AND #(.W(1)) ANDin_aibi_comb(
        .ina(ina[i]),
        .inb(inb_prev[i]),
        .out(aibi_comb)
    );
    bin_REG #(.W(1)) REGin_aibi(
        .clk(clk),
        .in(aibi_comb),
        .out(aibi)
    );
    wire red_u, red_w;
    bin_redXOR #(.W(d-1)) redXORin_red_u(
        .in(u),
        .out(red_u)
    );
    bin_redXOR #(.W(d-1)) redXORin_red_w(
        .in(w),
        .out(red_w)
    );
    wire ru_xor_rw;
    bin_XOR #(.W(1)) XORin_ru_xor_rw(
        .ina(red_u),
        .inb(red_w),
        .out(ru_xor_rw)
    );
    bin_XOR #(.W(1)) XORin_out(
        .ina(aibi),
        .inb(ru_xor_rw),
        .out(out[i])
    );
    for(j=0; j<d; j=j+1) begin: ParProdJ
        if (i != j) begin: NotEq
            localparam j2 = j < i ?  j : j-1;
            wire u_j2_comb;
            bin_AND #(.W(1)) ANDin_u_j2_comb(
                .ina(not_ina[i]),
                .inb(rnd_mat_prev[i][j]),
                .out(u_j2_comb)
            );
            wire v_j2_comb;
            bin_XOR #(.W(1)) XORin_v2_comb(
                .ina(inb[j]),
                .inb(rnd_mat[i][j]),
                .out(v_j2_comb)
            );
            wire w_j2_comb;
            bin_AND #(.W(1)) ANDin_w_j2_comb(
                .ina(ina[i]),
                .inb(v[j2]),
                .out(w_j2_comb)
            );
            bin_REG #(.W(1)) REGin_u(
                .clk(clk),
                .in(u_j2_comb),
                .out(u[j2])
            );
            bin_REG #(.W(1)) REGin_v(
                .clk(clk),
                .in(v_j2_comb),
                .out(v[j2])
            );
            bin_REG #(.W(1)) REGin_w(
                .clk(clk),
                .in(w_j2_comb),
                .out(w[j2])
            );
        end
    end
end

endmodule
