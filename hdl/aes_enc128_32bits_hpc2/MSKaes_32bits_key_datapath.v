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
    parameter d = 2
)
(
    // Global
    clk,
    // Control
    init,
    enable,
    loop,
    add_from_sb,
    rcon_rst,
    rcon_update,
    // Data
    sh_key,
    sh_4bytes_rot_to_SB,
    sh_4bytes_from_SB,
    sh_4bytes_to_AK
);

input clk;
input init;
input enable;
input loop;
input add_from_sb;
input rcon_rst;
input rcon_update;
input [128*d-1:0] sh_key;
output [32*d-1:0] sh_4bytes_rot_to_SB;
(* verime = "key_col_from_SB" *)
input [32*d-1:0] sh_4bytes_from_SB;
(* verime = "key_col_to_AK" *)
output [32*d-1:0] sh_4bytes_to_AK;

///// RCON addition post Sbox
// Module used to compute the 8bits RCON value
// shared representation of the RCON byte. 
wire [8*d-1:0] sh_rcon_b0;
MSKaes_rcon #(.d(d))
rcon_unit(
    .clk(clk),
    .rst(rcon_rst),
    .update(rcon_update),
    .mask_rcon(1'b1),
    .sh_rcon(sh_rcon_b0)
);
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


// Byte matrix representation of the input key
wire [8*d-1:0] sh_m_key_in[15:0];
genvar i;
generate
for(i=0;i<16;i=i+1) begin: byte_key_in
    assign sh_m_key_in[i] = sh_key[8*d*i +: 8*d];
end
endgenerate

// Byte matrix representation of the holded round key
(* verime = "key_byte" *)
wire [8*d-1:0] sh_m_key[15:0];
wire [8*d-1:0] to_sh_m_key[15:0];

generate
for(i=0;i<16;i=i+1) begin: byte_key
    // Reg instance
    MSKregEn #(.d(d),.count(8))
    reg_sh_m_key(
        .clk(clk),
        .en(enable),
        .in(to_sh_m_key[i]),
        .out(sh_m_key[i])
    );
end
endgenerate

// Mux at the input of sh_m_key[0:11]
genvar j;
generate
for(i=0;i<4;i=i+1) begin: row_min
    for(j=0;j<3;j=j+1) begin: col_min
        MSKmux #(.d(d),.count(8))
        mux_scan(
            .sel(init),
            .in_true(sh_m_key_in[4*j+i]),
            .in_false(sh_m_key[4*(j+1)+i]),
            .out(to_sh_m_key[4*j+i])
        );        
    end
end
endgenerate

// Input structure for the input of sh_m_key[12:15]
generate
for(i=0;i<4;i=i+1) begin: row_lc_in
    // Mux from SB 
    wire [8*d-1:0] mux_add_from_SB; 
    MSKmux #(.d(d),.count(8))
    inst_mux_add_from_SB(
        .sel(add_from_sb),
        .in_true(sh_4bytes_from_SB_rot_rcon[i*8*d +: 8*d]),
        .in_false(sh_m_key[12+i]),
        .out(mux_add_from_SB)
    );
    // XOR for key update 
    wire [8*d-1:0] xor_update;
    MSKxor #(.d(d),.count(8))
    inst_xor_xor_update(
        .ina(mux_add_from_SB),
        .inb(sh_m_key[i]),
        .out(xor_update)
    );
    // Mux for loop
    wire [8*d-1:0] mux_loop;
    MSKmux #(.d(d),.count(8))
    inst_mux_loop(
        .sel(loop),
        .in_true(sh_m_key[i]),
        .in_false(sh_m_key_in[12+i]),
        .out(mux_loop)
    );
    // Mux input of reg
    MSKmux #(.d(d),.count(8))
    inst_mux_to_sh_m_key(
        .sel(init || loop),
        .in_true(mux_loop),
        .in_false(xor_update),
        .out(to_sh_m_key[12+i])
    );
end
endgenerate

// Output assign 
assign sh_4bytes_rot_to_SB[0 +: 8*d] = sh_m_key[13];
assign sh_4bytes_rot_to_SB[8*d +: 8*d] = sh_m_key[14];
assign sh_4bytes_rot_to_SB[16*d +: 8*d] = sh_m_key[15];
assign sh_4bytes_rot_to_SB[24*d +: 8*d] = sh_m_key[12];

assign sh_4bytes_to_AK = {sh_m_key[15],sh_m_key[10],sh_m_key[5],sh_m_key[0]};

endmodule
