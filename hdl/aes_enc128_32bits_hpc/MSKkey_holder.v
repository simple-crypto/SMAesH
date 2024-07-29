module MSKkey_holder
#(
    parameter d = 2
)
(
    // Clock
    clk,
    rst,
    // Data in interface (used to set the new key) 
    data_in,
    data_in_valid,
    data_in_ready,
    // Data in, from the core, used for reverse mode
    sh_last_key_col,
    sh_last_key_col_pre_valid,
    // Long term shared key stored
    sh_data_out,
    // Randomness for refreshing
    rnd_rfrsh_in,
    rnd_rfrsh_in_valid,
    // Control
    start_fetch_procedure,
    key_size_cfg, // SYNC with start_fetch_procedure
    mode_inverse, // SYNC with start_fetch_procedure
    busy,
    aes_busy,
    // To AES core
    last_key_computation_required,
    aes_mode_256,
    aes_mode_192,
    aes_mode_inverse
);

`include "smaesh_config.vh"

// Generation param
localparam BITS = 256;
localparam RFRSH_RATE = 16;

// API
input clk;
input rst;

input [31:0] data_in;
input data_in_valid;
output reg data_in_ready;

input [32*d-1:0] sh_last_key_col; 
input sh_last_key_col_pre_valid;

output [d*BITS-1:0] sh_data_out;

input [(d-1)*RFRSH_RATE-1:0] rnd_rfrsh_in;
input rnd_rfrsh_in_valid;

input start_fetch_procedure;
input [1:0] key_size_cfg;
input mode_inverse;

output reg busy;
input aes_busy;

output aes_mode_256;
output aes_mode_192;
output aes_mode_inverse;
output reg last_key_computation_required;

// Low level data holder
wire [RFRSH_RATE*d-1:0] ll_shares_data_in;
wire [d-1:0] ll_enable;
reg ll_fetch_in;
MSKdata_holder_low_level #(.d(d), .BITS(BITS), .RFRSH_RATE(RFRSH_RATE))
ll_data_holder(
    .clk(clk),
    .shares_data_in(ll_shares_data_in),
    .sh_data_out(sh_data_out),
    .rnd_rfrsh_in(rnd_rfrsh_in),
    .enable(ll_enable),
    .fetch_in(ll_fetch_in)
);



// Register to hold the execution status of the key configured
reg fetch_config_flag;
reg [1:0] cfg_key_size;
reg cfg_mode_inverse;
always@(posedge clk) 
if(rst) begin
    cfg_key_size <= 2'b0;
    cfg_mode_inverse <= 0;
end else if(fetch_config_flag) begin
    cfg_key_size <= key_size_cfg;
    cfg_mode_inverse <= mode_inverse;
end
assign aes_mode_256 = cfg_key_size == KSIZE_256;
assign aes_mode_192 = cfg_key_size == KSIZE_192;
assign aes_mode_inverse = cfg_mode_inverse;

// Generation parameter for the amount of round 
localparam MAX_WORDS_PER_SHARE = BITS/RFRSH_RATE;
localparam AM_WMAX = MAX_WORDS_PER_SHARE*d;
parameter SIZE_CNT = $clog2(AM_WMAX);
reg [SIZE_CNT-1:0] words_per_share_bound;

reg rst_count_words;
reg inc_count_words;
wire [SIZE_CNT-1:0] share_idx;
wire [SIZE_CNT-1:0] word_idx;

serial_shares_words_counter #(
    .NBITS(SIZE_CNT), 
    .MAX_WORDS_PER_SHARE(MAX_WORDS_PER_SHARE),
    .d(d)
) cnt_words (
    .clk(clk),
    .rst(rst | rst_count_words),
    .inc(inc_count_words),
    .words_per_share_bound(words_per_share_bound),
    .share_idx(share_idx),
    .word_idx(word_idx)
);

// Some generation parameters
localparam AMW_256 = 256/RFRSH_RATE;
localparam AMW_128 = 128/RFRSH_RATE;
localparam AMW_192 = 192/RFRSH_RATE;
localparam NW_OFFSET192 = AMW_256 - AMW_192; 

// Logic to generate the different enable signal for low-level holder
genvar i;
wire [d-1:0] llenable_mode_fetch;
generate
for(i=0;i<d;i=i+1) begin: bit_llen_fetch
    assign llenable_mode_fetch[i] = share_idx == i; 
end
endgenerate
wire [d-1:0] llenable_mode_ksched = {d{1'b1}};

reg ll_enable_mask;
reg ll_enable_from_ksched;
assign ll_enable = {d{ll_enable_mask}} & (
    ll_enable_from_ksched ? llenable_mode_ksched : llenable_mode_fetch
);

// "FIFO" like buffer, to feed data at the input of the holder as expected
reg enable_buffer_api;
wire [15:0] buffer_in;
MSKregEn #(.d(1), .count(16))
buffer_reg (
    .clk(clk),
    .en(enable_buffer_api),
    .in(data_in[31:16]),
    .out(buffer_in)
);

reg data_in_from_buffer;
wire [15:0] data_in_selected; // Data selected in fetch (either input or buffer)
MSKmux #(.d(1), .count(RFRSH_RATE))
mux_to_holder_ll(
    .sel(data_in_from_buffer),
    .in_true(buffer_in),
    .in_false(data_in[15:0]),
    .out(data_in_selected)
);

reg enforce_data_in_zero;
wire [15:0] data_in_selected_gated = enforce_data_in_zero ? 16'b0 : data_in_selected;


//// Mux architecture used when last key must be fetched
wire [d*32-1:0] shares_last_key_col;
shbus2shares #(.d(d), .count(32))
decode_last_key_col(
    .shbus(sh_last_key_col),
    .shares(shares_last_key_col)
);

reg fetch_key_lcol_high;
wire [d*16-1:0] shares_last_key_col_selected;
generate
for(i=0;i<d;i=i+1) begin: str_mux_lkc
    assign shares_last_key_col_selected[i*16 +: 16] = fetch_key_lcol_high ?
    shares_last_key_col[32*i+16 +: 16] : shares_last_key_col[32*i +: 16];
end
endgenerate

//// Mux at the input of the low level holder
// Format the shares_data_in: replicated d time the input 
wire [d*RFRSH_RATE-1:0] shares_data_in; 
generate
for(i=0;i<d;i=i+1) begin: replicate
    assign shares_data_in[i*RFRSH_RATE +: RFRSH_RATE] = data_in_selected_gated;
end
endgenerate

reg fetch_from_kschedule;
assign ll_shares_data_in = fetch_from_kschedule ?
shares_last_key_col_selected : shares_data_in;

// Register in order to generate a pulse when a new execution of the 
// core starts
reg previous_aes_busy;
always@(posedge clk)
if(rst) begin
    previous_aes_busy <= 0;
end else begin
    previous_aes_busy <= aes_busy;
end
wire aes_exec_started = aes_busy & ~previous_aes_busy;

// FSM
localparam 
IDLE = 0,
FETCH_DATA = 1,
FEED_FROM_BUFFER = 2,
PAD_ZERO_NEW_KEY = 3,
START_KEY_COMPUTATION = 4,
WAIT_KEY_COMPUTATION = 5,
FETCH_KEY_MATERIAL = 6,
PAD_ZERO_LAST_KEY = 7,
IN_REFRESH = 8
;

localparam STATE_BITS = 4;
reg [STATE_BITS-1:0] state, nextstate;
always@(posedge clk)
if(rst) begin
    state <= IDLE;
end else begin
    state <= nextstate;
end

// Virtual state used for branching
reg [STATE_BITS-1:0] branch_compute_last;
reg in_branch_compute_last, in_padding, in_fetch_new_key, in_fetch_last_key, in_fetch_from_buffer, in_refresh;


// Assign the words_per_share_bound
always@(*) begin
    case(cfg_key_size)
        KSIZE_192: words_per_share_bound = in_padding ? NW_OFFSET192-1 : AMW_192-1;
        KSIZE_256: words_per_share_bound = AMW_256-1;
        default: words_per_share_bound = AMW_128-1;
    endcase
end

// fsm internal control
wire last_word_fetch = (share_idx == d-1) & (word_idx == words_per_share_bound);
wire last_last_key_word_fetch = (share_idx == 0) & (word_idx == words_per_share_bound); 
reg last_refresh_word; 
reg last_new_pad_word;

always@(*) begin
    // CAUTION: the key holder is in practice holding 256 bits, but not all are
    // used in version 128/192. However, due to its architecture acting a a
    // shift register of 256/RFRSH_RATE stages, specific consideration must be
    // taken for the execution of AES128 and AES192 in order to ensure that the
    // key value is properly encoded at the end of the refresh procedure. In
    // practice, this translates in counter more words than the amount of words
    // required to perform the refresh, enforcing then the shifting of data
    // through the pipeline. 
    case(cfg_key_size)
        KSIZE_192: begin
            last_refresh_word = (share_idx == 1) & (word_idx == NW_OFFSET192-1);
        end
        KSIZE_256: begin
            last_refresh_word = (share_idx == 0) & (word_idx == words_per_share_bound);
        end
        default: begin
            last_refresh_word = (share_idx == 1) & (word_idx == words_per_share_bound); 
        end
    endcase
end

// FSM 
always@(*) begin
    nextstate = state;
    busy = 1;
    last_key_computation_required = 0;

    enable_buffer_api = 0;

    // Related to the bus for fetching data from outside the core
    data_in_ready = 0;
   
    // Allows the enable of low loevel key holder
    ll_enable_mask = 0;

    // FSM control
    fetch_config_flag = 0;

    rst_count_words = 0;
    inc_count_words = 0;

    in_branch_compute_last = 0;
    in_padding = 0;
    in_fetch_new_key = 0;
    in_fetch_last_key = 0;
    in_fetch_from_buffer = 0;
    in_refresh = 0;

    case (state)
        IDLE: begin
            busy = 0;
            rst_count_words = 1;
            // First branch if a new execution started (refresh handling)
            if(aes_exec_started) begin
                nextstate = IN_REFRESH; 
                rst_count_words = 1;
            // Second branch if a new key is loaded 
            end else if(start_fetch_procedure) begin
                nextstate = FETCH_DATA;        
                fetch_config_flag = 1;
            end 
        end
        FETCH_DATA: begin
            data_in_ready = 1;
            in_fetch_new_key = 1;
            if(data_in_valid) begin
                nextstate = FEED_FROM_BUFFER;
                inc_count_words = 1;
                enable_buffer_api = 1;
                ll_enable_mask = 1;
            end
        end 
        FEED_FROM_BUFFER: begin
            inc_count_words = 1;
            in_fetch_new_key = 1;
            in_fetch_from_buffer = 1;
            ll_enable_mask = 1;
            if (last_word_fetch) begin
                if(cfg_key_size == KSIZE_256) begin
                    nextstate = branch_compute_last;
                    in_branch_compute_last = 1;
                end else begin
                    nextstate = PAD_ZERO_NEW_KEY; 
                    rst_count_words = 1;
                end
            end else begin
                nextstate = FETCH_DATA;
            end
        end
        PAD_ZERO_NEW_KEY: begin
            inc_count_words = 1;
            in_fetch_new_key = 1;
            in_padding = 1;
            ll_enable_mask = 1;
            if(last_word_fetch) begin 
                nextstate = branch_compute_last;
                in_branch_compute_last = 1;
            end
        end
        START_KEY_COMPUTATION: begin
            last_key_computation_required = 1;
            if(aes_exec_started) begin
                nextstate = WAIT_KEY_COMPUTATION;
            end
        end
        WAIT_KEY_COMPUTATION: begin
            if (sh_last_key_col_pre_valid) begin
                rst_count_words = 1;
                nextstate = FETCH_KEY_MATERIAL;
            end
        end
        FETCH_KEY_MATERIAL: begin
            inc_count_words = 1;
            in_fetch_last_key = 1;
            ll_enable_mask = 1;
            if (last_last_key_word_fetch) begin
                if(cfg_key_size == KSIZE_256) begin
                    nextstate = IDLE;
                end else begin
                    nextstate = PAD_ZERO_LAST_KEY;
                    rst_count_words = 1;
                end
            end 
        end
        PAD_ZERO_LAST_KEY: begin
            inc_count_words = 1;
            in_fetch_last_key = 1;
            in_padding = 1;
            ll_enable_mask = 1;
            if(last_last_key_word_fetch) begin
                nextstate = IDLE; 
            end
        end
        IN_REFRESH: begin
            in_refresh = 1;
            ll_enable_from_ksched = 1; 
            if(rnd_rfrsh_in_valid) begin
                inc_count_words = 1;
                ll_enable_mask = 1; 
                if(last_refresh_word) begin
                    nextstate = IDLE; 
                end
            end
        end
    endcase

end

always@(*) begin
    // Default
    data_in_from_buffer = 0; 
    fetch_key_lcol_high = 0; // fetch 16 last bits for the lask col 
    fetch_from_kschedule = in_fetch_last_key; // Input to ll from kschedule

    // LL data holder
    ll_fetch_in = 0; // Mux taking data from input instead of refresh shift
    ll_enable_from_ksched = 0; // data at the input comes from the key scheduling
    enforce_data_in_zero = 0;

    // Logic for branch_compute_last
    if(cfg_mode_inverse) begin
        branch_compute_last = START_KEY_COMPUTATION;
    end else begin
        branch_compute_last = IDLE;
    end

    ll_enable_from_ksched = in_fetch_last_key;
    data_in_from_buffer = in_fetch_from_buffer; 
    fetch_key_lcol_high = word_idx[0];
    if (in_padding) begin
        ll_fetch_in = 1;
        enforce_data_in_zero = 1;
    end else if (in_fetch_new_key | in_fetch_last_key) begin
        ll_fetch_in = 1;  
    end
    
end


endmodule
