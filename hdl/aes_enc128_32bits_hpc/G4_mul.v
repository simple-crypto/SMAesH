
// multiplication in GF(2^2) using normal basis (Omega^2, Omega)
module G4_mul(input wire [1:0] x, input wire [1:0] y, output wire [1:0] z);
    wire a, b, c, d, e;
    assign a = x[1];
    assign b = x[0];
    assign c = y[1];
    assign d = y[0];
    assign e = (a ^ b) & (c ^ d);
    assign z[1] = (a & c) ^ e;
    assign z[0] = (b & d) ^ e;
endmodule


