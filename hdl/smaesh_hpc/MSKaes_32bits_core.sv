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

// Full 32-bit arbitrary-order masked implementation of the AES (no inverse).
// This is the complete AES that can be verified with fullVerif.
`ifndef NSHARES
`define NSHARES 2
`endif
(* matchi_prop="PINI", matchi_strat="composite_top", matchi_arch="loopy", matchi_shares=d *)
module MSKaes_32bits_core
#
(
    parameter integer d=`NSHARES
)
(
    clk,
    // Active HIGH syn reset
    rst,
    // Active high
    busy,
    // Active high
    valid_in,
    // Active high when the core is not busy: valid_in can be asserted.
    in_ready,
    // Active high when cipher is valid. Remains high as long as in_ready was not asserted for one cycle.
    out_valid,
    // Active high when the output can be fetched. If out_valid and
    // out_ready are both high, the ciphertext is dropped from the core.
    out_ready,
    // Active high; specifies that the next operation starting must be inverse
    inverse,
    // Active high; specifies that the next operation starting must compute the
    // key scheduling only
    key_schedule_only,
    // Active high; specifies that the data on sh_last_key bus is valid.
    last_key_pre_valid,
    // Active high; specifies that the next operation starting must compute the
    // AES-256 version (default is AES-128)
    mode_256,
    // Active high; specifies that the next operation starting must compute the
    // AES-192 version (default is AES-128).  Ignored if asserted together with
    // 'mode_256'
    mode_192,
    //// Data
    // Masked plaintext (bit-compact representation). Valid when valid_in is high.
    sh_data_in,
    // Masked key (bit-compact representation). Valid when valid_in is high.
    sh_key,
    // Masked ciphertext (bit-compact representation). Valid when out_valid is high.
    sh_data_out,
    // Masked last key used (bit-compact representation). Used only to init the last round key in inverse mode).
    sh_last_key_col,
    // Randomness busses (required for the Sboxes). These busses must contain
    // fresh randomness for every cycle where the core is computing, which is
    // signaled by a HIGH value on in_ready_rnd.
    rnd_bus0w,
    rnd_bus1w,
    rnd_bus2w,
    rnd_bus3w,
    in_ready_rnd,
    rnd_bus0_valid_for_rfrsh
);

`include "canright_aes_sbox_dual.vh"

// IOs Ports
(* matchi_type="control" *)
input rst;
(* matchi_type="clock" *)
input clk;
(* matchi_type="control" *)
output busy;
(* matchi_type="control" *)
input valid_in;
(* matchi_type="control" *)
output in_ready;
(* matchi_type="control" *)
output out_valid;
(* matchi_type="control" *)
input out_ready;

(* matchi_type="control" *)
input inverse;
(* matchi_type="control" *)
input key_schedule_only;
(* matchi_type="control" *)
output last_key_pre_valid;
(* matchi_type="control" *)
input mode_256;
(* matchi_type="control" *)
input mode_192;

(* matchi_type="sharings_dense", matchi_active="matchi_input_active" *)
input [128*d-1:0] sh_data_in;
(* matchi_type="sharings_dense", matchi_active="matchi_input_active" *)
input [256*d-1:0] sh_key;
(* matchi_type="sharings_dense", matchi_active="matchi_output_active" *)
output [128*d-1:0] sh_data_out;
(* matchi_type="sharings_dense", matchi_active="matchi_lcol_valid" *)
output [32*d-1:0] sh_last_key_col;

(* matchi_type="random", matchi_active="matchi_rnd_active" *)
input [4*rnd_bus0-1:0] rnd_bus0w;
(* matchi_type="random", matchi_active="matchi_rnd_active" *)
input [4*rnd_bus1-1:0] rnd_bus1w;
(* matchi_type="random", matchi_active="matchi_rnd_active" *)
input [4*rnd_bus2-1:0] rnd_bus2w;
(* matchi_type="random", matchi_active="matchi_rnd_active" *)
input [4*rnd_bus3-1:0] rnd_bus3w;

(* matchi_type="control" *)
output in_ready_rnd;
(* matchi_type="control" *)
output rnd_bus0_valid_for_rfrsh;

// Signai only used for MATCHI (formal verif) purpose
`ifdef MATCHI
    wire matchi_input_active=valid_in;
    wire matchi_output_active=out_valid;
    wire matchi_rnd_active=1'b1; // Validate

    // Logic required to have the signal asserting the validity of
    // the key material (used only for inversion configuration)
    wire matchi_lcol_valid = 1;
`endif


// Control signal to enable to tap values coming from the outside of the core.
// Otherwise, 0 is fed to the input, ensuring that we don't start computing on
// invalid but sensitive data.
wire feed_input;

// Sharing of the plaintext
wire [128*d-1:0] zeros_sh_data_in;
MSKcst #(.d(d),.count(128))
cst_sh_plain(
    .cst(128'b0),
    .out(zeros_sh_data_in)
);

wire [128*d-1:0] gated_sh_data_in;
MSKmux #(.d(d),.count(128))
mux_in_data_holder(
    .sel(feed_input),
    .in_true(sh_data_in),
    .in_false(zeros_sh_data_in),
    .out(gated_sh_data_in)
);

// State datapath
wire state_enable;
wire state_init;
wire state_en_MC;
wire state_en_loop;
wire state_en_loop_r0;
wire state_en_SB_inverse;
wire state_bypass_MC_inverse;
wire state_en_toSB_inverse;

(* verime = "b32_fromK" *)
wire [32*d-1:0] state_sh_4bytes_from_key;
wire [24*d-1:0] state_sh_3bytes_from_key_inverse;
wire [32*d-1:0] sh_4bytes_from_SB;
(* verime = "b32_fromAK" *)
wire [32*d-1:0] state_sh_4bytes_to_SB;

wire [128*d-1:0] sh_data_out_gated;

MSKaes_32bits_state_datapath #(.d(d))
core_data(
    .clk(clk),
    .enable(state_enable),
    .init(state_init),
    .en_MC(state_en_MC),
    .en_loop(state_en_loop),
    .en_loop_r0(state_en_loop_r0),
    .en_SB_inverse(state_en_SB_inverse),
    .bypass_MC_inverse(state_bypass_MC_inverse),
    .en_toSB_inverse(state_en_toSB_inverse),
    .sh_data_in(gated_sh_data_in),
    .sh_4bytes_from_key(state_sh_4bytes_from_key),
    .sh_3bytes_from_key_inverse(state_sh_3bytes_from_key_inverse),
    .sh_4bytes_from_SB(sh_4bytes_from_SB),
    .sh_4bytes_to_SB(state_sh_4bytes_to_SB),
    .sh_data_out(sh_data_out_gated)
);

// Mux gating the sharing of the key
wire [256*d-1:0] cst_sh_key;
MSKcst #(.d(d),.count(256))
cst_sh_key_gadget(
    .cst(256'b0),
    .out(cst_sh_key)
);

wire [256*d-1:0] gated_sh_key;
MSKmux #(.d(d),.count(256))
mux_in_key_holder(
    .sel(feed_input),
    .in_true(sh_key),
    .in_false(cst_sh_key),
    .out(gated_sh_key)
);

///// Key handling
// Round constant control
wire rcon_rst;
wire rcon_mode_256;
wire rcon_mode_192;
wire rcon_update;
wire rcon_inverse;

wire KH_init;
wire KH_enable;
wire KH_loop;
wire KH_add_from_sb;

wire KH_rst_buffer_from_sbox;

wire KH_disable_rot_rcon;
wire KH_enable_pipe_high;
wire KH_feedback_from_high;
wire KH_col7_toSB;

wire [32*d-1:0] KH_sh_4bytes_rot_to_SB;
wire [32*d-1:0] KH_sh_4bytes_from_key;
wire [24*d-1:0] KH_sh_3bytes_from_key_inverse;

MSKaes_32bits_key_datapath #(.d(d))
key_holder(
    .clk(clk),
    .init(KH_init),
    .enable_pipe_low(KH_enable),
    .loop(KH_loop),
    .add_from_sb(KH_add_from_sb),
    .rcon_rst(rcon_rst),
    .rcon_mode_256(rcon_mode_256),
    .rcon_mode_192(rcon_mode_192),
    .rcon_update(rcon_update),
    .rcon_inverse(rcon_inverse),
    .rst_buffer_from_sbox(KH_rst_buffer_from_sbox),
    .disable_rot_rcon(KH_disable_rot_rcon),
    .enable_pipe_high(KH_enable_pipe_high),
    .feedback_from_high(KH_feedback_from_high),
    .col7_toSB(KH_col7_toSB),
    .sh_key(gated_sh_key),
    .sh_last_key_col(sh_last_key_col),
    .sh_4bytes_rot_to_SB(KH_sh_4bytes_rot_to_SB),
    .sh_4bytes_from_SB(sh_4bytes_from_SB),
    .sh_4bytes_to_AK(KH_sh_4bytes_from_key),
    .sh_3bytes_to_AK_inverse(KH_sh_3bytes_from_key_inverse)
);

// Mux to enable key addition
wire [32*d-1:0] zero_mask;
MSKcst #(.d(d),.count(32))
cst_zeros32(
    .cst(32'b0),
    .out(zero_mask)
);

// Muxes enable the key addition in forward and reverse mode
wire enable_key_add;
wire enable_key_add_inverse;

MSKmux #(.d(d),.count(8))
mux_key_en_b0(
    .sel(enable_key_add | enable_key_add_inverse),
    .in_true(KH_sh_4bytes_from_key[0 +: 8*d]),
    .in_false(zero_mask[0 +: 8*d]),
    .out(state_sh_4bytes_from_key[0 +: 8*d])
);

MSKmux #(.d(d),.count(24))
mux_key_en_b123(
    .sel(enable_key_add),
    .in_true(KH_sh_4bytes_from_key[8*d +: 24*d]),
    .in_false(zero_mask[8*d +: 24*d]),
    .out(state_sh_4bytes_from_key[8*d +: 24*d])
);

MSKmux #(.d(d), .count(24))
mux_key_en_inverse(
    .sel(enable_key_add_inverse),
    .in_true(KH_sh_3bytes_from_key_inverse),
    .in_false(zero_mask[0 +: 24*d]),
    .out(state_sh_3bytes_from_key_inverse)
);


// Sboxes
wire [8*d-1:0] bytes_to_SB [4];
(* verime = "B_fromSB" *)
wire [8*d-1:0] bytes_from_SB [4];

wire sbox_valid_in;
wire sbox_inverse;

genvar i;
generate
for(i=0;i<4;i=i+1) begin: gen_sbox_isnt
    gen_sbox #(.d(d))
    sbox_unit(
        .clk(clk),
        .i0(bytes_to_SB[i][0*d +: d]),
        .i1(bytes_to_SB[i][1*d +: d]),
        .i2(bytes_to_SB[i][2*d +: d]),
        .i3(bytes_to_SB[i][3*d +: d]),
        .i4(bytes_to_SB[i][4*d +: d]),
        .i5(bytes_to_SB[i][5*d +: d]),
        .i6(bytes_to_SB[i][6*d +: d]),
        .i7(bytes_to_SB[i][7*d +: d]),
        .rnd_bus0w(rnd_bus0w[i*rnd_bus0 +: rnd_bus0]),
        .rnd_bus1w(rnd_bus1w[i*rnd_bus1 +: rnd_bus1]),
        .rnd_bus2w(rnd_bus2w[i*rnd_bus2 +: rnd_bus2]),
        .rnd_bus3w(rnd_bus3w[i*rnd_bus3 +: rnd_bus3]),
        .inverse(sbox_inverse),
        .o0(bytes_from_SB[i][0*d +: d]),
        .o1(bytes_from_SB[i][1*d +: d]),
        .o2(bytes_from_SB[i][2*d +: d]),
        .o3(bytes_from_SB[i][3*d +: d]),
        .o4(bytes_from_SB[i][4*d +: d]),
        .o5(bytes_from_SB[i][5*d +: d]),
        .o6(bytes_from_SB[i][6*d +: d]),
        .o7(bytes_from_SB[i][7*d +: d])
    );
end
endgenerate

// Mux at the input of the SBOX
wire feed_sb_key;
wire [32*d-1:0] sh_bytes_to_SB;

MSKmux #(.d(d),.count(32))
mux2SB(
    .sel(feed_sb_key),
    .in_true(KH_sh_4bytes_rot_to_SB),
    .in_false(state_sh_4bytes_to_SB),
    .out(sh_bytes_to_SB)
);

// Mux to gate the input of the Sbox when unecessary
wire [32*d-1:0] cst_zeros_sbox;
MSKcst #(.d(d),.count(32))
cst_sb(
    .cst(32'b0),
    .out(cst_zeros_sbox)
);

wire [32*d-1:0] sh_bytes_gated_to_SB;
MSKmux #(.d(d),.count(32))
mux_gate_SB(
    .sel(sbox_valid_in),
    .in_true(sh_bytes_to_SB),
    .in_false(cst_zeros_sbox),
    .out(sh_bytes_gated_to_SB)
);

assign bytes_to_SB[0] = sh_bytes_gated_to_SB[0 +: 8*d];
assign bytes_to_SB[1] = sh_bytes_gated_to_SB[8*d +: 8*d];
assign bytes_to_SB[2] = sh_bytes_gated_to_SB[16*d +: 8*d];
assign bytes_to_SB[3] = sh_bytes_gated_to_SB[24*d +: 8*d];

// Link the value to the input from sboxes
assign sh_4bytes_from_SB[0 +: 8*d] = bytes_from_SB[0];
assign sh_4bytes_from_SB[8*d +: 8*d] = bytes_from_SB[1];
assign sh_4bytes_from_SB[16*d +: 8*d] = bytes_from_SB[2];
assign sh_4bytes_from_SB[24*d +: 8*d] = bytes_from_SB[3];

// Mux at the output, to only output data when required
wire [128*d-1:0] zeros_out;
MSKcst #(.d(d),.count(128))
cst_sh_zeros(
    .cst(128'b0),
    .out(zeros_out)
);

// Mux used to avoid an external module to tap internal data
// during an execution when the output is not valid.
MSKmux #(.d(d),.count(128))
mux_out(
    .sel(out_valid),
    .in_true(sh_data_out_gated),
    .in_false(zeros_out),
    .out(sh_data_out)
);

// FSM
MSKaes_32bits_fsm
fsm_unit(
    .clk(clk),
    .rst(rst),
    .busy(busy),
    .inverse(inverse),
    .key_schedule_only(key_schedule_only),
    .mode_256(mode_256),
    .mode_192(mode_192),
    .rnd_bus0_valid_for_refresh(rnd_bus0_valid_for_rfrsh),
    .valid_in(valid_in),
    .in_ready(in_ready),
    .out_ready(out_ready),
    .out_valid(out_valid),
    .global_init(feed_input),
    .state_enable(state_enable),
    .state_init(state_init),
    .state_en_MC(state_en_MC),
    .state_en_loop(state_en_loop),
    .state_en_loop_r0(state_en_loop_r0),
    .state_en_SB_inverse(state_en_SB_inverse),
    .state_bypass_MC_inverse(state_bypass_MC_inverse),
    .state_en_toSB_inverse(state_en_toSB_inverse),
    .KH_init(KH_init),
    .KH_enable(KH_enable),
    .KH_loop(KH_loop),
    .KH_add_from_sb(KH_add_from_sb),
    .KH_rst_buffer_from_sbox(KH_rst_buffer_from_sbox),
    .KH_last_key_pre_valid(last_key_pre_valid),
    .KH_disable_rot_rcon(KH_disable_rot_rcon),
    .KH_enable_pipe_high(KH_enable_pipe_high),
    .KH_feedback_from_high(KH_feedback_from_high),
    .KH_col7_toSB(KH_col7_toSB),
    .rcon_rst(rcon_rst),
    .rcon_mode_256(rcon_mode_256),
    .rcon_mode_192(rcon_mode_192),
    .rcon_update(rcon_update),
    .rcon_inverse(rcon_inverse),
    .pre_need_rnd(in_ready_rnd),
    .sbox_valid_in(sbox_valid_in),
    .sbox_inverse(sbox_inverse),
    .feed_sb_key(feed_sb_key),
    .enable_key_add(enable_key_add),
    .enable_key_add_inverse(enable_key_add_inverse)
);


endmodule
