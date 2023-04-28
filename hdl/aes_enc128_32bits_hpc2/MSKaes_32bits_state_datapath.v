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
    parameter d=2
)
(
    // Global
    clk,
    enable,
    // Routing control
    init,
    en_MC,
    en_loop,
    // Data
    sh_plaintext,
    sh_4bytes_from_key,
    sh_4bytes_from_SB,
    sh_4bytes_to_SB,
    sh_ciphertext
);

// IOs
input clk;
input enable;

input init;
input en_MC;
input en_loop;

input [128*d-1:0] sh_plaintext;
input [32*d-1:0] sh_4bytes_from_key;
input [32*d-1:0] sh_4bytes_from_SB;
output [32*d-1:0] sh_4bytes_to_SB;
output [128*d-1:0] sh_ciphertext;

// Byte matrix representation of the input plaintext
wire [8*d-1:0] sh_m_plain[15:0];
genvar i;
generate
for(i=0;i<16;i=i+1) begin: byte_pt
    assign sh_m_plain[i] = sh_plaintext[8*d*i +: 8*d];
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

// Generate the state register + input output signals    
wire [8*d-1:0] sh_reg_in [15:0];
wire [8*d-1:0] sh_reg_out [15:0];
wire [15:0] en_pipe;

generate
for(i=0;i<16;i=i+1) begin: scanff_state  
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

// Assign the routing for the first row
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
    .sel(en_loop),
    .in_true(sh_added_rkey_0),
    .in_false(sh_mux_r03_1),
    .out(sh_reg_in[12])
);

// Assign the routing for the second row
wire [8*d-1:0] sh_added_rkey_1;
MSKxor #(.d(d),.count(8))
xor11(
    .ina(sh_reg_out[5]),
    .inb(sh_4bytes_from_key[8*d +: 8*d]),
    .out(sh_added_rkey_1)
);
assign sh_reg_in[1] = sh_added_rkey_1;

assign sh_reg_in[5] = sh_reg_out[9];
assign sh_reg_in[9] = sh_reg_out[13];

wire [8*d-1:0] sh_mux_r13_1;
MSKmux #(.d(d),.count(8))
muxr13_2(
    .sel(en_MC),
    .in_true(sh_4bytes_from_MC[8*d +: 8*d]),
    .in_false(sh_4bytes_from_SB[8*d +: 8*d]),
    .out(sh_mux_r13_1)
);

wire [8*d-1:0] sh_mux_r13_0;
MSKmux #(.d(d),.count(8))
muxr13_1(
    .sel(en_loop),
    .in_true(sh_reg_out[1]),
    .in_false(sh_mux_r13_1),
    .out(sh_reg_in[13])
);

// Assign the routing for the third row
assign sh_reg_in[2] = sh_reg_out[6];

wire [8*d-1:0] sh_added_rkey_2;
MSKxor #(.d(d),.count(8))
xor22(
    .ina(sh_reg_out[10]),
    .inb(sh_4bytes_from_key[16*d +: 8*d]),
    .out(sh_added_rkey_2)
);
assign sh_reg_in[6] = sh_added_rkey_2;

assign sh_reg_in[10] = sh_reg_out[14];

wire [8*d-1:0] sh_mux_r23_1;
MSKmux #(.d(d),.count(8))
muxr23_2(
    .sel(en_MC),
    .in_true(sh_4bytes_from_MC[16*d +: 8*d]),
    .in_false(sh_4bytes_from_SB[16*d +: 8*d]),
    .out(sh_mux_r23_1)
);

wire [8*d-1:0] sh_mux_r23_0;
MSKmux #(.d(d),.count(8))
muxr23_1(
    .sel(en_loop),
    .in_true(sh_reg_out[2]),
    .in_false(sh_mux_r23_1),
    .out(sh_reg_in[14])
);

// Assign the routing for the fourth row
assign sh_reg_in[3] = sh_reg_out[7];
assign sh_reg_in[7] = sh_reg_out[11];

wire [8*d-1:0] sh_added_rkey_3;
MSKxor #(.d(d),.count(8))
xor33(
    .ina(sh_reg_out[15]),
    .inb(sh_4bytes_from_key[24*d +: 8*d]),
    .out(sh_added_rkey_3)
);

assign sh_reg_in[11] = sh_added_rkey_3;

wire [8*d-1:0] sh_mux_r33_1;
MSKmux #(.d(d),.count(8))
muxr33_2(
    .sel(en_MC),
    .in_true(sh_4bytes_from_MC[24*d +: 8*d]),
    .in_false(sh_4bytes_from_SB[24*d +: 8*d]),
    .out(sh_mux_r33_1)
);

wire [8*d-1:0] sh_mux_r33_0;
MSKmux #(.d(d),.count(8))
muxr33_1(
    .sel(en_loop),
    .in_true(sh_reg_out[3]),
    .in_false(sh_mux_r33_1),
    .out(sh_reg_in[15])
);


// Assign the enable signal to the pipe
generate
for(i=0;i<4;i=i+1) begin: cols_en_sig
    assign en_pipe[i*4] = enable;
    assign en_pipe[i*4+1] = enable; 
    assign en_pipe[i*4+2] = enable; 
    assign en_pipe[i*4+3] = enable; 
end
endgenerate

// Assign the output
assign sh_4bytes_to_SB[0 +: 8*d] = sh_added_rkey_0;
assign sh_4bytes_to_SB[8*d +: 8*d] = sh_added_rkey_1;
assign sh_4bytes_to_SB[16*d +: 8*d] = sh_added_rkey_2;
assign sh_4bytes_to_SB[24*d +: 8*d] = sh_added_rkey_3;

// Assign ciphertext
generate
for(i=0;i<16;i=i+1) begin: cipher_byte
    assign sh_ciphertext[8*d*i +: 8*d] = sh_reg_out[i];
end
endgenerate

endmodule
