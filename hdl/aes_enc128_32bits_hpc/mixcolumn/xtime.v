// Xtime over GF(256) with irreductible polynomial x^8+x^4+x^3+x+1
module xtime
(
    input [7:0] x,
    output [7:0] y
);

wire [7:0] x_shifted = {x[6:0],1'b0};
wire [7:0] cst_mask = {8{x[7]}} & 8'h1b;
assign y = x_shifted ^ cst_mask;
endmodule

