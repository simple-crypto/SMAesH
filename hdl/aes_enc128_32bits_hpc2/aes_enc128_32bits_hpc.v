// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-S-2.0
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

// Masked AES implementation using HPC masking scheme and 32-bit
// architecture.
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module aes_enc128_32bits_hpc
#
(
    parameter d = `DEFAULTSHARES,
    parameter PRNG_MAX_UNROLL = 512
)
(
    clk,
    // synchronous, active high
    rst,
    // valid/ready stream input (both key and plaintext must be provided
    // simultnaneously)
    in_valid,
    in_ready,
    in_shares_plaintext,
    in_shares_key,
    // valid/ready stream seed
    in_seed_valid,
    in_seed_ready,
    in_seed,
    // valid/ready stream output
    out_shares_ciphertext,
    out_valid,
    out_ready
);

/* ===== IOs definition ====*/
input clk;
// synchronous, active high
input rst;
// SVRS input (both key and plaintext must be provided simultnaneously)
input in_valid;
output in_ready;
(* verime = "shares_plaintext" *)
input [128*d-1:0] in_shares_plaintext;
(* verime = "shares_key" *)
input [128*d-1:0] in_shares_key;
// SVRS PRNG seed
input in_seed_valid;
output in_seed_ready;
input [79:0] in_seed;
// SVRS ciphertext output
(* verime = "shares_ciphertext" *)
output [128*d-1:0] out_shares_ciphertext;
output out_valid;
input out_ready;

`include "design.vh" 

/* =========== Aes core =========== */
wire aes_busy;
wire aes_valid_in;
wire aes_ready_in;
wire aes_cipher_valid;
wire aes_out_ready;
wire [4*rnd_bus0-1:0] rnd_bus0w;
wire [4*rnd_bus1-1:0] rnd_bus1w;
wire [4*rnd_bus2-1:0] rnd_bus2w;
`ifdef CANRIGHT_SBOX
wire [4*rnd_bus3-1:0] rnd_bus3w;

`endif
wire aes_in_ready_rnd;

// Modify shares encoding to sequential shared bit instead of 
// sequential shares for each bit of the key, plaintext and ciphertext.
wire [128*d-1:0] sh_key;
shares2shbus #(.d(d),.count(128))
switch_encoding_key(
    .shares(in_shares_key),
    .shbus(sh_key)
);

wire [128*d-1:0] sh_plaintext;
shares2shbus #(.d(d),.count(128))
switch_encoding_plaintext(
    .shares(in_shares_plaintext),
    .shbus(sh_plaintext)
);

wire [128*d-1:0] sh_ciphertext;
shbus2shares #(.d(d),.count(128))
switch_encoding_ciphertext(
    .shbus(sh_ciphertext),
    .shares(out_shares_ciphertext)
);

// Inner AES core
MSKaes_32bits_core
`ifndef CORE_SYNTHESIZED
#(
    .d(d)
)
`endif
aes_core(
    .rst(rst),
    .clk(clk),
    .busy(aes_busy),
    .valid_in(aes_valid_in),
    .in_ready(aes_ready_in),
    .cipher_valid(aes_cipher_valid),
    .out_ready(aes_out_ready),
    .sh_plaintext(sh_plaintext),
    .sh_key(sh_key),
    .sh_ciphertext(sh_ciphertext),
    .rnd_bus0w(rnd_bus0w),
    .rnd_bus1w(rnd_bus1w),
    .rnd_bus2w(rnd_bus2w),
`ifdef CANRIGHT_SBOX
    .rnd_bus3w(rnd_bus3w),
`endif
    .in_ready_rnd(aes_in_ready_rnd)
);

/* =========== PRNG =========== */
localparam NINIT=4*288;
`ifdef CANRIGHT_SBOX
localparam RND_AM = 4*(rnd_bus0+rnd_bus1+rnd_bus2+rnd_bus3);
`else
localparam RND_AM = 4*(rnd_bus0+rnd_bus1+rnd_bus2);
`endif
wire [RND_AM-1:0] rnd; 

wire prng_start_reseed;
wire prng_out_valid;
wire prng_busy;
prng_top #(.RND(RND_AM),.NINIT(NINIT),.MAX_UNROLL(PRNG_MAX_UNROLL))
prng_unit(
    .rst(rst),
    .clk(clk),
    .seed(in_seed),
    .start_reseed(prng_start_reseed),
    .out_ready(aes_in_ready_rnd),
    .out_valid(prng_out_valid),
    .out_rnd(rnd),
    .busy(prng_busy)
);

assign rnd_bus0w = rnd[0 +: 4*rnd_bus0];
assign rnd_bus1w = rnd[4*rnd_bus0 +: 4*rnd_bus1];
assign rnd_bus2w = rnd[4*(rnd_bus0+rnd_bus1) +: 4*rnd_bus2];
`ifdef CANRIGHT_SBOX
assign rnd_bus3w = rnd[4*(rnd_bus0+rnd_bus1+rnd_bus2) +: 4*rnd_bus3];
`endif

// SVRS interfaces handling.
// Stall input interface if PRNG output is not valid.
assign aes_valid_in = in_valid & prng_out_valid;
assign in_ready = aes_ready_in & prng_out_valid;

assign aes_out_ready = out_ready; 
assign out_valid = aes_cipher_valid;

// Reseed mechanism starts only if in_seed_valid is asserted and AES core is
// not active (or starting to be active), since this would give bad randomness
// to that core.
assign prng_start_reseed = in_seed_valid & ~in_valid & ~aes_busy;

// Compute in_seed_ready.
// We used input seed when there is as posedge on prng_busy.
reg prev_prng_busy;
always @(posedge clk)
if (rst) begin
    prev_prng_busy <= 0; 
end else begin
    prev_prng_busy <= prng_busy; 
end
assign in_seed_ready = ~prev_prng_busy & prng_busy;

endmodule
