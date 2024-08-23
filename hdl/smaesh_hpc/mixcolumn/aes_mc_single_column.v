// Mixcolumn operation for a single column
module aes_mc_single_column
(
    input [31:0] cin, 
    output [31:0] cout
);

// Intermediate byte values
wire [7:0] x [3:0];
wire [7:0] xt2 [3:0];
wire [7:0] xt3 [3:0];

genvar i;
generate
for(i=0;i<4;i=i+1) begin: product
    // Fetch X
    assign x[i] = cin[8*i +: 8];
    // Compute x times 02
    xtime xtb(.x(x[i]), .y(xt2[i]));
    // Compute x times 03
    assign xt3[i] = xt2[i] ^ x[i];
end
endgenerate

// Compute the results for each rows
assign cout[0 +: 8] = xt2[0] ^ xt3[1] ^ x[2] ^ x[3];
assign cout[8 +: 8] = x[0] ^ xt2[1] ^ xt3[2] ^ x[3];
assign cout[16 +: 8] = x[0] ^ x[1] ^ xt2[2] ^ xt3[3];
assign cout[24 +: 8] = xt3[0] ^ x[1] ^ x[2] ^ xt2[3];

endmodule
