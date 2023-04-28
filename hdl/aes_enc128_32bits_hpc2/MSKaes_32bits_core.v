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
(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module MSKaes_32bits_core
#
(
    parameter d=2
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
    cipher_valid,
    // Active high when the output can be fetched. If cipher_valid and
    // out_ready are both high, the ciphertext is dropped from the core.
    out_ready,
    //// Data
    // Masked plaintext (bit-compact representation). Valid when valid_in is high.
    sh_plaintext,
    // Masked key (bit-compact representation). Valid when valid_in is high.
    sh_key,
    // Masked ciphertext (bit-compact representation). Valid when cipher_valid is high.
    sh_ciphertext,
    // Randomness busses (required for the Sboxes). These busses must contain
    // fresh randomness for every cycle where the core is computing, which is
    // signaled by a HIGH value on in_ready_rnd.
    rnd_bus0,
    rnd_bus2,
    rnd_bus3,
    rnd_bus4,
    in_ready_rnd
);

`include "MSKand_HPC2.vh"

// IOs Ports
(* fv_type="control" *)
input rst;
(* fv_type="clock" *)
input clk;
(* fv_type="control" *)
output busy;
(* fv_type="control" *)
input valid_in;
(* fv_type="control" *)
output in_ready;
(* fv_type="control" *)
output cipher_valid;
(* fv_type="control" *)
input out_ready;

(* fv_type="sharing", fv_latency=0, fv_count=128 *)
input [128*d-1:0] sh_plaintext;
(* fv_type="sharing", fv_latency=0, fv_count=128 *)
input [128*d-1:0] sh_key;
(* fv_type="sharing", fv_latency=106, fv_count=128 *)
output [128*d-1:0] sh_ciphertext;

(* fv_type="random", fv_count=0, fv_rnd_count_0=4*9*and_pini_nrnd *)
input [4*9*and_pini_nrnd-1:0] rnd_bus0;
(* fv_type="random", fv_count=0, fv_rnd_count_0=4*3*and_pini_nrnd *)
input [4*3*and_pini_nrnd-1:0] rnd_bus2;
(* fv_type="random", fv_count=0, fv_rnd_count_0=4*4*and_pini_nrnd *)
input [4*4*and_pini_nrnd-1:0] rnd_bus3;
(* fv_type="random", fv_count=0, fv_rnd_count_0=4*18*and_pini_nrnd *)
input [4*18*and_pini_nrnd-1:0] rnd_bus4;

(* fv_type="control" *)
output in_ready_rnd;

// Control signal to enable to tap values coming from the outside of the core.
// Otherwise, 0 is fed to the input, ensuring that we don't start computing on
// invalid but sensitive data.
wire feed_input;

// Sharing of the plaintext
wire [128*d-1:0] zeros_sh_plaintext;
MSKcst #(.d(d),.count(128))
cst_sh_plain(
    .cst(128'b0),
    .out(zeros_sh_plaintext)
);

wire [128*d-1:0] gated_sh_plaintext;
MSKmux #(.d(d),.count(128))
mux_in_data_holder(
    .sel(feed_input),
    .in_true(sh_plaintext),
    .in_false(zeros_sh_plaintext),
    .out(gated_sh_plaintext)
);

// State datapath
wire state_enable;
wire state_init;
wire state_en_MC;
wire state_en_loop;

(* verime = "b32_fromK" *)
wire [32*d-1:0] state_sh_4bytes_from_key;
wire [32*d-1:0] sh_4bytes_from_SB;
(* verime = "b32_fromAK" *)
wire [32*d-1:0] state_sh_4bytes_to_SB;

wire [128*d-1:0] sh_ciphertext_out;

MSKaes_32bits_state_datapath #(.d(d))
core_data(
    .clk(clk),
    .enable(state_enable),
    .init(state_init),
    .en_MC(state_en_MC),
    .en_loop(state_en_loop),
    .sh_plaintext(gated_sh_plaintext),
    .sh_4bytes_from_key(state_sh_4bytes_from_key),
    .sh_4bytes_from_SB(sh_4bytes_from_SB),
    .sh_4bytes_to_SB(state_sh_4bytes_to_SB),
    .sh_ciphertext(sh_ciphertext_out)
);

// Mux gating the sharing of the key
wire [128*d-1:0] cst_sh_key;
MSKcst #(.d(d),.count(128))
cst_sh_key_gadget(
    .cst(128'b0),
    .out(cst_sh_key)
);

wire [128*d-1:0] gated_sh_key;
MSKmux #(.d(d),.count(128))
mux_in_key_holder(
    .sel(feed_input),
    .in_true(sh_key),
    .in_false(cst_sh_key),
    .out(gated_sh_key)
);

///// Key handling 
// Round constant control 
wire rcon_rst;
wire rcon_update;

wire KH_init;
wire KH_enable;
wire KH_loop;
wire KH_add_from_sb;

wire [32*d-1:0] KH_sh_4bytes_rot_to_SB;
wire [32*d-1:0] KH_sh_4bytes_from_key;

MSKaes_32bits_key_datapath #(.d(d))
key_holder(
    .clk(clk),
    .init(KH_init),
    .enable(KH_enable),
    .loop(KH_loop),
    .add_from_sb(KH_add_from_sb),
    .rcon_rst(rcon_rst),
    .rcon_update(rcon_update),
    .sh_key(gated_sh_key),
    .sh_4bytes_rot_to_SB(KH_sh_4bytes_rot_to_SB),
    .sh_4bytes_from_SB(sh_4bytes_from_SB),
    .sh_4bytes_to_AK(KH_sh_4bytes_from_key)
);

// Mux to enable key addition
wire [32*d-1:0] zero_mask;
MSKcst #(.d(d),.count(32))
cst_zeros32(
    .cst(32'b0),
    .out(zero_mask)
);

wire enable_key_add;
MSKmux #(.d(d),.count(32))
mux_key_en(
    .sel(enable_key_add),
    .in_true(KH_sh_4bytes_from_key),
    .in_false(zero_mask),
    .out(state_sh_4bytes_from_key)
);


// Sboxes  
wire [8*d-1:0] bytes_to_SB [3:0];
(* verime = "B_fromSB" *)
wire [8*d-1:0] bytes_from_SB [3:0];

wire sbox_valid_in;

genvar i;
generate
for(i=0;i<4;i=i+1) begin: sbox_isnt
    bp_aes_sbox_msk_noctrl_noenable #(.d(d))
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
        .rnd_bus0(rnd_bus0[i*9*and_pini_nrnd +: 9*and_pini_nrnd]),
        .rnd_bus2(rnd_bus2[i*3*and_pini_nrnd +: 3*and_pini_nrnd]),
        .rnd_bus3(rnd_bus3[i*4*and_pini_nrnd +: 4*and_pini_nrnd]),
        .rnd_bus4(rnd_bus4[i*18*and_pini_nrnd +: 18*and_pini_nrnd]),
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
    .sel(cipher_valid),
    .in_true(sh_ciphertext_out),
    .in_false(zeros_out),
    .out(sh_ciphertext)
);

// FSM
MSKaes_32bits_fsm
fsm_unit(
    .clk(clk),
    .rst(rst),
    .busy(busy),
    .valid_in(valid_in),
    .in_ready(in_ready),
    .out_ready(out_ready),
    .cipher_valid(cipher_valid),
    .global_init(feed_input),
    .state_enable(state_enable),
    .state_init(state_init),
    .state_en_MC(state_en_MC),
    .state_en_loop(state_en_loop),
    .KH_init(KH_init),
    .KH_enable(KH_enable),
    .KH_loop(KH_loop),
    .KH_add_from_sb(KH_add_from_sb),
    .rcon_rst(rcon_rst),
    .rcon_update(rcon_update),
    .pre_need_rnd(in_ready_rnd),
    .sbox_valid_in(sbox_valid_in),
    .feed_sb_key(feed_sb_key),
    .enable_key_add(enable_key_add)
);


endmodule
