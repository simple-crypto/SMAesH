`timescale 1ns/1ps

// latency = 4

// Fully pipeline PINI circuit in 4 clock cycles.
// This file has been automatically generated.
`ifdef FULLVERIF
(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
`endif
module canright # ( parameter d=2 ) (
    clk,
    i0,
    i1,
    i2,
    i3,
    i4,
    i5,
    i6,
    i7,
    o0,
    o1,
    o2,
    o3,
    o4,
    o5,
    o6,
    o7,
    rnd_0,
    rnd_1,
    rnd_2,
    rnd_3,
);
`include "MSKand_hpc1.vh"
`include "MSKand_hpc2.vh"
`include "MSKand_hpc3.vh"
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
(* fv_type="sharing", fv_latency=4, fv_count=1 *)
output [d-1:0] o0;
(* fv_type="sharing", fv_latency=4, fv_count=1 *)
output [d-1:0] o1;
(* fv_type="sharing", fv_latency=4, fv_count=1 *)
output [d-1:0] o2;
(* fv_type="sharing", fv_latency=4, fv_count=1 *)
output [d-1:0] o3;
(* fv_type="sharing", fv_latency=4, fv_count=1 *)
output [d-1:0] o4;
(* fv_type="sharing", fv_latency=4, fv_count=1 *)
output [d-1:0] o5;
(* fv_type="sharing", fv_latency=4, fv_count=1 *)
output [d-1:0] o6;
(* fv_type="sharing", fv_latency=4, fv_count=1 *)
output [d-1:0] o7;
(* fv_type="random", fv_count=1, fv_rnd_count_0=1*(4*d*(d-1)), fv_rnd_lat_0=0  *)
input [1*(4*d*(d-1))-1:0] rnd_0;
(* fv_type="random", fv_count=1, fv_rnd_count_0=1*(2*d*(d-1)), fv_rnd_lat_0=1  *)
input [1*(2*d*(d-1))-1:0] rnd_1;
(* fv_type="random", fv_count=1, fv_rnd_count_0=2*(2*d*(d-1)), fv_rnd_lat_0=2  *)
input [2*(2*d*(d-1))-1:0] rnd_2;
(* fv_type="random", fv_count=1, fv_rnd_count_0=2*(4*d*(d-1)), fv_rnd_lat_0=3  *)
input [2*(4*d*(d-1))-1:0] rnd_3;
wire [d-1:0] gen0_4;
wire [d-1:0] gen1_4;
wire [d-1:0] gen10_0;
wire [d-1:0] gen10_1;
wire [d-1:0] gen10_2;
wire [d-1:0] gen10_3;
wire [d-1:0] gen11_0;
wire [d-1:0] gen12_0;
wire [d-1:0] gen12_1;
wire [d-1:0] gen12_2;
wire [d-1:0] gen12_3;
wire [d-1:0] gen13_0;
wire [d-1:0] gen14_0;
wire [d-1:0] gen14_1;
wire [d-1:0] gen14_2;
wire [d-1:0] gen14_3;
wire [d-1:0] gen15_0;
wire [d-1:0] gen16_0;
wire [d-1:0] gen16_1;
wire [d-1:0] gen16_2;
wire [d-1:0] gen16_3;
wire [d-1:0] gen17_0;
wire [d-1:0] gen18_0;
wire [d-1:0] gen19_0;
wire [d-1:0] gen19_1;
wire [d-1:0] gen19_2;
wire [d-1:0] gen19_3;
wire [d-1:0] gen2_4;
wire [d-1:0] gen20_0;
wire [d-1:0] gen20_1;
wire [d-1:0] gen20_2;
wire [d-1:0] gen20_3;
wire [d-1:0] gen21_0;
wire [d-1:0] gen21_1;
wire [d-1:0] gen21_2;
wire [d-1:0] gen21_3;
wire [d-1:0] gen22_1;
wire [d-1:0] gen22_2;
wire [d-1:0] gen23_1;
wire [d-1:0] gen23_2;
wire [d-1:0] gen24_2;
wire [d-1:0] gen25_1;
wire [d-1:0] gen25_2;
wire [d-1:0] gen26_1;
wire [d-1:0] gen26_2;
wire [d-1:0] gen27_2;
wire [d-1:0] gen28_2;
wire [d-1:0] gen29_2;
wire [d-1:0] gen3_4;
wire [d-1:0] gen30_2;
wire [d-1:0] gen30_3;
wire [d-1:0] gen31_2;
wire [d-1:0] gen32_2;
wire [d-1:0] gen32_3;
wire [d-1:0] gen33_1;
wire [d-1:0] gen34_1;
wire [d-1:0] gen35_1;
wire [d-1:0] gen36_1;
wire [d-1:0] gen37_1;
wire [d-1:0] gen38_1;
wire [d-1:0] gen39_1;
wire [d-1:0] gen4_0;
wire [d-1:0] gen40_1;
wire [d-1:0] gen41_1;
wire [d-1:0] gen42_1;
wire [d-1:0] gen43_1;
wire [d-1:0] gen44_4;
wire [d-1:0] gen45_4;
wire [d-1:0] gen46_4;
wire [d-1:0] gen47_4;
wire [d-1:0] gen48_4;
wire [d-1:0] gen49_4;
wire [d-1:0] gen5_0;
wire [d-1:0] gen50_4;
wire [d-1:0] gen51_4;
wire [d-1:0] gen52_4;
wire [d-1:0] gen53_4;
wire [d-1:0] gen54_4;
wire [d-1:0] gen55_4;
wire [d-1:0] gen56_4;
wire [d-1:0] gen57_4;
wire [d-1:0] gen58_4;
wire [d-1:0] gen59_3;
wire [d-1:0] gen59_4;
wire [d-1:0] gen6_0;
wire [d-1:0] gen60_3;
wire [d-1:0] gen60_4;
wire [d-1:0] gen61_3;
wire [d-1:0] gen61_4;
wire [d-1:0] gen62_3;
wire [d-1:0] gen62_4;
wire [d-1:0] gen7_0;
wire [d-1:0] gen8_0;
wire [d-1:0] gen9_0;
wire [d-1:0] i0_0;
wire [d-1:0] i0_1;
wire [d-1:0] i0_2;
wire [d-1:0] i0_3;
wire [d-1:0] i1_0;
wire [d-1:0] i2_0;
wire [d-1:0] i3_0;
wire [d-1:0] i4_0;
wire [d-1:0] i5_0;
wire [d-1:0] i6_0;
wire [d-1:0] i7_0;
wire [d-1:0] o0_4;
wire [d-1:0] o1_4;
wire [d-1:0] o2_4;
wire [d-1:0] o3_4;
wire [d-1:0] o4_4;
wire [d-1:0] o5_4;
wire [d-1:0] o6_4;
wire [d-1:0] o7_4;
assign i0_0 = i0;
assign i1_0 = i1;
assign i2_0 = i2;
assign i3_0 = i3;
assign i4_0 = i4;
assign i5_0 = i5;
assign i6_0 = i6;
assign i7_0 = i7;
assign o0 = o0_4;
assign o1 = o1_4;
assign o2 = o2_4;
assign o3 = o3_4;
assign o4 = o4_4;
assign o5 = o5_4;
assign o6 = o6_4;
assign o7 = o7_4;


MSKxor #(.d(d)) comp_gen9_0 (
    .out(gen9_0),
    .ina(i0_0),
    .inb(i4_0)
);
MSKxor #(.d(d)) comp_gen6_0 (
    .out(gen6_0),
    .ina(i0_0),
    .inb(i1_0)
);
MSKxor #(.d(d)) comp_gen11_0 (
    .out(gen11_0),
    .ina(i0_0),
    .inb(i5_0)
);
MSKxor #(.d(d)) comp_gen15_0 (
    .out(gen15_0),
    .ina(gen9_0),
    .inb(i5_0)
);
MSKxor #(.d(d)) comp_gen7_0 (
    .out(gen7_0),
    .ina(gen6_0),
    .inb(i3_0)
);
MSKxor #(.d(d)) comp_gen4_0 (
    .out(gen4_0),
    .ina(gen6_0),
    .inb(i2_0)
);
MSKxor #(.d(d)) comp_gen13_0 (
    .out(gen13_0),
    .ina(gen6_0),
    .inb(i5_0)
);
MSKxor #(.d(d)) comp_gen12_0 (
    .out(gen12_0),
    .ina(gen11_0),
    .inb(i6_0)
);
MSKxor #(.d(d)) comp_gen16_0 (
    .out(gen16_0),
    .ina(gen15_0),
    .inb(i6_0)
);
MSKxor #(.d(d)) comp_gen8_0 (
    .out(gen8_0),
    .ina(gen7_0),
    .inb(i4_0)
);
MSKxor #(.d(d)) comp_gen5_0 (
    .out(gen5_0),
    .ina(gen4_0),
    .inb(i3_0)
);
MSKxor #(.d(d)) comp_gen17_0 (
    .out(gen17_0),
    .ina(gen4_0),
    .inb(i5_0)
);
MSKxor #(.d(d)) comp_gen14_0 (
    .out(gen14_0),
    .ina(gen13_0),
    .inb(i6_0)
);
MSKxor #(.d(d)) comp_gen20_0 (
    .out(gen20_0),
    .ina(gen12_0),
    .inb(i7_0)
);
MSKxor #(.d(d)) comp_gen33_1 (
    .out(gen33_1),
    .ina(gen16_1),
    .inb(i0_1)
);
MSKxor #(.d(d)) comp_gen19_0 (
    .out(gen19_0),
    .ina(gen8_0),
    .inb(i7_0)
);
MSKxor #(.d(d)) comp_gen10_0 (
    .out(gen10_0),
    .ina(gen5_0),
    .inb(i6_0)
);
MSKxor #(.d(d)) comp_gen18_0 (
    .out(gen18_0),
    .ina(gen17_0),
    .inb(i6_0)
);
MSKxor #(.d(d)) comp_gen37_1 (
    .out(gen37_1),
    .ina(gen14_1),
    .inb(gen12_1)
);
MSKg16mul_hpc3 #(.d(d)) comp_gen39_1 (
    .out0(gen39_1),
    .out1(gen41_1),
    .out2(gen42_1),
    .out3(gen43_1),
    .rnd(rnd_0[0 +: 4*d*(d-1)]),
    .ina0(gen20_0),
    .ina0_prev(gen20_1),
    .ina1(gen14_0),
    .ina1_prev(gen14_1),
    .ina2(gen16_0),
    .ina2_prev(gen16_1),
    .ina3(gen21_0),
    .ina3_prev(gen21_1),
    .inb0(gen10_0),
    .inb1(gen12_0),
    .inb2(i0_0),
    .inb3(gen19_0),
    .clk(clk)
);
MSKxor #(.d(d)) comp_gen34_1 (
    .out(gen34_1),
    .ina(gen20_1),
    .inb(gen10_1)
);
MSKxor #(.d(d)) comp_gen21_0 (
    .out(gen21_0),
    .ina(gen18_0),
    .inb(i7_0)
);
MSKxor #(.d(d)) comp_gen35_1 (
    .out(gen35_1),
    .ina(gen33_1),
    .inb(gen34_1)
);
MSKxor #(.d(d)) comp_gen23_1 (
    .out(gen23_1),
    .ina(gen34_1),
    .inb(gen39_1)
);
MSKxor #(.d(d)) comp_gen40_1 (
    .out(gen40_1),
    .ina(gen34_1),
    .inb(gen37_1)
);
MSKxor #(.d(d)) comp_gen36_1 (
    .out(gen36_1),
    .ina(gen21_1),
    .inb(gen19_1)
);
MSKxor #(.d(d)) comp_gen25_1 (
    .out(gen25_1),
    .ina(gen35_1),
    .inb(gen43_1)
);
MSKxor #(.d(d)) comp_gen26_1 (
    .out(gen26_1),
    .ina(gen40_1),
    .inb(gen41_1)
);
MSKxor #(.d(d)) comp_gen38_1 (
    .out(gen38_1),
    .ina(gen36_1),
    .inb(gen37_1)
);
MSKxor #(.d(d)) comp_gen27_2 (
    .out(gen27_2),
    .ina(gen25_2),
    .inb(gen26_2)
);
MSKxor #(.d(d)) comp_gen22_1 (
    .out(gen22_1),
    .ina(gen38_1),
    .inb(gen42_1)
);
MSKxor #(.d(d)) comp_gen24_2 (
    .out(gen24_2),
    .ina(gen22_2),
    .inb(gen23_2)
);
MSKg4mul_hpc3 #(.d(d)) comp_gen29_2 (
    .out0(gen29_2),
    .out1(gen31_2),
    .rnd(rnd_1[0 +: 2*d*(d-1)]),
    .ina0(gen22_1),
    .ina0_prev(gen22_2),
    .ina1(gen25_1),
    .ina1_prev(gen25_2),
    .inb0(gen23_1),
    .inb1(gen26_1),
    .clk(clk)
);
MSKxor #(.d(d)) comp_gen28_2 (
    .out(gen28_2),
    .ina(gen24_2),
    .inb(gen27_2)
);
MSKxor #(.d(d)) comp_gen32_2 (
    .out(gen32_2),
    .ina(gen27_2),
    .inb(gen31_2)
);
MSKxor #(.d(d)) comp_gen30_2 (
    .out(gen30_2),
    .ina(gen28_2),
    .inb(gen29_2)
);
MSKg4mul_hpc3 #(.d(d)) comp_gen59_3 (
    .out0(gen59_3),
    .out1(gen60_3),
    .rnd(rnd_2[0 +: 2*d*(d-1)]),
    .ina0(gen32_2),
    .ina0_prev(gen32_3),
    .ina1(gen30_2),
    .ina1_prev(gen30_3),
    .inb0(gen23_2),
    .inb1(gen26_2),
    .clk(clk)
);
MSKg4mul_hpc3 #(.d(d)) comp_gen61_3 (
    .out0(gen61_3),
    .out1(gen62_3),
    .rnd(rnd_2[1*(2*d*(d-1)) +: 2*d*(d-1)]),
    .ina0(gen32_2),
    .ina0_prev(gen32_3),
    .ina1(gen30_2),
    .ina1_prev(gen30_3),
    .inb0(gen22_2),
    .inb1(gen25_2),
    .clk(clk)
);
MSKg16mul_hpc3 #(.d(d)) comp_gen48_4 (
    .out0(gen48_4),
    .out1(gen57_4),
    .out2(gen53_4),
    .out3(gen58_4),
    .rnd(rnd_3[0 +: 4*d*(d-1)]),
    .ina0(gen61_3),
    .ina0_prev(gen61_4),
    .ina1(gen62_3),
    .ina1_prev(gen62_4),
    .ina2(gen59_3),
    .ina2_prev(gen59_4),
    .ina3(gen60_3),
    .ina3_prev(gen60_4),
    .inb0(gen10_3),
    .inb1(gen12_3),
    .inb2(i0_3),
    .inb3(gen19_3),
    .clk(clk)
);
MSKg16mul_hpc3 #(.d(d)) comp_gen51_4 (
    .out0(gen51_4),
    .out1(gen47_4),
    .out2(gen52_4),
    .out3(gen45_4),
    .rnd(rnd_3[1*(4*d*(d-1)) +: 4*d*(d-1)]),
    .ina0(gen61_3),
    .ina0_prev(gen61_4),
    .ina1(gen62_3),
    .ina1_prev(gen62_4),
    .ina2(gen59_3),
    .ina2_prev(gen59_4),
    .ina3(gen60_3),
    .ina3_prev(gen60_4),
    .inb0(gen20_3),
    .inb1(gen14_3),
    .inb2(gen16_3),
    .inb3(gen21_3),
    .clk(clk)
);
MSKxor #(.d(d)) comp_gen49_4 (
    .out(gen49_4),
    .ina(gen47_4),
    .inb(gen48_4)
);
MSKxor #(.d(d)) comp_gen50_4 (
    .out(gen50_4),
    .ina(gen45_4),
    .inb(gen48_4)
);
MSKxor #(.d(d)) comp_gen44_4 (
    .out(gen44_4),
    .ina(gen51_4),
    .inb(gen52_4)
);
MSKxor #(.d(d)) comp_gen2_4 (
    .out(gen2_4),
    .ina(gen51_4),
    .inb(gen53_4)
);
MSKxor #(.d(d)) comp_o7_4 (
    .out(o7_4),
    .ina(gen45_4),
    .inb(gen57_4)
);
MSKxor #(.d(d)) comp_gen3_4 (
    .out(gen3_4),
    .ina(gen45_4),
    .inb(gen58_4)
);
MSKxor #(.d(d)) comp_gen0_4 (
    .out(gen0_4),
    .ina(gen49_4),
    .inb(gen53_4)
);
MSKxor #(.d(d)) comp_gen1_4 (
    .out(gen1_4),
    .ina(gen49_4),
    .inb(gen57_4)
);
MSKxor #(.d(d)) comp_gen55_4 (
    .out(gen55_4),
    .ina(gen50_4),
    .inb(gen57_4)
);
MSKxor #(.d(d)) comp_gen46_4 (
    .out(gen46_4),
    .ina(gen44_4),
    .inb(gen45_4)
);
MSKinv #(.d(d)) comp_o5_4 (
    .out(o5_4),
    .in(gen2_4)
);
MSKxor #(.d(d)) comp_o4_4 (
    .out(o4_4),
    .ina(o7_4),
    .inb(gen58_4)
);
MSKinv #(.d(d)) comp_o6_4 (
    .out(o6_4),
    .in(gen3_4)
);
MSKinv #(.d(d)) comp_o0_4 (
    .out(o0_4),
    .in(gen0_4)
);
MSKinv #(.d(d)) comp_o1_4 (
    .out(o1_4),
    .in(gen1_4)
);
MSKxor #(.d(d)) comp_gen56_4 (
    .out(gen56_4),
    .ina(gen55_4),
    .inb(gen53_4)
);
MSKxor #(.d(d)) comp_gen54_4 (
    .out(gen54_4),
    .ina(gen46_4),
    .inb(gen57_4)
);
MSKxor #(.d(d)) comp_o3_4 (
    .out(o3_4),
    .ina(gen56_4),
    .inb(gen58_4)
);
MSKxor #(.d(d)) comp_o2_4 (
    .out(o2_4),
    .ina(gen54_4),
    .inb(gen53_4)
);
MSKreg #(.d(d)) reg_gen61_3 (
    .in(gen61_3),
    .out(gen61_4),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen62_3 (
    .in(gen62_3),
    .out(gen62_4),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen16_0 (
    .in(gen16_0),
    .out(gen16_1),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen16_1 (
    .in(gen16_1),
    .out(gen16_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen16_2 (
    .in(gen16_2),
    .out(gen16_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_i0_0 (
    .in(i0_0),
    .out(i0_1),
    .clk(clk)
);
MSKreg #(.d(d)) reg_i0_1 (
    .in(i0_1),
    .out(i0_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_i0_2 (
    .in(i0_2),
    .out(i0_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen12_0 (
    .in(gen12_0),
    .out(gen12_1),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen12_1 (
    .in(gen12_1),
    .out(gen12_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen12_2 (
    .in(gen12_2),
    .out(gen12_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen19_0 (
    .in(gen19_0),
    .out(gen19_1),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen19_1 (
    .in(gen19_1),
    .out(gen19_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen19_2 (
    .in(gen19_2),
    .out(gen19_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen22_1 (
    .in(gen22_1),
    .out(gen22_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen20_0 (
    .in(gen20_0),
    .out(gen20_1),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen20_1 (
    .in(gen20_1),
    .out(gen20_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen20_2 (
    .in(gen20_2),
    .out(gen20_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen14_0 (
    .in(gen14_0),
    .out(gen14_1),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen14_1 (
    .in(gen14_1),
    .out(gen14_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen14_2 (
    .in(gen14_2),
    .out(gen14_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen10_0 (
    .in(gen10_0),
    .out(gen10_1),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen10_1 (
    .in(gen10_1),
    .out(gen10_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen10_2 (
    .in(gen10_2),
    .out(gen10_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen26_1 (
    .in(gen26_1),
    .out(gen26_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen23_1 (
    .in(gen23_1),
    .out(gen23_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen60_3 (
    .in(gen60_3),
    .out(gen60_4),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen59_3 (
    .in(gen59_3),
    .out(gen59_4),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen21_0 (
    .in(gen21_0),
    .out(gen21_1),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen21_1 (
    .in(gen21_1),
    .out(gen21_2),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen21_2 (
    .in(gen21_2),
    .out(gen21_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen32_2 (
    .in(gen32_2),
    .out(gen32_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen30_2 (
    .in(gen30_2),
    .out(gen30_3),
    .clk(clk)
);
MSKreg #(.d(d)) reg_gen25_1 (
    .in(gen25_1),
    .out(gen25_2),
    .clk(clk)
);
endmodule
