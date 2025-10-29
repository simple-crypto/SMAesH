module bus_offset_decoder
#(
    parameter TL_W=4
)
(
    mask,
    offset
);

parameter LOG2_TL_W = $clog2(TL_W);
input [TL_W-1:0] mask;
output [LOG2_TL_W-1:0] offset;

// Recover the location of the first bit set to HIGH in mask. 
// To do so, we generate a vector of TL_W bits, where the v[i]=0 if the first
// 1 of mask[0:i-1] is full of zero. In such a case, we can easily recover the
// location of the first 1 in the mask (which is the offset we look for) by
// adding the amount of 1 in v. 
wire [TL_W-1:0] v;
wire [TL_W-1:0] not_v;
wire [LOG2_TL_W-1:0] sum [TL_W-1:0];
genvar i;
generate
    for(i=0;i<TL_W;i=i+1) begin: vi 
        assign not_v[i] = ~v[i];
        if(i==0) begin
            assign v[i] = mask[i];
            assign sum[i] = not_v[i];
        end else begin 
            assign v[i] = (|v[i-1:0]) | mask[i];
            assign sum[i] = sum[i-1] + not_v[i];
        end
    end
endgenerate

// Assign the output
assign offset = sum[TL_W-1];


endmodule
