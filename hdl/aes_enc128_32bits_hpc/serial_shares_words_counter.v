module serial_shares_words_counter
#
(
    parameter NBITS = 4,
    parameter MAX_WORDS_PER_SHARE = 8,
    parameter d = 2
)
(
    clk,
    rst, // Active high reset
    inc, // Active high increment
    words_per_share_bound, // Bound of the amount of words per share to consider when counting 
    share_idx, 
    word_idx
);

input clk;
input rst;
input inc;
input [NBITS-1:0] words_per_share_bound;
output [NBITS-1:0] share_idx;
output [NBITS-1:0] word_idx;

// Counter of the amount of words
reg [NBITS-1:0] cnt_words;
wire soft_reset;
always@(posedge clk)
if(rst | soft_reset) begin
    cnt_words <= 0;
end else if (inc) begin
    cnt_words <= cnt_words + 1;
end
wire inc_share_needed = (cnt_words == words_per_share_bound);
assign soft_reset = inc & inc_share_needed;

// Counter fpr the shares
reg [NBITS-1:0] cnt_shares;
always@(posedge clk) 
if(rst) begin
    cnt_shares <= 0;        
end else if (inc & inc_share_needed) begin
    cnt_shares <= cnt_shares + 1;
end 

assign share_idx = cnt_shares;
assign word_idx = cnt_words;




endmodule
