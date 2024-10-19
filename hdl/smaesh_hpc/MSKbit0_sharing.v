module MSKbit0_sharing
#
(
    parameter integer d = 2
)
(
    input [d-2:0] rnd,
    output [d-1:0] sh_out
);

genvar i;
generate
for(i=0;i<d;i=i+1) begin: gen_rnd_use
    if (i==0) begin: gen_sh_out_init
        assign sh_out[i] = rnd[0];
    end else if(i==d-1) begin: gen_sh_out_last
        assign sh_out[i] = rnd[d-2];
    end else begin: gen_sh_out_others
        assign sh_out[i] = rnd[i] ^ rnd[i-1];
    end
end
endgenerate

endmodule
