module MSKrefresh_tree
#
(
    parameter integer d = 2,
    parameter integer BITS = 16
)
(
    input [d*BITS-1:0] sh_in,
    output [d*BITS-1:0] sh_out,
    input [(d-1)*BITS-1:0] rnd
);

genvar i, j;
generate
for(i=0;i<BITS;i=i+1) begin: gen_bit_refresh
    // fetch data used in refresh
    wire [d-1:0] bit_used = sh_in[i*d +: d];
    wire [d-2:0] rnd_used = rnd[i*(d-1) +: d-1];
    // Generate the sharing of zero for the refreshed bit
    wire [d-1:0] sh_bit_zero;
    MSKbit0_sharing #(.d(d))
    sharing_bit_zero(
        .rnd(rnd_used),
        .sh_out(sh_bit_zero)
    );
    // Xor for the refresh
    MSKxor #(.d(d), .count(1))
    xor_refresh(
        .ina(sh_bit_zero),
        .inb(bit_used),
        .out(sh_out[i*d +: d])
    );
end
endgenerate
endmodule
