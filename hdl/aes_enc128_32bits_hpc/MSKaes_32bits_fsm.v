// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-S-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-S v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-S v2 (https://ohwr.org/cern_ohl_s_v2.txt ).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-S v2 for applicable conditions.
// Source location: https://github.com/simple-crypto/SMAesH
// As per CERN-OHL-S v2 section 4, should You produce hardware based
// on this source, You must where practicable maintain the Source Location
// visible on the external case of any product you make using this source.

(* fv_prop = "PINI", fv_strat = "flatten" *)
module MSKaes_32bits_fsm
(
    clk,
    rst,
    busy,
    inverse,
    key_schedule_only,
    // Once asserted, expected to remain high until exchange completion.
    valid_in,
    in_ready,
    out_ready,
    // Once asserted, should remain high until exhcange completion
    cipher_valid,
    global_init,
    // AES core control
    state_enable,
    state_init,
    state_en_MC,
    state_en_loop,
    state_en_loop_r0,
    state_en_SB_inverse,
    state_bypass_MC_inverse,
    state_en_toSB_inverse,
    // Key handling
    KH_init,
    KH_enable,
    KH_loop,
    KH_add_from_sb,
    KH_enable_buffer_from_sbox,
    KH_rst_buffer_from_sbox,
    KH_last_key_valid,
    // RCON holder
    rcon_rst,
    rcon_update,
    rcon_inverse,
    // Randomness
    pre_need_rnd, 
    // Sbox
    sbox_valid_in,
    sbox_inverse,
    // Mux input sbox
    feed_sb_key,
    enable_key_add,
    enable_key_add_inverse
);

// IOs
input clk;
input rst;
output busy;
input inverse;
input key_schedule_only;
input valid_in;
output in_ready;
input out_ready;
output cipher_valid;
output reg global_init;
// AES core control
output reg state_enable;
output reg state_init;
output reg state_en_MC;
output reg state_en_loop;
output reg state_en_loop_r0; 
output reg state_en_SB_inverse;  
output reg state_bypass_MC_inverse;  
output reg state_en_toSB_inverse; 
// Key handling
output reg KH_init;
output reg KH_enable;
output reg KH_loop;
output reg KH_add_from_sb;
output reg KH_enable_buffer_from_sbox; 
output reg KH_rst_buffer_from_sbox;
output reg KH_last_key_valid;
// RCON holder
output reg rcon_rst;
output reg rcon_update;
output reg rcon_inverse; 
// Randomness
output reg pre_need_rnd; 
// Sbox
output reg sbox_valid_in;
output reg sbox_inverse;
// Mux input sbox
output reg feed_sb_key;
output reg enable_key_add;
output reg enable_key_add_inverse; 

// Generation parameters
localparam SERIAL_LAT=4;
localparam SBOX_LAT=4;
localparam FIRST_KEXP_CYCLE=SBOX_LAT-1;


// FSM
localparam IDLE = 0,
FIRST_SB_K = 1,
WAIT_ROUND = 2,
WAIT_LAST_ROUND = 3,
WAIT_AKfinal = 4;

reg [3:0] state, nextstate;

// Global counter for the fsm
reg [3:0] cnt_fsm;
reg cnt_fsm_inc, cnt_fsm_reset;
always@(posedge clk)
if(cnt_fsm_reset) begin
    cnt_fsm <= 0;
end else if(cnt_fsm_inc) begin
    cnt_fsm <= cnt_fsm + 1;
end

wire first_round_cycle = cnt_fsm == 0;
wire last_round_cycle = cnt_fsm == SBOX_LAT+SERIAL_LAT-1;
wire pre_last_round_cycle = cnt_fsm == SBOX_LAT+SERIAL_LAT-2;
wire last_FAK_cycle = cnt_fsm == SERIAL_LAT-1;

wire in_AKSB = cnt_fsm<SERIAL_LAT;
wire in_AKSB_except_last = cnt_fsm < SERIAL_LAT-1;

wire in_KS_KEYUPDATE = (cnt_fsm >= (SBOX_LAT-1)) & (cnt_fsm < SBOX_LAT+3);


wire in_KEXP_FIRST = cnt_fsm==FIRST_KEXP_CYCLE;
wire in_KEXP = (cnt_fsm>=FIRST_KEXP_CYCLE) & (cnt_fsm<(FIRST_KEXP_CYCLE+SERIAL_LAT));

wire key_from_sbox = (cnt_fsm==(SBOX_LAT-1));

// Round counter
reg [3:0] cnt_round;
reg cnt_round_inc, cnt_round_reset;
always@(posedge clk)
if(cnt_round_reset) begin
    cnt_round <= 0;
end else if(cnt_round_inc) begin
    cnt_round <= cnt_round + 1;
end

wire last_full_round = cnt_round == 8;

// State register
always@(posedge clk)
if(rst) begin
    state <= IDLE;
end else begin
    state <= nextstate;
end

// Register to save the execution status
reg exec_status_inverse;
reg exec_status_key_schedule_only;

reg save_exec_status, rst_exec_status;
always@(posedge clk)
if(rst_exec_status) begin
    exec_status_inverse <= 1'b0;
    exec_status_key_schedule_only <= 1'b0;
end else if(save_exec_status) begin
    exec_status_inverse <= inverse;
    exec_status_key_schedule_only <= key_schedule_only;
end


// Register to keep the cipher_valid signal
reg set_valid_out;
reg valid_out_reg;
wire cipher_fetch = valid_out_reg & out_ready;
always@(posedge clk)
if(rst | cipher_fetch) begin
    valid_out_reg <= 0;
end else if(set_valid_out) begin
    valid_out_reg <= 1; 
end

assign cipher_valid = valid_out_reg;

// in_ready handling. According to the SVRS protocol, the input interface
// signal is sticky (the data and the in_valid signals remains fixed once 
// in_valid is asserted until transfer completion). It also specifies that 
// no combinatorial path should exist between the input and the output interface
// (e.g., out_ready and in_ready). A special handling of the in_ready
// signal should occurs in order to not lose clock cycle due to the transfer when 
// the core is in regime with back pressure. In particular, the core benefit 
// from the information that the data may not change once specified as valid at the input
// by starting processing it before asserting the in_ready signal. In such a way, the 
// in regime latency is not affected in practice by the handshake. 
// 
// In practice, the in_ready signal is thus asserted
// - at the reset of the core
// - when no execution is in progress (IDLE mode) and that no valid output remains in the core.

reg reg_in_ready;
reg next_in_ready;
always@(posedge clk)
if(rst) begin
    reg_in_ready <= 1;
end else begin
    reg_in_ready <= next_in_ready;
end
assign in_ready = reg_in_ready;

// Signal to properly start the execution
wire start_exec = valid_in & (~valid_out_reg | cipher_fetch);

// Global status
reg in_fetch, in_first_SBK, in_round, in_last_round, in_AKfinal, in_reset_KH;
wire is_first_round = cnt_round == 0;

// Nextstate logic
always@(*) begin
    nextstate = state;  

    cnt_fsm_reset = 0;
    cnt_round_reset = 0; 
    cnt_round_inc = 0;
    
    in_fetch = 0;
    in_first_SBK = 0;
    in_round = 0;
    in_last_round = 0;
    in_AKfinal = 0;
    in_reset_KH = 0;

    rcon_rst = 0;
    rcon_update = 0;

    save_exec_status = 0;
    rst_exec_status = 0;

    case(state)
        IDLE: begin
            if(start_exec) begin
                in_fetch = 1;
                nextstate = FIRST_SB_K;
                cnt_fsm_reset = 1;
                cnt_round_reset = 1;
                rcon_rst = 1;
                save_exec_status = 1;
            end else begin
                if (~valid_out_reg | cipher_fetch) begin
                    in_reset_KH = 1;
                    rst_exec_status = 1;
                end
            end
        end
        FIRST_SB_K: begin
            in_first_SBK = 1;
            nextstate = WAIT_ROUND;
            cnt_fsm_reset = 1;
        end
        WAIT_ROUND: begin
            in_round = 1;
            if(last_round_cycle) begin
                cnt_fsm_reset = 1;
                cnt_round_inc = 1;
                rcon_update = 1;
                if(last_full_round) begin
                    nextstate = WAIT_LAST_ROUND;
                end else begin
                    nextstate = WAIT_ROUND;
                end
            end
        end
        WAIT_LAST_ROUND: begin
            in_last_round = 1;
            if(last_round_cycle) begin
                nextstate = WAIT_AKfinal;
                cnt_fsm_reset = 1;
                cnt_round_inc = 1;
            end
        end
        WAIT_AKfinal: begin
            in_AKfinal = 1;
            if(last_FAK_cycle) begin
                nextstate = IDLE;
            end
        end
    endcase
end


// Control logic
always@(*) begin
    global_init = 0;
    next_in_ready = 0;

    set_valid_out = 0;

    state_enable = 0;
    state_init = 0;
    state_en_MC = 0;
    state_en_loop = 0;
    state_en_loop_r0 = 0;
    state_en_SB_inverse = 0;
    state_bypass_MC_inverse = 0;
    state_en_toSB_inverse = 0;

    KH_init = 0;
    KH_loop = 0;
    KH_add_from_sb = 0;
    KH_enable_buffer_from_sbox = 0;
    KH_rst_buffer_from_sbox = 0;
    KH_last_key_valid = 0;

    sbox_valid_in = 0;
    sbox_inverse = 0;

    feed_sb_key = 0;
    
    cnt_fsm_inc = 0;

    enable_key_add = 0;
    enable_key_add_inverse = 0;

    pre_need_rnd = 1;

    rcon_inverse = exec_status_inverse;
    
    // Pre_need_rnd always on except when IDLE and no start
    if ((state==IDLE) & ~start_exec)begin
        pre_need_rnd = 0;
    end
    // Core ready when IDLE & output processed or not valid
    if (state==IDLE) begin
        // CHECK HERE -> idle total alrgith? 
        next_in_ready = reg_in_ready ?  ~valid_in : (~valid_out_reg | cipher_fetch);
        global_init = in_fetch;
    end
    // The output is valid after the last cycle of the final key addition
    if ((state==WAIT_AKfinal) & last_FAK_cycle) begin
        set_valid_out = 1;
    end
    // Mux tap the input (instead of looping) if 
    // a new execution starts or 
    // if no execution starts and the output is fetched (to empty the core).
    if(in_fetch | in_reset_KH) begin
        state_init = 1;
        KH_init = 1;
    end
    // FSM increments counter during the processing of rounds
    if(in_first_SBK | in_round | in_last_round) begin
        cnt_fsm_inc = 1;
    end else if(in_AKfinal) begin
        cnt_fsm_inc = 1;
    end
    // The sbox is valid 
    // during the first cycke of an execution (feeding the last column of the input key) or
    // during the first `SERIAL_LAT cycles of a round (feeding the result of AK) or
    // during the last cycle of a round (feeding the last column of the round key)
    if(in_first_SBK | ((in_round | in_last_round) & in_AKSB) | (in_round & last_round_cycle)) begin
        sbox_valid_in = 1;
    end
    // The Key addition is enabled
    // during the key addition operation of a round
    // during the final key addition
    if(((in_round | in_last_round) & in_AKSB) | in_AKfinal) begin
        if(exec_status_inverse) begin
            enable_key_add_inverse = 1;
        end else begin
            enable_key_add = 1;
        end
    end
    // The inputs of the Sboxes are key materials
    // during the first cycle or 
    // during the last cycle of a round
    if (in_first_SBK | last_round_cycle) begin
        feed_sb_key = 1;
    end
    // State holder enable if :
    // round or last key addition in progress or
    // if a new execution starts or 
    // if no execution starts and the output is fetched (to empty the core).
    // The datapath is disabled when the value coming from the Sbox is key material 
    if(in_fetch | ((in_round | in_last_round) & ~key_from_sbox ) | in_AKfinal | in_reset_KH) begin
        state_enable = 1;
    end
    // State mux control
    // During an encryption, the forward Mixcolumns logic is enabled during the rounds except the last one.
    // During a decryption, the forward Mixcolumns logic is never enabled;
    if (exec_status_inverse) begin
        state_en_MC = 0;
    end else begin
        if(in_round) begin
            state_en_MC = 1;
        end
    end
    // The state holder loops over itself 
    //  - During the AKSB operation of rounds (to keep byte 1,2,6,3,7,11 valid) or 
    //  - During the final key addition
    // Exception for the last three rows during the decryption, where the 
    // data always loop over the pipeline since the mux selecting the data between the forward MC and the Sbox output is not used.
    if(exec_status_inverse) begin
        if(((in_round | in_last_round) & in_AKSB) | in_AKfinal) begin
            state_en_loop_r0 = 1;
        end
        state_en_loop = 1;
    end else begin
        if(((in_round | in_last_round) & in_AKSB) | in_AKfinal) begin
            state_en_loop = 1;
            state_en_loop_r0 = 1;
        end
    end
    // The key holder is enabled
    // when a new execution starts or
    // during rounds when AKSB of key expension are in progress or
    // during the final key addition or
    // if no execution starts and the output is fetched (to empty the core).
    KH_enable = (
        in_first_SBK |
        in_fetch |
        ((in_round | in_last_round) & ((in_AKSB_except_last | last_round_cycle) | in_KEXP)) |
        in_AKfinal |
        in_reset_KH 
    );
    // The key key holder is looping over itself
    // during AKSB operation of rounds or 
    // during the final key addition.
    //
    // The result of the sbox is added to the key column during
    // the first cycle of the key expension.
    if((in_round | in_last_round) & (in_AKSB_except_last | last_round_cycle)) begin
        KH_loop = 1;
    end else if((in_round | in_last_round) & in_KEXP_FIRST) begin
        KH_add_from_sb = 1;
    end else if(in_AKfinal) begin
        KH_loop = 1;
    end else if(in_first_SBK) begin
        KH_loop = 1;
    end
    // RCON inverse
    if(in_fetch) begin
        rcon_inverse = inverse; 
    end 
    // In decryption, the feeding of the datapath from the S-boxes in enabled
    // during the round computation (as well as the last one) when the key addition is not performed
    state_en_SB_inverse = exec_status_inverse & (in_round | in_last_round) & (~in_AKSB);
    // In decryption, the inverse mixcolumn logic block must be bypassed during
    // the key addition of the first round
    state_bypass_MC_inverse = exec_status_inverse & (in_round & in_AKSB & is_first_round); 
    // In decryption, the column going to the Sbox from the state comes from the first column
    state_en_toSB_inverse = exec_status_inverse;
    // In decryption, the buffer storing the key material of the last column is reset during 
    //  - at the very first cycle of an execution
    //  - at the last cycle of a round (including the last one) 
    KH_rst_buffer_from_sbox = pre_last_round_cycle | in_first_SBK;
    // In decryption, the buffer storing the key material is enabled during the round (including the last one) when the sbox output is key material and when the buffer is reset 
    KH_enable_buffer_from_sbox = (exec_status_inverse & ((in_round | in_last_round) & in_KS_KEYUPDATE)) | in_first_SBK;
    // In decryption, the sbox is executed in reverse mode
    sbox_inverse = exec_status_inverse & (~feed_sb_key);
    // The last key value is valid at the very first cycle of the last key addition operation
    KH_last_key_valid = in_AKfinal & first_round_cycle; 
     
end

assign busy = (state != IDLE);

endmodule
