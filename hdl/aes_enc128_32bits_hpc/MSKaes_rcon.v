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

// Outputs the AES round constant. The masking is non-random: (x, 0, ..., 0).
(* fv_strat = "flatten" *)
module MSKaes_rcon
#
(
    parameter d = 2
)
(
    input clk,
    // Active high.
    input rst,
    // Active high,
    input mode_256,
    // Update the rcon value
    input update,
    // Gates the output to 0 if high.
    input mask_rcon,
    // RCON as a sharing 
    output [8*d-1:0] sh_rcon,
    // Control for the inverse operation
    input inverse
);

//// Unshared rcon
reg [7:0] rcon;
wire [7:0] next_rcon;
wire [7:0] rst_rcon;
always @(posedge clk) begin
    if (rst) begin
        rcon <= rst_rcon;
    end else if (update) begin
        rcon <= next_rcon;
    end 
end

// Forward computation
wire [7:0] shifted_rcon = {rcon[6:0],1'b0};
wire [7:0] masked_0x1b_cst = {8{rcon[7]}} & 8'h1b;
wire [7:0] next_rcon_forward = shifted_rcon ^ masked_0x1b_cst;

// Reverse computation
wire [7:0] shifted_rcon_inverse = {1'b0, rcon[7:1]};
wire [7:0] next_rcon_inverse = shifted_rcon_inverse ^ ({8{rcon[0]}} & 8'h0d) ^ {rcon[0], 7'b0};

assign next_rcon = inverse ? next_rcon_inverse : next_rcon_forward;
assign rst_rcon = inverse ? (mode_256 ? 8'h40 : 8'h36) : 8'h01;

//// Output mux
wire [7:0] out_rcon;
assign out_rcon = rcon & {8{mask_rcon}};

//// Sharing
MSKcst #(.d(d),.count(8))
cst_sh_rcon(
    .cst(out_rcon),
    .out(sh_rcon)
);


endmodule
