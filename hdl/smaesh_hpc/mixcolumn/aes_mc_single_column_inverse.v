// Mixcolumn inverse operation for a single column
module aes_mc_single_column_inverse
(
    input [31:0] cin,
    output [31:0] cout
);

// Intermediate byte values
wire [7:0] x [4];
wire [7:0] xt2 [4];
wire [7:0] xt3 [4];
wire [7:0] xt4 [4];
wire [7:0] xt5 [4];
wire [7:0] xt6 [4];
wire [7:0] xt7 [4];
wire [7:0] xt8 [4];
wire [7:0] xt9 [4];
wire [7:0] xta [4];
wire [7:0] xtb [4];
wire [7:0] xtc [4];
wire [7:0] xtd [4];
wire [7:0] xte [4];

genvar i;
generate
for(i=0;i<4;i=i+1) begin: gen_product
    // Fetch X
    assign x[i] = cin[8*i +: 8];
    // x times 02
    xtime xt_2(.x(x[i]), .y(xt2[i]));
    // x times 03
    assign xt3[i] = xt2[i] ^ x[i];
    // x times 04
    xtime xt_4(.x(xt2[i]), .y(xt4[i]));
    // x times 05
    assign xt5[i] = xt4[i] ^ x[i];
    // x times 06
    xtime xt_6(.x(xt3[i]), .y(xt6[i]));
    // x times 07
    assign xt7[i] = xt6[i] ^ x[i];
    // x times 08
    xtime xt_8(.x(xt4[i]), .y(xt8[i]));
    // x times 09
    assign xt9[i] = xt8[i] ^ x[i];
    // x times 0a
    xtime xt_a(.x(xt5[i]), .y(xta[i]));
    // x times 0b
    assign xtb[i] = xta[i] ^ x[i];
    // x times 0c
    xtime xt_c(.x(xt6[i]), .y(xtc[i]));
    // x times 0d
    assign xtd[i] = xtc[i] ^ x[i];
    // x times 0e
    xtime xt_e(.x(xt7[i]), .y(xte[i]));
end
endgenerate

// Compute the results for each rows
assign cout[0 +: 8] = xte[0] ^ xtb[1] ^ xtd[2] ^ xt9[3];
assign cout[8 +: 8] = xt9[0] ^ xte[1] ^ xtb[2] ^ xtd[3];
assign cout[16 +: 8] = xtd[0] ^ xt9[1] ^ xte[2] ^ xtb[3];
assign cout[24 +: 8] = xtb[0] ^ xtd[1] ^ xt9[2] ^ xte[3];

endmodule
