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

// Fully pipeline PINI AES Sbox (no inverse) in 6 clock cycles.
// This file has been partially generated using  hpc_veriloger.py script (see Makefile for parameters).
(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module bp_aes_sbox_msk_noctrl_noenable
#
(
    parameter d=2
)
(
    	// Circuit inputs IOs
	clk,
	i0,
	i1,
	i2,
	i3,
	i4,
	i5,
	i6,
	i7,
	rnd_bus0,
	rnd_bus2,
	rnd_bus3,
	rnd_bus4,
	// Circuit outputs IOs
	o0,
	o1,
	o2,
	o3,
	o4,
	o5,
	o6,
	o7

);

`include "MSKand_HPC2.vh"

// Inputs ports
(* fv_type="clock" *)
input clk;
(* fv_type="sharing", fv_latency=0, fv_count=1 *)
input [d-1:0] i0;
(* fv_type="sharing", fv_latency=0, fv_count=1 *)
input [d-1:0] i1;
(* fv_type="sharing", fv_latency=0, fv_count=1 *)
input [d-1:0] i2;
(* fv_type="sharing", fv_latency=0, fv_count=1 *)
input [d-1:0] i3;
(* fv_type="sharing", fv_latency=0, fv_count=1 *)
input [d-1:0] i4;
(* fv_type="sharing", fv_latency=0, fv_count=1 *)
input [d-1:0] i5;
(* fv_type="sharing", fv_latency=0, fv_count=1 *)
input [d-1:0] i6;
(* fv_type="sharing", fv_latency=0, fv_count=1 *)
input [d-1:0] i7;
(* fv_type="random", fv_count=1, fv_rnd_count_0=9*and_pini_nrnd, fv_rnd_lat_0=0  *)
input [9*and_pini_nrnd-1:0] rnd_bus0;
(* fv_type="random", fv_count=1, fv_rnd_count_0=3*and_pini_nrnd, fv_rnd_lat_0=2  *)
input [3*and_pini_nrnd-1:0] rnd_bus2;
(* fv_type="random", fv_count=1, fv_rnd_count_0=4*and_pini_nrnd, fv_rnd_lat_0=3  *)
input [4*and_pini_nrnd-1:0] rnd_bus3;
(* fv_type="random", fv_count=1, fv_rnd_count_0=18*and_pini_nrnd, fv_rnd_lat_0=4  *)
input [18*and_pini_nrnd-1:0] rnd_bus4;

// Outputs ports
(* fv_type="sharing", fv_latency=6, fv_count=1 *)
output [d-1:0] o0;
(* fv_type="sharing", fv_latency=6, fv_count=1 *)
output [d-1:0] o1;
(* fv_type="sharing", fv_latency=6, fv_count=1 *)
output [d-1:0] o2;
(* fv_type="sharing", fv_latency=6, fv_count=1 *)
output [d-1:0] o3;
(* fv_type="sharing", fv_latency=6, fv_count=1 *)
output [d-1:0] o4;
(* fv_type="sharing", fv_latency=6, fv_count=1 *)
output [d-1:0] o5;
(* fv_type="sharing", fv_latency=6, fv_count=1 *)
output [d-1:0] o6;
(* fv_type="sharing", fv_latency=6, fv_count=1 *)
output [d-1:0] o7;


// Internal variables
wire [d-1:0] u0;
wire [d-1:0] u1;
wire [d-1:0] u2;
wire [d-1:0] u3;
wire [d-1:0] u4;
wire [d-1:0] u5;
wire [d-1:0] u6;
wire [d-1:0] u7;
wire [d-1:0] t1;
wire [d-1:0] t2;
wire [d-1:0] t3;
wire [d-1:0] t4;
wire [d-1:0] t5;
wire [d-1:0] t6;
wire [d-1:0] t7;
wire [d-1:0] t8;
wire [d-1:0] t9;
wire [d-1:0] t10;
wire [d-1:0] t11;
wire [d-1:0] t12;
wire [d-1:0] t13;
wire [d-1:0] t14;
wire [d-1:0] t15;
wire [d-1:0] t16;
wire [d-1:0] t17;
wire [d-1:0] t18;
wire [d-1:0] t19;
wire [d-1:0] t20;
wire [d-1:0] t21;
wire [d-1:0] t22;
wire [d-1:0] t23;
wire [d-1:0] t24;
wire [d-1:0] t25;
wire [d-1:0] t26;
wire [d-1:0] t27;
wire [d-1:0] ds;
wire [d-1:0] m1;
wire [d-1:0] m2;
wire [d-1:0] m3;
wire [d-1:0] m4;
wire [d-1:0] m5;
wire [d-1:0] m6;
wire [d-1:0] m7;
wire [d-1:0] m8;
wire [d-1:0] m9;
wire [d-1:0] m10;
wire [d-1:0] m11;
wire [d-1:0] m12;
wire [d-1:0] m13;
wire [d-1:0] m14;
wire [d-1:0] m15;
wire [d-1:0] m16;
wire [d-1:0] m17;
wire [d-1:0] m18;
wire [d-1:0] m19;
wire [d-1:0] m20;
wire [d-1:0] m21;
wire [d-1:0] m22;
wire [d-1:0] m23;
wire [d-1:0] m24;
wire [d-1:0] m25;
wire [d-1:0] m26;
wire [d-1:0] m27;
wire [d-1:0] m28;
wire [d-1:0] m29;
wire [d-1:0] m30;
wire [d-1:0] m31;
wire [d-1:0] m32;
wire [d-1:0] m33;
wire [d-1:0] m34;
wire [d-1:0] m35;
wire [d-1:0] m36;
wire [d-1:0] m37;
wire [d-1:0] m38;
wire [d-1:0] m39;
wire [d-1:0] m40;
wire [d-1:0] m41;
wire [d-1:0] m42;
wire [d-1:0] m43;
wire [d-1:0] m44;
wire [d-1:0] m45;
wire [d-1:0] m46;
wire [d-1:0] m47;
wire [d-1:0] m48;
wire [d-1:0] m49;
wire [d-1:0] m50;
wire [d-1:0] m51;
wire [d-1:0] m52;
wire [d-1:0] m53;
wire [d-1:0] m54;
wire [d-1:0] m55;
wire [d-1:0] m56;
wire [d-1:0] m57;
wire [d-1:0] m58;
wire [d-1:0] m59;
wire [d-1:0] m60;
wire [d-1:0] m61;
wire [d-1:0] m62;
wire [d-1:0] m63;
wire [d-1:0] l0;
wire [d-1:0] l1;
wire [d-1:0] l2;
wire [d-1:0] l3;
wire [d-1:0] l4;
wire [d-1:0] l5;
wire [d-1:0] l6;
wire [d-1:0] l7;
wire [d-1:0] l8;
wire [d-1:0] l9;
wire [d-1:0] l10;
wire [d-1:0] l11;
wire [d-1:0] l12;
wire [d-1:0] l13;
wire [d-1:0] l14;
wire [d-1:0] l15;
wire [d-1:0] l16;
wire [d-1:0] l17;
wire [d-1:0] l18;
wire [d-1:0] l19;
wire [d-1:0] l20;
wire [d-1:0] l21;
wire [d-1:0] l22;
wire [d-1:0] l23;
wire [d-1:0] l24;
wire [d-1:0] l25;
wire [d-1:0] l26;
wire [d-1:0] l27;
wire [d-1:0] l28;
wire [d-1:0] l29;
wire [d-1:0] s0;
wire [d-1:0] s1_tmpNXOR;
wire [d-1:0] s1;
wire [d-1:0] s2_tmpNXOR;
wire [d-1:0] s2;
wire [d-1:0] s3;
wire [d-1:0] s4;
wire [d-1:0] s5;
wire [d-1:0] s6_tmpNXOR;
wire [d-1:0] s6;
wire [d-1:0] s7_tmpNXOR;
wire [d-1:0] s7;
wire [d-1:0] dt6;
wire [d-1:0] ddt14;
wire [d-1:0] dt14;
wire [d-1:0] dt8;
wire [d-1:0] dt27;
wire [d-1:0] dt15;
wire [d-1:0] dds;
wire [d-1:0] ddt24;
wire [d-1:0] dt24;
wire [d-1:0] dt10;
wire [d-1:0] dt16;
wire [d-1:0] ddt26;
wire [d-1:0] dt26;
wire [d-1:0] dt9;
wire [d-1:0] dm20;
wire [d-1:0] ddm27;
wire [d-1:0] dm27;
wire [d-1:0] dt17;
wire [d-1:0] ddt25;
wire [d-1:0] dt25;
wire [d-1:0] dm23;
wire [d-1:0] dm33;
wire [d-1:0] ddm24;
wire [d-1:0] dm24;
wire [d-1:0] dm22;
wire [d-1:0] dm36;
wire [d-1:0] ddm23;
wire [d-1:0] dddm21;
wire [d-1:0] ddm21;
wire [d-1:0] dm21;
wire [d-1:0] dddm23;
wire [d-1:0] ddddt4;
wire [d-1:0] dddt4;
wire [d-1:0] ddt4;
wire [d-1:0] dt4;
wire [d-1:0] ddddt16;
wire [d-1:0] dddt16;
wire [d-1:0] ddt16;
wire [d-1:0] ddddt1;
wire [d-1:0] dddt1;
wire [d-1:0] ddt1;
wire [d-1:0] dt1;
wire [d-1:0] ddddt3;
wire [d-1:0] dddt3;
wire [d-1:0] ddt3;
wire [d-1:0] dt3;
wire [d-1:0] ddddt22;
wire [d-1:0] dddt22;
wire [d-1:0] ddt22;
wire [d-1:0] dt22;
wire [d-1:0] ddddt17;
wire [d-1:0] dddt17;
wire [d-1:0] ddt17;
wire [d-1:0] ddddt6;
wire [d-1:0] dddt6;
wire [d-1:0] ddt6;
wire [d-1:0] ddddds;
wire [d-1:0] dddds;
wire [d-1:0] ddds;
wire [d-1:0] ddddt9;
wire [d-1:0] dddt9;
wire [d-1:0] ddt9;
wire [d-1:0] ddddt27;
wire [d-1:0] dddt27;
wire [d-1:0] ddt27;
wire [d-1:0] ddddt10;
wire [d-1:0] dddt10;
wire [d-1:0] ddt10;
wire [d-1:0] ddddt20;
wire [d-1:0] dddt20;
wire [d-1:0] ddt20;
wire [d-1:0] dt20;
wire [d-1:0] ddddt23;
wire [d-1:0] dddt23;
wire [d-1:0] ddt23;
wire [d-1:0] dt23;
wire [d-1:0] ddddt19;
wire [d-1:0] dddt19;
wire [d-1:0] ddt19;
wire [d-1:0] dt19;
wire [d-1:0] ddddt8;
wire [d-1:0] dddt8;
wire [d-1:0] ddt8;
wire [d-1:0] ddddt13;
wire [d-1:0] dddt13;
wire [d-1:0] ddt13;
wire [d-1:0] dt13;
wire [d-1:0] ddddt2;
wire [d-1:0] dddt2;
wire [d-1:0] ddt2;
wire [d-1:0] dt2;
wire [d-1:0] ddddt15;
wire [d-1:0] dddt15;
wire [d-1:0] ddt15;

// Internal computation node
assign u3 = i4;

assign u5 = i2;

MSKxor #(.d(d))
xorhpc2_t4 (
    .ina(u3),
    .inb(u5),
    .out(t4)
    );

MSKreg #(.d(d))
regen_dt4 (
    .clk(clk),
    .in(t4),
    .out(dt4)
    );

MSKreg #(.d(d))
regen_ddt4 (
    .clk(clk),
    .in(dt4),
    .out(ddt4)
    );

MSKreg #(.d(d))
regen_dddt4 (
    .clk(clk),
    .in(ddt4),
    .out(dddt4)
    );

MSKreg #(.d(d))
regen_ddddt4 (
    .clk(clk),
    .in(dddt4),
    .out(ddddt4)
    );

assign u0 = i7;

MSKxor #(.d(d))
xorhpc2_t1 (
    .ina(u0),
    .inb(u3),
    .out(t1)
    );

assign u4 = i3;

assign u6 = i1;

MSKxor #(.d(d))
xorhpc2_t5 (
    .ina(u4),
    .inb(u6),
    .out(t5)
    );

MSKxor #(.d(d))
xorhpc2_t6 (
    .ina(t1),
    .inb(t5),
    .out(t6)
    );

assign u1 = i6;

MSKxor #(.d(d))
xorhpc2_t11 (
    .ina(u1),
    .inb(u5),
    .out(t11)
    );

MSKxor #(.d(d))
xorhpc2_t14 (
    .ina(t6),
    .inb(t11),
    .out(t14)
    );

MSKreg #(.d(d))
regen_dt14 (
    .clk(clk),
    .in(t14),
    .out(dt14)
    );

MSKreg #(.d(d))
regen_ddt14 (
    .clk(clk),
    .in(dt14),
    .out(ddt14)
    );

MSKxor #(.d(d))
xorhpc2_t3 (
    .ina(u0),
    .inb(u6),
    .out(t3)
    );

MSKxor #(.d(d))
xorhpc2_t13 (
    .ina(t3),
    .inb(t4),
    .out(t13)
    );

MSKreg #(.d(d))
regen_dt6 (
    .clk(clk),
    .in(t6),
    .out(dt6)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m1 (
    .ina(dt6),
    .inb(t13),
    .rnd(rnd_bus0[0 +: and_pini_nrnd]),
    .clk(clk),
    .out(m1)
    );

MSKxor #(.d(d))
xorhpc2_m3 (
    .ina(ddt14),
    .inb(m1),
    .out(m3)
    );

MSKxor #(.d(d))
xorhpc2_t2 (
    .ina(u0),
    .inb(u5),
    .out(t2)
    );

assign u2 = i5;

MSKxor #(.d(d))
xorhpc2_t7 (
    .ina(u1),
    .inb(u2),
    .out(t7)
    );

assign u7 = i0;

MSKxor #(.d(d))
xorhpc2_t21 (
    .ina(u6),
    .inb(u7),
    .out(t21)
    );

MSKxor #(.d(d))
xorhpc2_t22 (
    .ina(t7),
    .inb(t21),
    .out(t22)
    );

MSKxor #(.d(d))
xorhpc2_t23 (
    .ina(t2),
    .inb(t22),
    .out(t23)
    );

MSKxor #(.d(d))
xorhpc2_t8 (
    .ina(u7),
    .inb(t6),
    .out(t8)
    );

MSKreg #(.d(d))
regen_dt8 (
    .clk(clk),
    .in(t8),
    .out(dt8)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m2 (
    .ina(dt8),
    .inb(t23),
    .rnd(rnd_bus0[1*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m2)
    );

MSKxor #(.d(d))
xorhpc2_m16 (
    .ina(m3),
    .inb(m2),
    .out(m16)
    );

MSKxor #(.d(d))
xorhpc2_t12 (
    .ina(u2),
    .inb(u5),
    .out(t12)
    );

MSKxor #(.d(d))
xorhpc2_t27 (
    .ina(t1),
    .inb(t12),
    .out(t27)
    );

MSKreg #(.d(d))
regen_dt27 (
    .clk(clk),
    .in(t27),
    .out(dt27)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m12 (
    .ina(dt27),
    .inb(t4),
    .rnd(rnd_bus0[2*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m12)
    );

MSKxor #(.d(d))
xorhpc2_t15 (
    .ina(t5),
    .inb(t11),
    .out(t15)
    );

MSKreg #(.d(d))
regen_dt15 (
    .clk(clk),
    .in(t15),
    .out(dt15)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m11 (
    .ina(dt15),
    .inb(t1),
    .rnd(rnd_bus0[3*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m11)
    );

MSKxor #(.d(d))
xorhpc2_m13 (
    .ina(m12),
    .inb(m11),
    .out(m13)
    );

MSKxor #(.d(d))
xorhpc2_m20 (
    .ina(m16),
    .inb(m13),
    .out(m20)
    );

MSKxor #(.d(d))
xorhpc2_t10 (
    .ina(t6),
    .inb(t7),
    .out(t10)
    );

MSKxor #(.d(d))
xorhpc2_t24 (
    .ina(t2),
    .inb(t10),
    .out(t24)
    );

MSKreg #(.d(d))
regen_dt24 (
    .clk(clk),
    .in(t24),
    .out(dt24)
    );

MSKreg #(.d(d))
regen_ddt24 (
    .clk(clk),
    .in(dt24),
    .out(ddt24)
    );

MSKxor #(.d(d))
xorhpc2_t18 (
    .ina(u3),
    .inb(u7),
    .out(t18)
    );

MSKxor #(.d(d))
xorhpc2_t19 (
    .ina(t7),
    .inb(t18),
    .out(t19)
    );

assign ds = u7;

MSKreg #(.d(d))
regen_dds (
    .clk(clk),
    .in(ds),
    .out(dds)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m4 (
    .ina(dds),
    .inb(t19),
    .rnd(rnd_bus0[4*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m4)
    );

MSKxor #(.d(d))
xorhpc2_m5 (
    .ina(m4),
    .inb(m1),
    .out(m5)
    );

MSKxor #(.d(d))
xorhpc2_m17 (
    .ina(ddt24),
    .inb(m5),
    .out(m17)
    );

MSKreg #(.d(d))
regen_dt10 (
    .clk(clk),
    .in(t10),
    .out(dt10)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m14 (
    .ina(dt10),
    .inb(t2),
    .rnd(rnd_bus0[5*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m14)
    );

MSKxor #(.d(d))
xorhpc2_m15 (
    .ina(m14),
    .inb(m11),
    .out(m15)
    );

MSKxor #(.d(d))
xorhpc2_m21 (
    .ina(m17),
    .inb(m15),
    .out(m21)
    );

MSKxor #(.d(d))
xorhpc2_m27 (
    .ina(m20),
    .inb(m21),
    .out(m27)
    );

MSKreg #(.d(d))
regen_dm27 (
    .clk(clk),
    .in(m27),
    .out(dm27)
    );

MSKreg #(.d(d))
regen_ddm27 (
    .clk(clk),
    .in(dm27),
    .out(ddm27)
    );

MSKxor #(.d(d))
xorhpc2_t16 (
    .ina(t5),
    .inb(t12),
    .out(t16)
    );

MSKxor #(.d(d))
xorhpc2_t26 (
    .ina(t3),
    .inb(t16),
    .out(t26)
    );

MSKreg #(.d(d))
regen_dt26 (
    .clk(clk),
    .in(t26),
    .out(dt26)
    );

MSKreg #(.d(d))
regen_ddt26 (
    .clk(clk),
    .in(dt26),
    .out(ddt26)
    );

MSKreg #(.d(d))
regen_dt16 (
    .clk(clk),
    .in(t16),
    .out(dt16)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m6 (
    .ina(dt16),
    .inb(t3),
    .rnd(rnd_bus0[6*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m6)
    );

MSKxor #(.d(d))
xorhpc2_m8 (
    .ina(ddt26),
    .inb(m6),
    .out(m8)
    );

MSKxor #(.d(d))
xorhpc2_t9 (
    .ina(u7),
    .inb(t7),
    .out(t9)
    );

MSKreg #(.d(d))
regen_dt9 (
    .clk(clk),
    .in(t9),
    .out(dt9)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m7 (
    .ina(dt9),
    .inb(t22),
    .rnd(rnd_bus0[7*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m7)
    );

MSKxor #(.d(d))
xorhpc2_m18 (
    .ina(m8),
    .inb(m7),
    .out(m18)
    );

MSKxor #(.d(d))
xorhpc2_m22 (
    .ina(m18),
    .inb(m13),
    .out(m22)
    );

MSKreg #(.d(d))
regen_dm20 (
    .clk(clk),
    .in(m20),
    .out(dm20)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m25 (
    .ina(dm20),
    .inb(m22),
    .rnd(rnd_bus2[0 +: and_pini_nrnd]),
    .clk(clk),
    .out(m25)
    );

MSKxor #(.d(d))
xorhpc2_m33 (
    .ina(ddm27),
    .inb(m25),
    .out(m33)
    );

MSKreg #(.d(d))
regen_dm33 (
    .clk(clk),
    .in(m33),
    .out(dm33)
    );

MSKxor #(.d(d))
xorhpc2_t20 (
    .ina(t1),
    .inb(t19),
    .out(t20)
    );

MSKxor #(.d(d))
xorhpc2_t17 (
    .ina(t9),
    .inb(t16),
    .out(t17)
    );

MSKxor #(.d(d))
xorhpc2_t25 (
    .ina(t20),
    .inb(t17),
    .out(t25)
    );

MSKreg #(.d(d))
regen_dt25 (
    .clk(clk),
    .in(t25),
    .out(dt25)
    );

MSKreg #(.d(d))
regen_ddt25 (
    .clk(clk),
    .in(dt25),
    .out(ddt25)
    );

MSKreg #(.d(d))
regen_dt17 (
    .clk(clk),
    .in(t17),
    .out(dt17)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m9 (
    .ina(dt17),
    .inb(t20),
    .rnd(rnd_bus0[8*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m9)
    );

MSKxor #(.d(d))
xorhpc2_m10 (
    .ina(m9),
    .inb(m6),
    .out(m10)
    );

MSKxor #(.d(d))
xorhpc2_m19 (
    .ina(m10),
    .inb(m15),
    .out(m19)
    );

MSKxor #(.d(d))
xorhpc2_m23 (
    .ina(ddt25),
    .inb(m19),
    .out(m23)
    );

MSKreg #(.d(d))
regen_dm23 (
    .clk(clk),
    .in(m23),
    .out(dm23)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m31 (
    .ina(dm23),
    .inb(m20),
    .rnd(rnd_bus2[1*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m31)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m32 (
    .ina(m31),
    .inb(dm27),
    .rnd(rnd_bus3[0 +: and_pini_nrnd]),
    .clk(clk),
    .out(m32)
    );

MSKxor #(.d(d))
xorhpc2_m38 (
    .ina(dm33),
    .inb(m32),
    .out(m38)
    );

MSKxor #(.d(d))
xorhpc2_m24 (
    .ina(m22),
    .inb(m23),
    .out(m24)
    );

MSKreg #(.d(d))
regen_dm24 (
    .clk(clk),
    .in(m24),
    .out(dm24)
    );

MSKreg #(.d(d))
regen_ddm24 (
    .clk(clk),
    .in(dm24),
    .out(ddm24)
    );

MSKxor #(.d(d))
xorhpc2_m36 (
    .ina(ddm24),
    .inb(m25),
    .out(m36)
    );

MSKreg #(.d(d))
regen_dm36 (
    .clk(clk),
    .in(m36),
    .out(dm36)
    );

MSKreg #(.d(d))
regen_dm22 (
    .clk(clk),
    .in(m22),
    .out(dm22)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m34 (
    .ina(dm22),
    .inb(m21),
    .rnd(rnd_bus2[2*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m34)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m35 (
    .ina(m34),
    .inb(dm24),
    .rnd(rnd_bus3[1*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m35)
    );

MSKxor #(.d(d))
xorhpc2_m40 (
    .ina(dm36),
    .inb(m35),
    .out(m40)
    );

MSKxor #(.d(d))
xorhpc2_m41 (
    .ina(m38),
    .inb(m40),
    .out(m41)
    );

MSKreg #(.d(d))
regen_dm21 (
    .clk(clk),
    .in(m21),
    .out(dm21)
    );

MSKreg #(.d(d))
regen_ddm21 (
    .clk(clk),
    .in(dm21),
    .out(ddm21)
    );

MSKreg #(.d(d))
regen_dddm21 (
    .clk(clk),
    .in(ddm21),
    .out(dddm21)
    );

MSKreg #(.d(d))
regen_ddm23 (
    .clk(clk),
    .in(dm23),
    .out(ddm23)
    );

MSKxor #(.d(d))
xorhpc2_m28 (
    .ina(ddm23),
    .inb(m25),
    .out(m28)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m29 (
    .ina(m28),
    .inb(dm27),
    .rnd(rnd_bus3[2*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m29)
    );

MSKxor #(.d(d))
xorhpc2_m37 (
    .ina(dddm21),
    .inb(m29),
    .out(m37)
    );

MSKreg #(.d(d))
regen_dddm23 (
    .clk(clk),
    .in(ddm23),
    .out(dddm23)
    );

MSKxor #(.d(d))
xorhpc2_m26 (
    .ina(ddm21),
    .inb(m25),
    .out(m26)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m30 (
    .ina(m26),
    .inb(dm24),
    .rnd(rnd_bus3[3*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m30)
    );

MSKxor #(.d(d))
xorhpc2_m39 (
    .ina(dddm23),
    .inb(m30),
    .out(m39)
    );

MSKxor #(.d(d))
xorhpc2_m42 (
    .ina(m37),
    .inb(m39),
    .out(m42)
    );

MSKxor #(.d(d))
xorhpc2_m45 (
    .ina(m41),
    .inb(m42),
    .out(m45)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m62 (
    .ina(m45),
    .inb(ddddt4),
    .rnd(rnd_bus4[0 +: and_pini_nrnd]),
    .clk(clk),
    .out(m62)
    );

MSKreg #(.d(d))
regen_ddt16 (
    .clk(clk),
    .in(dt16),
    .out(ddt16)
    );

MSKreg #(.d(d))
regen_dddt16 (
    .clk(clk),
    .in(ddt16),
    .out(dddt16)
    );

MSKreg #(.d(d))
regen_ddddt16 (
    .clk(clk),
    .in(dddt16),
    .out(ddddt16)
    );

MSKxor #(.d(d))
xorhpc2_m43 (
    .ina(m38),
    .inb(m37),
    .out(m43)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m49 (
    .ina(m43),
    .inb(ddddt16),
    .rnd(rnd_bus4[1*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m49)
    );

MSKreg #(.d(d))
regen_dt1 (
    .clk(clk),
    .in(t1),
    .out(dt1)
    );

MSKreg #(.d(d))
regen_ddt1 (
    .clk(clk),
    .in(dt1),
    .out(ddt1)
    );

MSKreg #(.d(d))
regen_dddt1 (
    .clk(clk),
    .in(ddt1),
    .out(dddt1)
    );

MSKreg #(.d(d))
regen_ddddt1 (
    .clk(clk),
    .in(dddt1),
    .out(ddddt1)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m61 (
    .ina(m42),
    .inb(ddddt1),
    .rnd(rnd_bus4[2*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m61)
    );

MSKxor #(.d(d))
xorhpc2_l5 (
    .ina(m49),
    .inb(m61),
    .out(l5)
    );

MSKxor #(.d(d))
xorhpc2_l6 (
    .ina(m62),
    .inb(l5),
    .out(l6)
    );

MSKreg #(.d(d))
regen_ddt9 (
    .clk(clk),
    .in(dt9),
    .out(ddt9)
    );

MSKreg #(.d(d))
regen_dddt9 (
    .clk(clk),
    .in(ddt9),
    .out(dddt9)
    );

MSKreg #(.d(d))
regen_ddddt9 (
    .clk(clk),
    .in(dddt9),
    .out(ddddt9)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m50 (
    .ina(m38),
    .inb(ddddt9),
    .rnd(rnd_bus4[3*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m50)
    );

MSKreg #(.d(d))
regen_dt23 (
    .clk(clk),
    .in(t23),
    .out(dt23)
    );

MSKreg #(.d(d))
regen_ddt23 (
    .clk(clk),
    .in(dt23),
    .out(ddt23)
    );

MSKreg #(.d(d))
regen_dddt23 (
    .clk(clk),
    .in(ddt23),
    .out(dddt23)
    );

MSKreg #(.d(d))
regen_ddddt23 (
    .clk(clk),
    .in(dddt23),
    .out(ddddt23)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m56 (
    .ina(m40),
    .inb(ddddt23),
    .rnd(rnd_bus4[4*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m56)
    );

MSKxor #(.d(d))
xorhpc2_l1 (
    .ina(m50),
    .inb(m56),
    .out(l1)
    );

MSKreg #(.d(d))
regen_dt13 (
    .clk(clk),
    .in(t13),
    .out(dt13)
    );

MSKreg #(.d(d))
regen_ddt13 (
    .clk(clk),
    .in(dt13),
    .out(ddt13)
    );

MSKreg #(.d(d))
regen_dddt13 (
    .clk(clk),
    .in(ddt13),
    .out(dddt13)
    );

MSKreg #(.d(d))
regen_ddddt13 (
    .clk(clk),
    .in(dddt13),
    .out(ddddt13)
    );

MSKxor #(.d(d))
xorhpc2_m44 (
    .ina(m40),
    .inb(m39),
    .out(m44)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m55 (
    .ina(m44),
    .inb(ddddt13),
    .rnd(rnd_bus4[5*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m55)
    );

MSKxor #(.d(d))
xorhpc2_l15 (
    .ina(l1),
    .inb(m55),
    .out(l15)
    );

MSKreg #(.d(d))
regen_ddt15 (
    .clk(clk),
    .in(dt15),
    .out(ddt15)
    );

MSKreg #(.d(d))
regen_dddt15 (
    .clk(clk),
    .in(ddt15),
    .out(dddt15)
    );

MSKreg #(.d(d))
regen_ddddt15 (
    .clk(clk),
    .in(dddt15),
    .out(ddddt15)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m52 (
    .ina(m42),
    .inb(ddddt15),
    .rnd(rnd_bus4[6*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m52)
    );

MSKreg #(.d(d))
regen_ddt27 (
    .clk(clk),
    .in(dt27),
    .out(ddt27)
    );

MSKreg #(.d(d))
regen_dddt27 (
    .clk(clk),
    .in(ddt27),
    .out(dddt27)
    );

MSKreg #(.d(d))
regen_ddddt27 (
    .clk(clk),
    .in(dddt27),
    .out(ddddt27)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m53 (
    .ina(m45),
    .inb(ddddt27),
    .rnd(rnd_bus4[7*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m53)
    );

MSKxor #(.d(d))
xorhpc2_l9 (
    .ina(m52),
    .inb(m53),
    .out(l9)
    );

MSKxor #(.d(d))
xorhpc2_l24 (
    .ina(l15),
    .inb(l9),
    .out(l24)
    );

MSKxor #(.d(d))
xorhpc2_s0 (
    .ina(l6),
    .inb(l24),
    .out(s0)
    );

MSKxor #(.d(d))
xorhpc2_l0 (
    .ina(m61),
    .inb(m62),
    .out(l0)
    );

MSKxor #(.d(d))
xorhpc2_l16 (
    .ina(m56),
    .inb(l0),
    .out(l16)
    );

MSKreg #(.d(d))
regen_ddt6 (
    .clk(clk),
    .in(dt6),
    .out(ddt6)
    );

MSKreg #(.d(d))
regen_dddt6 (
    .clk(clk),
    .in(ddt6),
    .out(dddt6)
    );

MSKreg #(.d(d))
regen_ddddt6 (
    .clk(clk),
    .in(dddt6),
    .out(ddddt6)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m46 (
    .ina(m44),
    .inb(ddddt6),
    .rnd(rnd_bus4[8*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m46)
    );

MSKreg #(.d(d))
regen_ddt8 (
    .clk(clk),
    .in(dt8),
    .out(ddt8)
    );

MSKreg #(.d(d))
regen_dddt8 (
    .clk(clk),
    .in(ddt8),
    .out(dddt8)
    );

MSKreg #(.d(d))
regen_ddddt8 (
    .clk(clk),
    .in(dddt8),
    .out(ddddt8)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m47 (
    .ina(m40),
    .inb(ddddt8),
    .rnd(rnd_bus4[9*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m47)
    );

MSKxor #(.d(d))
xorhpc2_l3 (
    .ina(m47),
    .inb(m55),
    .out(l3)
    );

MSKxor #(.d(d))
xorhpc2_l7 (
    .ina(m46),
    .inb(l3),
    .out(l7)
    );

MSKxor #(.d(d))
xorhpc2_l26 (
    .ina(l7),
    .inb(l9),
    .out(l26)
    );

MSKxor #(.d(d))
xorhpc2_s1_tmpNXOR (
    .ina(l16),
    .inb(l26),
    .out(s1_tmpNXOR)
    );

MSKinv #(.d(d))
inv_s1 (
    .in(s1_tmpNXOR),
    .out(s1)
    );

MSKreg #(.d(d))
regen_dt2 (
    .clk(clk),
    .in(t2),
    .out(dt2)
    );

MSKreg #(.d(d))
regen_ddt2 (
    .clk(clk),
    .in(dt2),
    .out(ddt2)
    );

MSKreg #(.d(d))
regen_dddt2 (
    .clk(clk),
    .in(ddt2),
    .out(dddt2)
    );

MSKreg #(.d(d))
regen_ddddt2 (
    .clk(clk),
    .in(dddt2),
    .out(ddddt2)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m63 (
    .ina(m41),
    .inb(ddddt2),
    .rnd(rnd_bus4[10*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m63)
    );

MSKreg #(.d(d))
regen_ddt10 (
    .clk(clk),
    .in(dt10),
    .out(ddt10)
    );

MSKreg #(.d(d))
regen_dddt10 (
    .clk(clk),
    .in(ddt10),
    .out(dddt10)
    );

MSKreg #(.d(d))
regen_ddddt10 (
    .clk(clk),
    .in(dddt10),
    .out(ddddt10)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m54 (
    .ina(m41),
    .inb(ddddt10),
    .rnd(rnd_bus4[11*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m54)
    );

MSKreg #(.d(d))
regen_dt3 (
    .clk(clk),
    .in(t3),
    .out(dt3)
    );

MSKreg #(.d(d))
regen_ddt3 (
    .clk(clk),
    .in(dt3),
    .out(ddt3)
    );

MSKreg #(.d(d))
regen_dddt3 (
    .clk(clk),
    .in(ddt3),
    .out(dddt3)
    );

MSKreg #(.d(d))
regen_ddddt3 (
    .clk(clk),
    .in(dddt3),
    .out(ddddt3)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m58 (
    .ina(m43),
    .inb(ddddt3),
    .rnd(rnd_bus4[12*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m58)
    );

MSKxor #(.d(d))
xorhpc2_l4 (
    .ina(m54),
    .inb(m58),
    .out(l4)
    );

MSKxor #(.d(d))
xorhpc2_l19 (
    .ina(m63),
    .inb(l4),
    .out(l19)
    );

MSKreg #(.d(d))
regen_dt20 (
    .clk(clk),
    .in(t20),
    .out(dt20)
    );

MSKreg #(.d(d))
regen_ddt20 (
    .clk(clk),
    .in(dt20),
    .out(ddt20)
    );

MSKreg #(.d(d))
regen_dddt20 (
    .clk(clk),
    .in(ddt20),
    .out(dddt20)
    );

MSKreg #(.d(d))
regen_ddddt20 (
    .clk(clk),
    .in(dddt20),
    .out(ddddt20)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m60 (
    .ina(m37),
    .inb(ddddt20),
    .rnd(rnd_bus4[13*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m60)
    );

MSKreg #(.d(d))
regen_ddds (
    .clk(clk),
    .in(dds),
    .out(ddds)
    );

MSKreg #(.d(d))
regen_dddds (
    .clk(clk),
    .in(ddds),
    .out(dddds)
    );

MSKreg #(.d(d))
regen_ddddds (
    .clk(clk),
    .in(dddds),
    .out(ddddds)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m48 (
    .ina(m39),
    .inb(ddddds),
    .rnd(rnd_bus4[14*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m48)
    );

MSKxor #(.d(d))
xorhpc2_l2 (
    .ina(m46),
    .inb(m48),
    .out(l2)
    );

MSKxor #(.d(d))
xorhpc2_l11 (
    .ina(m60),
    .inb(l2),
    .out(l11)
    );

MSKxor #(.d(d))
xorhpc2_l14 (
    .ina(m52),
    .inb(m61),
    .out(l14)
    );

MSKxor #(.d(d))
xorhpc2_l28 (
    .ina(l11),
    .inb(l14),
    .out(l28)
    );

MSKxor #(.d(d))
xorhpc2_s2_tmpNXOR (
    .ina(l19),
    .inb(l28),
    .out(s2_tmpNXOR)
    );

MSKinv #(.d(d))
inv_s2 (
    .in(s2_tmpNXOR),
    .out(s2)
    );

MSKxor #(.d(d))
xorhpc2_l21 (
    .ina(l1),
    .inb(l7),
    .out(l21)
    );

MSKxor #(.d(d))
xorhpc2_s3 (
    .ina(l6),
    .inb(l21),
    .out(s3)
    );

MSKxor #(.d(d))
xorhpc2_l20 (
    .ina(l1),
    .inb(l0),
    .out(l20)
    );

MSKreg #(.d(d))
regen_ddt17 (
    .clk(clk),
    .in(dt17),
    .out(ddt17)
    );

MSKreg #(.d(d))
regen_dddt17 (
    .clk(clk),
    .in(ddt17),
    .out(dddt17)
    );

MSKreg #(.d(d))
regen_ddddt17 (
    .clk(clk),
    .in(dddt17),
    .out(ddddt17)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m51 (
    .ina(m37),
    .inb(ddddt17),
    .rnd(rnd_bus4[15*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m51)
    );

MSKxor #(.d(d))
xorhpc2_l12 (
    .ina(m48),
    .inb(m51),
    .out(l12)
    );

MSKxor #(.d(d))
xorhpc2_l22 (
    .ina(l3),
    .inb(l12),
    .out(l22)
    );

MSKxor #(.d(d))
xorhpc2_s4 (
    .ina(l20),
    .inb(l22),
    .out(s4)
    );

MSKxor #(.d(d))
xorhpc2_l10 (
    .ina(m53),
    .inb(l4),
    .out(l10)
    );

MSKxor #(.d(d))
xorhpc2_l25 (
    .ina(l6),
    .inb(l10),
    .out(l25)
    );

MSKreg #(.d(d))
regen_dt19 (
    .clk(clk),
    .in(t19),
    .out(dt19)
    );

MSKreg #(.d(d))
regen_ddt19 (
    .clk(clk),
    .in(dt19),
    .out(ddt19)
    );

MSKreg #(.d(d))
regen_dddt19 (
    .clk(clk),
    .in(ddt19),
    .out(dddt19)
    );

MSKreg #(.d(d))
regen_ddddt19 (
    .clk(clk),
    .in(dddt19),
    .out(ddddt19)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m57 (
    .ina(m39),
    .inb(ddddt19),
    .rnd(rnd_bus4[16*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m57)
    );

MSKxor #(.d(d))
xorhpc2_l17 (
    .ina(l1),
    .inb(m57),
    .out(l17)
    );

MSKxor #(.d(d))
xorhpc2_l29 (
    .ina(l11),
    .inb(l17),
    .out(l29)
    );

MSKxor #(.d(d))
xorhpc2_s5 (
    .ina(l25),
    .inb(l29),
    .out(s5)
    );

MSKxor #(.d(d))
xorhpc2_l13 (
    .ina(m50),
    .inb(l0),
    .out(l13)
    );

MSKreg #(.d(d))
regen_dt22 (
    .clk(clk),
    .in(t22),
    .out(dt22)
    );

MSKreg #(.d(d))
regen_ddt22 (
    .clk(clk),
    .in(dt22),
    .out(ddt22)
    );

MSKreg #(.d(d))
regen_dddt22 (
    .clk(clk),
    .in(ddt22),
    .out(dddt22)
    );

MSKreg #(.d(d))
regen_ddddt22 (
    .clk(clk),
    .in(dddt22),
    .out(ddddt22)
    );

MSKand_HPC2 #(.d(d))
andhpc2_m59 (
    .ina(m38),
    .inb(ddddt22),
    .rnd(rnd_bus4[17*and_pini_nrnd +: and_pini_nrnd]),
    .clk(clk),
    .out(m59)
    );

MSKxor #(.d(d))
xorhpc2_l8 (
    .ina(m59),
    .inb(m51),
    .out(l8)
    );

MSKxor #(.d(d))
xorhpc2_l27 (
    .ina(l8),
    .inb(l10),
    .out(l27)
    );

MSKxor #(.d(d))
xorhpc2_s6_tmpNXOR (
    .ina(l13),
    .inb(l27),
    .out(s6_tmpNXOR)
    );

MSKinv #(.d(d))
inv_s6 (
    .in(s6_tmpNXOR),
    .out(s6)
    );

MSKxor #(.d(d))
xorhpc2_l18 (
    .ina(m58),
    .inb(l8),
    .out(l18)
    );

MSKxor #(.d(d))
xorhpc2_l23 (
    .ina(l18),
    .inb(l2),
    .out(l23)
    );

MSKxor #(.d(d))
xorhpc2_s7_tmpNXOR (
    .ina(l6),
    .inb(l23),
    .out(s7_tmpNXOR)
    );

MSKinv #(.d(d))
inv_s7 (
    .in(s7_tmpNXOR),
    .out(s7)
    );

// Output nodes
assign o7 = s0;

assign o6 = s1;

assign o5 = s2;

assign o4 = s3;

assign o3 = s4;

assign o2 = s5;

assign o1 = s6;

assign o0 = s7;

endmodule
