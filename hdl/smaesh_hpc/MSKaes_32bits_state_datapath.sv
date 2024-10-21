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
module MSKaes_32bits_state_datapath
#
(
    parameter integer d=2
)
(
    // Global
    clk,
    enable,
    // Routing control
    init,
    en_MC,
    en_loop,
    en_loop_r0,
    en_SB_inverse,
    bypass_MC_inverse,
    en_toSB_inverse,
    // Data
    sh_data_in,
    sh_4bytes_from_key,
    sh_3bytes_from_key_inverse,
    sh_4bytes_from_SB,
    sh_4bytes_to_SB,
    sh_data_out
);

// IOs
input clk;
input enable;

input init;
input en_MC;
input en_loop;
input en_loop_r0;
input en_SB_inverse;
input bypass_MC_inverse;
input en_toSB_inverse;

input [128*d-1:0] sh_data_in;
input [32*d-1:0] sh_4bytes_from_key;
input [24*d-1:0] sh_3bytes_from_key_inverse;
input [32*d-1:0] sh_4bytes_from_SB;
output [32*d-1:0] sh_4bytes_to_SB;
output [128*d-1:0] sh_data_out;

// Byte matrix representation of the input plaintext
wire [8*d-1:0] sh_m_plain[16];
genvar i;
generate
for(i=0;i<16;i=i+1) begin: gen_byte_pt
    assign sh_m_plain[i] = sh_data_in[8*d*i +: 8*d];
end
endgenerate

// Mixcolumns combinatorial logic bloc dealing with the 32 shared bits
// coming from the Sbox
(* verime = "b32_fromMC" *)
wire [32*d-1:0] sh_4bytes_from_MC;
// Mixcolumn unit
MSKaesMC #(.d(d))
MC_unit(
    .a0(sh_4bytes_from_SB[0 +: 8*d]),
    .a1(sh_4bytes_from_SB[8*d +: 8*d]),
    .a2(sh_4bytes_from_SB[16*d +: 8*d]),
    .a3(sh_4bytes_from_SB[24*d +: 8*d]),
    .b0(sh_4bytes_from_MC[0 +: 8*d]),
    .b1(sh_4bytes_from_MC[8*d +: 8*d]),
    .b2(sh_4bytes_from_MC[16*d +: 8*d]),
    .b3(sh_4bytes_from_MC[24*d +: 8*d])
);

// Inverse Mixcolumns combinatorial logic block dealing with 32-bit column from the state
wire [32*d-1:0] sh_4bytes_from_MC_inverse;
wire [32*d-1:0] sh_4bytes_to_MC_inverse;
MSKaesMC_inverse #(.d(d))
MC_unit_inverse(
    .a0(sh_4bytes_to_MC_inverse[0 +: 8*d]),
    .a1(sh_4bytes_to_MC_inverse[8*d +: 8*d]),
    .a2(sh_4bytes_to_MC_inverse[16*d +: 8*d]),
    .a3(sh_4bytes_to_MC_inverse[24*d +: 8*d]),
    .b0(sh_4bytes_from_MC_inverse[0 +: 8*d]),
    .b1(sh_4bytes_from_MC_inverse[8*d +: 8*d]),
    .b2(sh_4bytes_from_MC_inverse[16*d +: 8*d]),
    .b3(sh_4bytes_from_MC_inverse[24*d +: 8*d])
);

// Generate the state register + input output signals
wire [8*d-1:0] sh_reg_in [16];
wire [8*d-1:0] sh_reg_out [16];
wire [15:0] en_pipe;

generate
for(i=0;i<16;i=i+1) begin: gen_scanff_state
    MSKscanReg #(.d(d),.count(8))
    sff_byte(
        .clk(clk),
        .en(en_pipe[i]),
        .scan_en(!init),
        .in_d(sh_m_plain[i]),
        .in_scan(sh_reg_in[i]),
        .out_q(sh_reg_out[i])
    );
end
endgenerate

// ########## Assign the routing for the first row
assign sh_reg_in[0] = sh_reg_out[4];
assign sh_reg_in[4] = sh_reg_out[8];
assign sh_reg_in[8] = sh_reg_out[12];

wire [8*d-1:0] sh_mux_r03_1;
MSKmux #(.d(d),.count(8))
muxr03_2(
    .sel(en_MC),
    .in_true(sh_4bytes_from_MC[0 +: 8*d]),
    .in_false(sh_4bytes_from_SB[0 +: 8*d]),
    .out(sh_mux_r03_1)
);

wire [8*d-1:0] sh_added_rkey_0;
MSKxor #(.d(d),.count(8))
xor00(
    .ina(sh_reg_out[0]),
    .inb(sh_4bytes_from_key[0 +: 8*d]),
    .out(sh_added_rkey_0)
);

wire [8*d-1:0] sh_mux_r03_0;
MSKmux #(.d(d),.count(8))
muxr03_1(
    .sel(en_loop_r0),
    .in_true(sh_added_rkey_0),
    .in_false(sh_mux_r03_1),
    .out(sh_reg_in[12])
);

assign sh_4bytes_to_MC_inverse[0 +: 8*d] = sh_added_rkey_0;

// ########## Assign the routing for the second row
// Xor to add the key in direct and inverse operation
wire [8*d-1:0] sh_added_rkey_1;
MSKxor #(.d(d),.count(8))
xor11(
    .ina(sh_reg_out[5]),
    .inb(sh_4bytes_from_key[8*d +: 8*d]),
    .out(sh_added_rkey_1)
);

// Mux to feed back the data from the Sbox in inverse operation
wire [8*d-1:0] sh_fromSB_inverse_11;
MSKmux #(.d(d), .count(8))
mux11_SBinv(
    .sel(en_SB_inverse),
    .in_true(sh_4bytes_from_SB[8*d +: 8*d]),
    .in_false(sh_added_rkey_1),
    .out(sh_fromSB_inverse_11)
);

assign sh_reg_in[1] = sh_fromSB_inverse_11;
assign sh_reg_in[5] = sh_reg_out[9];
assign sh_reg_in[9] = sh_reg_out[13];

// Mux selecting from SB or from MC
wire [8*d-1:0] sh_mux_r13_1;
MSKmux #(.d(d),.count(8))
muxr13_2(
    .sel(en_MC),
    .in_true(sh_4bytes_from_MC[8*d +: 8*d]),
    .in_false(sh_4bytes_from_SB[8*d +: 8*d]),
    .out(sh_mux_r13_1)
);

// Xor to add the inverse round key for inverse operation
wire [8*d-1:0] sh_added_rkeyinv_1;
MSKxor #(.d(d),.count(8))
xor_r10_inv(
    .ina(sh_reg_out[1]),
    .inb(sh_3bytes_from_key_inverse[0 +: 8*d]),
    .out(sh_added_rkeyinv_1)
);
assign sh_4bytes_to_MC_inverse[8*d +: 8*d] = sh_added_rkeyinv_1;

// Mux from loop feedback
wire [8*d-1:0] sh_mux_r13_0;
MSKmux #(.d(d),.count(8))
muxr13_1(
    .sel(en_loop),
    .in_true(sh_added_rkeyinv_1),
    .in_false(sh_mux_r13_1),
    .out(sh_reg_in[13])
);

// ########## Assign the routing for the third row
assign sh_reg_in[2] = sh_reg_out[6];

// Xor for key addition in the forward operation
wire [8*d-1:0] sh_added_rkey_2;
MSKxor #(.d(d),.count(8))
xor22(
    .ina(sh_reg_out[10]),
    .inb(sh_4bytes_from_key[16*d +: 8*d]),
    .out(sh_added_rkey_2)
);

// Mux to feed back the data from the Sbox in inverse operation
wire [8*d-1:0] sh_fromSB_inverse_22;
MSKmux #(.d(d), .count(8))
mux22_SBinv(
    .sel(en_SB_inverse),
    .in_true(sh_4bytes_from_SB[16*d +: 8*d]),
    .in_false(sh_added_rkey_2),
    .out(sh_fromSB_inverse_22)
);

assign sh_reg_in[6] = sh_fromSB_inverse_22;
assign sh_reg_in[10] = sh_reg_out[14];

// Mux to select from SB or from MC
wire [8*d-1:0] sh_mux_r23_1;
MSKmux #(.d(d),.count(8))
muxr23_2(
    .sel(en_MC),
    .in_true(sh_4bytes_from_MC[16*d +: 8*d]),
    .in_false(sh_4bytes_from_SB[16*d +: 8*d]),
    .out(sh_mux_r23_1)
);

// Xor to add the inverse round key for inverse operation
wire [8*d-1:0] sh_added_rkeyinv_2;
MSKxor #(.d(d),.count(8))
xor_r22_inv(
    .ina(sh_reg_out[2]),
    .inb(sh_3bytes_from_key_inverse[8*d +: 8*d]),
    .out(sh_added_rkeyinv_2)
);

assign sh_4bytes_to_MC_inverse[16*d +: 8*d] = sh_added_rkeyinv_2;

// Mux for loop feedback
wire [8*d-1:0] sh_mux_r23_0;
MSKmux #(.d(d),.count(8))
muxr23_1(
    .sel(en_loop),
    .in_true(sh_added_rkeyinv_2),
    .in_false(sh_mux_r23_1),
    .out(sh_reg_in[14])
);

// ########## Assign the routing for the fourth row
assign sh_reg_in[3] = sh_reg_out[7];
assign sh_reg_in[7] = sh_reg_out[11];

// Xor used in round key addition for forward operation
wire [8*d-1:0] sh_added_rkey_3;
MSKxor #(.d(d),.count(8))
xor33(
    .ina(sh_reg_out[15]),
    .inb(sh_4bytes_from_key[24*d +: 8*d]),
    .out(sh_added_rkey_3)
);

// Mux to feed back the data from the Sbox in inverse operation
wire [8*d-1:0] sh_fromSB_inverse_33;
MSKmux #(.d(d), .count(8))
mux33_SBinv(
    .sel(en_SB_inverse),
    .in_true(sh_4bytes_from_SB[24*d +: 8*d]),
    .in_false(sh_added_rkey_3),
    .out(sh_fromSB_inverse_33)
);

assign sh_reg_in[11] = sh_fromSB_inverse_33;

// Mux to select from MC of from SB
wire [8*d-1:0] sh_mux_r33_1;
MSKmux #(.d(d),.count(8))
muxr33_2(
    .sel(en_MC),
    .in_true(sh_4bytes_from_MC[24*d +: 8*d]),
    .in_false(sh_4bytes_from_SB[24*d +: 8*d]),
    .out(sh_mux_r33_1)
);

// Xor to add the inverse round key for inverse operation
wire [8*d-1:0] sh_added_rkeyinv_3;
MSKxor #(.d(d),.count(8))
xor_r33_inv(
    .ina(sh_reg_out[3]),
    .inb(sh_3bytes_from_key_inverse[16*d +: 8*d]),
    .out(sh_added_rkeyinv_3)
);

assign sh_4bytes_to_MC_inverse[24*d +: 8*d] = sh_added_rkeyinv_3;

wire [8*d-1:0] sh_mux_r33_0;
MSKmux #(.d(d),.count(8))
muxr33_1(
    .sel(en_loop),
    .in_true(sh_added_rkeyinv_3),
    .in_false(sh_mux_r33_1),
    .out(sh_reg_in[15])
);

// Assign the enable signal to the pipe
generate
for(i=0;i<4;i=i+1) begin: gen_cols_en_sig
    assign en_pipe[i*4] = enable;
    assign en_pipe[i*4+1] = enable;
    assign en_pipe[i*4+2] = enable;
    assign en_pipe[i*4+3] = enable;
end
endgenerate

// Mux structure around the MC inverse core
wire [32*d-1:0] sh_4bytes_toSB_inverse;
MSKmux #(.d(d), .count(32))
mux_bypass_mcinverse(
    .sel(bypass_MC_inverse),
    .in_true(sh_4bytes_to_MC_inverse),
    .in_false(sh_4bytes_from_MC_inverse),
    .out(sh_4bytes_toSB_inverse)
);

// Mux to select the 4 bytes going to the Sbox
wire [32*d-1:0] sh_4bytes_toSB_forward = {
    sh_added_rkey_3,
    sh_added_rkey_2,
    sh_added_rkey_1,
    sh_added_rkey_0
};
MSKmux #(.d(d), .count(32))
mux_selection_to_SB(
    .sel(en_toSB_inverse),
    .in_true(sh_4bytes_toSB_inverse),
    .in_false(sh_4bytes_toSB_forward),
    .out(sh_4bytes_to_SB)
);

// Assign ciphertext
generate
for(i=0;i<16;i=i+1) begin: gen_cipher_byte
    assign sh_data_out[8*d*i +: 8*d] = sh_reg_out[i];
end
endgenerate

endmodule
