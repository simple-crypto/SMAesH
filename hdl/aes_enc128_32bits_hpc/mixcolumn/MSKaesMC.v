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

// Masked implementation of MixColumms.
// The implementation is sharewise and purely combinational.
(* fv_prop = "affine", fv_strat = "composite", fv_order=d *)
module MSKaesMC
#
(
    parameter d = 2
)
(
    // Input shares (masked GF_256 field elements)
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    input [8*d-1:0] a0,
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    input [8*d-1:0] a1,
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    input [8*d-1:0] a2,
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    input [8*d-1:0] a3,
    // Output shares (masked GF_256 field elements)
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    output [8*d-1:0] b0,
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    output [8*d-1:0] b1,
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    output [8*d-1:0] b2,
    (* fv_type="sharing" , fv_latency=0, fv_count=8 *)
    output [8*d-1:0] b3
);


genvar i, j;
generate
for(i=0;i<d;i=i+1) begin: share_mc
    wire [31:0] cin, cout;
    for(j=0;j<8;j=j+1) begin: share_bytes
        // Inputs
        assign cin[0+j] = a0[d*j+i];
        assign cin[8+j]= a1[d*j+i];
        assign cin[16+j]= a2[d*j+i];
        assign cin[24+j]= a3[d*j+i];
        // Outputs
        assign b0[d*j+i] = cout[0+j];
        assign b1[d*j+i] = cout[8+j];
        assign b2[d*j+i] = cout[16+j];
        assign b3[d*j+i] = cout[24+j];
    end
    // MC logic for the share
    aes_mc_single_column mc_logic(
        .cin(cin),
        .cout(cout)
    );
end
endgenerate

endmodule
