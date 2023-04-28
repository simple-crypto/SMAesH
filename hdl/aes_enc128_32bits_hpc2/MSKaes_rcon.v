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
    // Update the rcon value
    input update,
    // Gates the output to 0 if high.
    input mask_rcon,
    // RCON as a sharing 
    output [8*d-1:0] sh_rcon
);

//// Unshared rcon
reg [7:0] rcon, next_rcon;
always @(posedge clk) begin
    rcon <= next_rcon;
end

always @(*) begin
    if (rst) begin
        next_rcon = 8'h01;
    end else if (update) begin
        if (rcon[7]) begin
            next_rcon = 8'h1b;
        end else begin
            next_rcon = rcon << 1;
        end
    end else begin
        next_rcon = rcon;
    end
end

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
