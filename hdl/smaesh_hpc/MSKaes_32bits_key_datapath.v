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

(* fv_prop = "PINI", fv_strat = "flatten", fv_order=d *)
module MSKaes_32bits_key_datapath
#
(
    parameter integer d = 2
)
(
    // Global
    clk,
    // Control
    init,
    enable_pipe_low,
    loop,
    add_from_sb,
    rcon_rst,
    rcon_mode_256,
    rcon_mode_192,
    rcon_update,
    rcon_inverse,
    rst_buffer_from_sbox,
    disable_rot_rcon,
    enable_pipe_high,
    feedback_from_high,
    col7_toSB,
    // Data
    sh_key,
    sh_last_key_col,
    sh_4bytes_rot_to_SB,
    sh_4bytes_from_SB,
    sh_4bytes_to_AK,
    sh_3bytes_to_AK_inverse
);

input clk;
input init;
input enable_pipe_low;
input loop;
input add_from_sb;
input rcon_rst;
input rcon_mode_256;
input rcon_mode_192;
input rcon_update;
input rcon_inverse;
input rst_buffer_from_sbox;
input disable_rot_rcon;
input enable_pipe_high;
input feedback_from_high;
input col7_toSB;

input [256*d-1:0] sh_key;
output [32*d-1:0] sh_last_key_col;
output [32*d-1:0] sh_4bytes_rot_to_SB;
(* verime = "key_col_from_SB" *)
input [32*d-1:0] sh_4bytes_from_SB;
(* verime = "key_col_to_AK" *)
output [32*d-1:0] sh_4bytes_to_AK;
output [24*d-1:0] sh_3bytes_to_AK_inverse;

///// RCON addition post Sbox
// Module used to compute the 8bits RCON value
// shared representation of the RCON byte.
wire [8*d-1:0] sh_rcon_b0;
MSKaes_rcon #(.d(d))
rcon_unit(
    .clk(clk),
    .rst(rcon_rst),
    .mode_256(rcon_mode_256),
    .mode_192(rcon_mode_192),
    .update(rcon_update),
    .mask_rcon(1'b1),
    .sh_rcon(sh_rcon_b0),
    .inverse(rcon_inverse)
);

// Reverse the rotation performed at the input of the Sbox for Key material.
// used only for the AES-256 key scheduling
wire [32*d-1:0] sh_4bytes_from_SB_norot;
assign sh_4bytes_from_SB_norot[0 +: 8*d] = sh_4bytes_from_SB[24*d +: 8*d];
assign sh_4bytes_from_SB_norot[8*d +: 8*d] = sh_4bytes_from_SB[0 +: 8*d];
assign sh_4bytes_from_SB_norot[16*d +: 8*d] = sh_4bytes_from_SB[8*d +: 8*d];
assign sh_4bytes_from_SB_norot[24*d +: 8*d] = sh_4bytes_from_SB[16*d +: 8*d];


// XOR used to perform the addition with the first byte
// coming from the sbox (post rotation of the column)
wire [8*d-1:0] added_rcon;
MSKxor #(.d(d),.count(8))
xor_rcon(
    .ina(sh_4bytes_from_SB[0 +: 8*d]),
    .inb(sh_rcon_b0),
    .out(added_rcon)
);
// Reformat the byte from sbox with RCON addition result
wire [32*d-1:0] sh_4bytes_from_SB_rot_rcon;
assign sh_4bytes_from_SB_rot_rcon[0 +: 8*d] = added_rcon;
assign sh_4bytes_from_SB_rot_rcon[8*d +: 8*d] = sh_4bytes_from_SB[8*d +: 8*d];
assign sh_4bytes_from_SB_rot_rcon[16*d +: 8*d] = sh_4bytes_from_SB[16*d +: 8*d];
assign sh_4bytes_from_SB_rot_rcon[24*d +: 8*d] = sh_4bytes_from_SB[24*d +: 8*d];

// Mux to select data from Sbox
// - with RCON addition and rotation (AES128 and AES256)
//   or
// - without (AES256 only)
wire [32*d-1:0] sh_4bytes_from_SB_to_key_update;
MSKmux #(.d(d), .count(32))
inst_mux_rotrcon_vs_raw(
    .sel(disable_rot_rcon),
    .in_true(sh_4bytes_from_SB_norot),
    .in_false(sh_4bytes_from_SB_rot_rcon),
    .out(sh_4bytes_from_SB_to_key_update)
);


// Byte matrix representation of the input key
wire [8*d-1:0] sh_m_key_in[32];
genvar i;
generate
for(i=0;i<32;i=i+1) begin: gen_byte_key_in
    assign sh_m_key_in[i] = sh_key[8*d*i +: 8*d];
end
endgenerate

// Apply the initial permutation
// (required because of the new architecture, in regime the position of
// the key byte are located 1 stage before when the last column is taken)
// Here, the permutation is only applied on the 4 first columns. This is done such that the
// AES-256 is implemented on top of the AES-128 while limiting the additional logic.
wire [8*d-1:0] sh_m_key_in_perm[32];
generate
for(i=0;i<16;i=i+1) begin: gen_byte_key_in_perm
    assign sh_m_key_in_perm[i] = sh_m_key_in[(i+12)%16];
    assign sh_m_key_in_perm[i+16] = sh_m_key_in[i+16];
end
endgenerate

// Byte matrix representation of the holded round key
(* verime = "key_byte" *)
wire [8*d-1:0] sh_m_key[32];
wire [8*d-1:0] to_sh_m_key[32];

generate
for(i=0;i<16;i=i+1) begin: gen_byte_key
    // Reg instance LOW pipe
    MSKregEn #(.d(d),.count(8))
    reg_sh_m_key_low(
        .clk(clk),
        .en(enable_pipe_low),
        .in(to_sh_m_key[i]),
        .out(sh_m_key[i])
    );
    // Reg instance HIGH pipe
    MSKregEn #(.d(d),.count(8))
    reg_sh_m_key_high(
        .clk(clk),
        .en(enable_pipe_high),
        .in(to_sh_m_key[16+i]),
        .out(sh_m_key[16+i])
    );
end
endgenerate
assign sh_last_key_col[0 +: 8*d] = sh_m_key[0];
assign sh_last_key_col[8*d +: 8*d] = sh_m_key[1];
assign sh_last_key_col[16*d +: 8*d] = sh_m_key[2];
assign sh_last_key_col[24*d +: 8*d] = sh_m_key[3];

// Mux at the input of sh_m_key[4:15]
genvar j;
generate
for(i=0;i<4;i=i+1) begin: gen_row_min
    for(j=0;j<2;j=j+1) begin: gen_col_min
        MSKmux #(.d(d),.count(8))
        mux_scan(
            .sel(init),
            .in_true(sh_m_key_in_perm[4*(j+1)+i]),
            .in_false(sh_m_key[(4*(j+2)+i) % 16]),
            .out(to_sh_m_key[4*(j+1)+i])
        );
    end
end
endgenerate

// Mux at the input of sh_m_key[12:15].
generate
for(i=0;i<4;i=i+1) begin: gen_input_col_12_15
    // Mux for the feedback selection between
    // - sh_m_key[0:3], used during the
    //      - key addition in round function (AES-128/256)
    //      - key scheduling algorithm
    // - sh_m_key[16:19], used during the key scheduling of AES-256
    wire [8*d-1:0] feedback_half;
    MSKmux #(.d(d), .count(8))
    mux_feedback_half(
        .sel(feedback_from_high),
        .in_true(sh_m_key[16+i]),
        .in_false(sh_m_key[i]),
        .out(feedback_half)
    );
    // Mux for the initialization
    MSKmux #(.d(d), .count(8))
    mux_scan(
        .sel(init),
        .in_true(sh_m_key_in_perm[12+i]),
        .in_false(feedback_half),
        .out(to_sh_m_key[12+i])
    );
end
endgenerate

// Mux at the input of register sh_m_key[16:31]
generate
for(i=0;i<4;i=i+1)begin: gen_row_16_28
    for(j=0;j<4;j=j+1) begin: gen_byte_row
        MSKmux #(.d(d), .count(8))
        mux_scan(
            .sel(init),
            .in_true(sh_m_key_in_perm[16+i+4*j]),
            .in_false(sh_m_key[(16+i+4*(j+1)) % 32]),
            .out(to_sh_m_key[16+i+4*j])
        );
    end
end
endgenerate

// Input structure for the input of sh_m_key[0:3]
generate
for(i=0;i<4;i=i+1) begin: gen_row_lc_in
    // Mux from SB
    wire [8*d-1:0] mux_add_from_SB;
    MSKmux #(.d(d),.count(8))
    inst_mux_add_from_SB(
        .sel(add_from_sb),
        .in_true(sh_4bytes_from_SB_to_key_update[i*8*d +: 8*d]),
        .in_false(sh_m_key[i]),
        .out(mux_add_from_SB)
    );
    // XOR for key update
    wire [8*d-1:0] xor_update;
    MSKxor #(.d(d),.count(8))
    inst_xor_xor_update(
        .ina(mux_add_from_SB),
        .inb(sh_m_key[4+i]),
        .out(xor_update)
    );

    // Sharing of zeros, going to the register holding from Sbox
    wire [8*d-1:0] zeros_sh_from_sbox;
    MSKcst #(.d(d),.count(8))
    cst_sh_plain(
        .cst(8'b0),
        .out(zeros_sh_from_sbox)
    );

    // Xor for the update before going to the buffer, used in decryption
    wire [8*d-1:0] buffer_from_SB;
    wire [8*d-1:0] incremented_buffer;
    MSKxor #(.d(d), .count(8))
    xor_increment_inv(
        .ina(buffer_from_SB),
        .inb(mux_add_from_SB),
        .out(incremented_buffer)
    );

    // Mux before the reg holding data from sbox (for reverse operation only)
    wire [8*d-1:0] to_buffer_from_SB;
    MSKmux #(.d(d), .count(8))
    mux_in_buffer_from_SB(
        .sel(rst_buffer_from_sbox),
        .in_true(zeros_sh_from_sbox),
        .in_false(incremented_buffer),
        .out(to_buffer_from_SB)
    );

    // Register to act as a buffer for the data from Sboxes
    MSKreg #(.d(d), .count(8))
    reg_buffer_sbox(
        .clk(clk),
        .in(to_buffer_from_SB),
        .out(buffer_from_SB)
    );

    // Xor required only for the reverse operation
    wire [8*d-1:0] xor_update_with_inverse;
    MSKxor #(.d(d), .count(8))
    inst_xor_update_inverse(
        .ina(xor_update),
        .inb(buffer_from_SB),
        .out(xor_update_with_inverse)
    );

    // Mux for loop
    wire [8*d-1:0] mux_loop;
    MSKmux #(.d(d),.count(8))
    inst_mux_loop(
        .sel(loop),
        .in_true(sh_m_key[4+i]),
        .in_false(sh_m_key_in_perm[i]),
        .out(mux_loop)
    );
    // Mux input of reg
    MSKmux #(.d(d),.count(8))
    inst_mux_to_sh_m_key(
        .sel(init || loop),
        .in_true(mux_loop),
        .in_false(xor_update_with_inverse),
        .out(to_sh_m_key[i])
    );
end
endgenerate

// Mux structure for forward versus inverse data to sbox
wire [8*d-1:0] toSB_forward_vs_inverse [4];
generate
for(i=0;i<4;i=i+1) begin: gen_mux_layer_forward_vs_inverse
    // Xor between first and last column
    wire [8*d-1:0] xor_c0_c3;
    MSKxor #(.d(d), .count(8))
    inst_xor_inverse_to_sbox(
        .ina(sh_m_key[i]),
        .inb(sh_m_key[12+i]),
        .out(xor_c0_c3)
    );
    // Mux for selection between inverse versus forward
    MSKmux #(.d(d),.count(8))
    inst_mux_inverse_to_sbox(
        .sel(rcon_inverse & ~(rcon_mode_256 | rcon_mode_192)),
        .in_true(xor_c0_c3),
        .in_false(sh_m_key[i]),
        .out(toSB_forward_vs_inverse[i])
    );
end
endgenerate

// Mux to select either the last column (used only in the first cycle of
// AES-256 encryption), or the values from the first column
wire [8*d-1:0] sh_bytes_to_SB_sel_lastcol [4];
generate
for(i=0;i<4;i=i+1) begin: gen_mux_byte_to_SB
    MSKmux #(.d(d),.count(8))
    inst_mux_initm256(
        .sel(col7_toSB),
        .in_true(sh_m_key[28+i]),
        .in_false(toSB_forward_vs_inverse[i]),
        .out(sh_bytes_to_SB_sel_lastcol[i])
    );
end
endgenerate

// Output assign
assign sh_4bytes_rot_to_SB[0 +: 8*d] = sh_bytes_to_SB_sel_lastcol[1];
assign sh_4bytes_rot_to_SB[8*d +: 8*d] = sh_bytes_to_SB_sel_lastcol[2];
assign sh_4bytes_rot_to_SB[16*d +: 8*d] = sh_bytes_to_SB_sel_lastcol[3];
assign sh_4bytes_rot_to_SB[24*d +: 8*d] = sh_bytes_to_SB_sel_lastcol[0];

assign sh_4bytes_to_AK = {sh_m_key[15],sh_m_key[10],sh_m_key[5],sh_m_key[0]};
assign sh_3bytes_to_AK_inverse = {sh_m_key[3],sh_m_key[2],sh_m_key[1]};

endmodule
