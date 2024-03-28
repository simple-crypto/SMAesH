// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-S-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-S v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-S v2 (https://ohwr.org/cern_ohl_s_v2.txt ).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-S v2 for applicable conditions.
// Source location: https://github.com/simple-crypto/SMAesH
// As per CERN-OHL-S v2 section 4, should You produce hardware based
// on this source, You must where practicable maintain the Source Location
// visible on the external case of any product you make using this source.

// Takes masked x in GF_256 and returns masked 0x02*x and 0x03*x.
// The implementation is sharewise and purely combinational.
(* fv_prop = "affine", fv_strat = "isolate", fv_order=d *)
module MSKprodMC
#
(
    parameter d = 2
)
(

    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    input [8*d-1:0] sh_in,
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    output [8*d-1:0] sh_inx2,
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    output [8*d-1:0] sh_inx3
);

wire [7:0] cst_poly = 8'h1b;

// Generate sharings
genvar i,j;
wire [7:0] shares [d-1:0];
generate
for(i=0;i<8;i=i+1) begin: bit_op
    for(j=0;j<d;j=j+1) begin: share_op
        assign shares[j][i] = sh_in[i*d+j];
    end
end
endgenerate

// Generate xtime for each indep share.
wire [7:0] x2_shares [d-1:0];
wire [7:0] x3_shares [d-1:0];
generate
for(i=0;i<d;i=i+1) begin: sharing_op
    wire [7:0] used_shares = shares[i];
    wire sh_MSB = shares[i][7];
    wire [7:0] shifted_sh = {shares[i][6:0],1'b0};
    wire [7:0] and_cst_poly = ({8{sh_MSB}} & cst_poly);
    assign x2_shares[i] = shifted_sh ^ and_cst_poly;
    assign x3_shares[i] = x2_shares[i] ^ shares[i];
end
endgenerate

// Regenerate output mux
generate
for(i=0;i<8;i=i+1) begin: out_share
    for(j=0;j<d;j=j+1) begin: share_out_op
        assign sh_inx2[i*d+j] = x2_shares[j][i]; 
        assign sh_inx3[i*d+j] = x3_shares[j][i]; 
    end
end
endgenerate


endmodule
