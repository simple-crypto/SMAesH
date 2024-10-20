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
`include "architecture_default.vh"
module smaesh_hpc
#
(
    parameter integer d = `DEFAULTSHARES,
    parameter integer PRNG_MAX_UNROLL = 512
)
(
    clk,
    // synchronous, active high
    rst,
    // valid/ready data stream input
    in_data_valid,
    in_data_ready,
    in_shares_data,
    // valid/ready key stream input
    in_key_valid,
    in_key_ready,
    in_key_data,
    in_key_size_cfg,
    in_key_mode_inverse,
    // valid/ready stream seed
    in_seed_valid,
    in_seed_ready,
    in_seed,
    // valid/ready stream output
    out_shares_data,
    out_valid,
    out_ready
);

/* ===== IOs definition ====*/
input clk;
// synchronous, active high
input rst;
// SVRS input (both key and plaintext must be provided simultnaneously)
input in_data_valid;
output in_data_ready;
(* verime = "shares_plaintext" *)
input [128*d-1:0] in_shares_data;
input in_key_valid;
output in_key_ready;
input [31:0] in_key_data;
input [1:0] in_key_size_cfg;
input in_key_mode_inverse;
// SVRS PRNG seed
input in_seed_valid;
output in_seed_ready;
input [79:0] in_seed;
// SVRS ciphertext output
(* verime = "shares_ciphertext" *)
output [128*d-1:0] out_shares_data;
output out_valid;
input out_ready;

`include "canright_aes_sbox_dual.vh"

/* =========== Aes core =========== */
wire aes_busy;
wire aes_valid_in;
wire aes_ready_in;
wire aes_out_valid;
wire aes_out_ready;
wire [4*rnd_bus0-1:0] rnd_bus0w;
wire [4*rnd_bus1-1:0] rnd_bus1w;
wire [4*rnd_bus2-1:0] rnd_bus2w;
wire [4*rnd_bus3-1:0] rnd_bus3w;

wire aes_in_ready_rnd;

// Modify shares encoding to sequential shared bit instead of
// sequential shares for each bit of the plaintext and ciphertext.
wire [128*d-1:0] sh_data_in;
shares2shbus #(.d(d),.count(128))
switch_encoding_plaintext(
    .shares(in_shares_data),
    .shbus(sh_data_in)
);

wire [128*d-1:0] sh_data_out;
shbus2shares #(.d(d),.count(128))
switch_encoding_ciphertext(
    .shbus(sh_data_out),
    .shares(out_shares_data)
);

// Inner Key holder
wire [256*d-1:0] KSU_sh_key_out;
wire KSU_busy;
wire KSU_rnd_bus0_valid_for_rfrsh;
wire [32*d-1:0] KSU_sh_last_key_col;
wire KSU_last_key_pre_valid;
wire KSU_start_fetch_procedure;

wire KSU_last_key_computation_required;
wire KSU_aes_mode_256;
wire KSU_aes_mode_192;
wire KSU_aes_mode_inverse;
wire KSU_in_ready;
wire KSU_valid_in;

MSKkey_holder #(.d(d))
key_storage_unit(
    .clk(clk),
    .rst(rst),
    .data_in(in_key_data),
    .data_in_valid(KSU_valid_in),
    .data_in_ready(KSU_in_ready),
    .sh_last_key_col(KSU_sh_last_key_col),
    .sh_last_key_col_pre_valid(KSU_last_key_pre_valid),
    .sh_data_out(KSU_sh_key_out),
    .rnd_rfrsh_in(rnd_bus0w[(d-1)*16-1:0]),
    .rnd_rfrsh_in_valid(KSU_rnd_bus0_valid_for_rfrsh),
    .start_fetch_procedure(KSU_start_fetch_procedure),
    .key_size_cfg(in_key_size_cfg),
    .mode_inverse(in_key_mode_inverse),
    .busy(KSU_busy),
    .aes_busy(aes_busy),
    .last_key_computation_required(KSU_last_key_computation_required),
    .aes_mode_256(KSU_aes_mode_256),
    .aes_mode_192(KSU_aes_mode_192),
    .aes_mode_inverse(KSU_aes_mode_inverse)
);

// Inner AES core
wire aes_inverse = KSU_last_key_computation_required ? 1'b0 : KSU_aes_mode_inverse;
wire aes_key_schedule_only = KSU_last_key_computation_required;
wire aes_mode_256 = KSU_aes_mode_256;
wire aes_mode_192 = KSU_aes_mode_192;

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
    .out_valid(aes_out_valid),
    .out_ready(aes_out_ready),
    .inverse(aes_inverse),
    .key_schedule_only(aes_key_schedule_only),
    .last_key_pre_valid(KSU_last_key_pre_valid),
    .mode_256(aes_mode_256),
    .mode_192(aes_mode_192),
    .sh_data_in(sh_data_in),
    .sh_key(KSU_sh_key_out),
    .sh_data_out(sh_data_out),
    .sh_last_key_col(KSU_sh_last_key_col),
    .rnd_bus0w(rnd_bus0w),
    .rnd_bus1w(rnd_bus1w),
    .rnd_bus2w(rnd_bus2w),
    .rnd_bus3w(rnd_bus3w),
    .in_ready_rnd(aes_in_ready_rnd),
    .rnd_bus0_valid_for_rfrsh(KSU_rnd_bus0_valid_for_rfrsh)
);

/* =========== PRNG =========== */
localparam integer NINIT=4*288;
localparam integer RND_AM = 4*(rnd_bus0+rnd_bus1+rnd_bus2+rnd_bus3);
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
assign rnd_bus3w = rnd[4*(rnd_bus0+rnd_bus1+rnd_bus2) +: 4*rnd_bus3];

//// SVRS interfaces handling.
// Arbitrer
smaesh_arbitrer arbitrer(
    .clk(clk),
    .rst(rst),
    .in_seed_valid(in_seed_valid),
    .in_seed_ready(in_seed_ready),
    .in_key_valid(in_key_valid),
    .in_key_ready(in_key_ready),
    .in_data_valid(in_data_valid),
    .in_data_ready(in_data_ready),
    .KSU_in_ready(KSU_in_ready),
    .aes_in_ready(aes_ready_in),
    .prng_busy(prng_busy),
    .KSU_busy(KSU_busy),
    .aes_busy(aes_busy),
    .prng_seeded(prng_out_valid),
    .prng_start_reseed(prng_start_reseed),
    .KSU_start_fetch_procedure(KSU_start_fetch_procedure),
    .KSU_last_key_computation_required(KSU_last_key_computation_required),
    .aes_valid_in(aes_valid_in),
    .KSU_valid_in(KSU_valid_in)
);

// Output signal: just forward
assign aes_out_ready = out_ready;
assign out_valid = aes_out_valid;


endmodule
