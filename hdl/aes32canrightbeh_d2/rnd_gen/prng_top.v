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

// This is a wrapper for the trivium PRNG implemented in trivium_prng.v.
// This wrapper adds a reseeding feature and SVRS output interface.
`ifndef DEFAULTRND
`define DEFAULTRND 1
`endif
module prng_top
#
(
    // Number of bits of randomness generated at each clock cycle
    parameter RND=`DEFAULTRND,
    // Number of shifts executed during the reseed procedure.
    // Default is the standard for Trivium.
    parameter NINIT=4*288,
    // Maximum of unrolling (in bits) for a single PRNG instance
    // Default gives low logic depth for Trivium.
    parameter MAX_UNROLL=1024
)
(
    // Active high, reset for the control (does no reseed !).
    input rst,
    // Clock
    input clk,
    // Acive high. Start the reseeding procedure.
    input start_reseed,
    // Active high, reseed in progress,
    output busy,
    // The seed, loaded as initial state.
    input [79:0] seed,
    // SVRS pseudo-random output stream.
    // Output will be always valid, except:
    // - when a reseeding is in progress
    // - when the PRNG has not been reseeded yet after a reset.
    input out_ready,
    output out_valid,
    output [RND-1:0] out_rnd
);

// Generation parameters 
localparam N_PRNGS = $rtoi($ceil($itor(RND) / MAX_UNROLL));
localparam UNROLL = $rtoi($ceil($itor(RND) / N_PRNGS));

// PRNG global control
reg core_feed_seed;
reg core_update;
wire [UNROLL*N_PRNGS-1:0] random_bits;

// Number of cycles required to init the PRNGs with new randomness
// We ensure to do at least NINIT shifts.
localparam LAT_INIT = $rtoi($ceil($itor(NINIT) / UNROLL));

// FSM state
localparam
    INIT=0,
    RUNNING=1,
    RESEED=2;
reg [1:0] state, nextstate;
always @(posedge clk) begin
    if (rst) begin
        state <= INIT;
    end else begin
        state <= nextstate;
    end
end

// Counter for reseed iteration
parameter ADDR = $clog2(LAT_INIT+1);
reg [ADDR-1:0] cnt_fsm;
reg rst_cnt;
always @(posedge clk) begin
    if (rst | rst_cnt) begin
        cnt_fsm <= 0;
    end else begin
        cnt_fsm <= cnt_fsm + 1;
    end
end

// FSM logic
always @(*) begin
    nextstate = state;
    rst_cnt = 1;
    core_update = 0;
    core_feed_seed = 0;

    case (state)
        INIT: begin
            if (start_reseed) begin
                nextstate = RESEED;
                core_feed_seed = 1;
            end
        end
        RESEED: begin
            // We keep the reseed counter at zero, except when doing the reseed.
            rst_cnt = 0;
            core_update = 1;
            // Stay in RESEED for LAT_INIT+1 cycles.
            // The +1 stands for the cycle for the output to go through reg_rnd_out.
            if (cnt_fsm == LAT_INIT) begin
                nextstate = RUNNING;
            end
        end
        RUNNING: begin
            // We always keep the output valid when in running state, and tell
            // the PRNG to update when the output is used.
            if (out_ready) begin
                core_update = 1;
            end
            if (start_reseed) begin
                nextstate = RESEED;
                core_feed_seed = 1;
            end
        end
    endcase
end

// Generate output 
assign out_valid = (state==RUNNING);
assign busy = (state==RESEED);

//// Generate the PRNG instances
genvar i;
generate
for(i=0;i<N_PRNGS;i=i+1) begin: prng_inst
    wire [79:0] iv_trivium = i;
    trivium_prng #(.RND(UNROLL))
    trivium_core(
        .clk(clk),
        .key(seed),
        .iv(iv_trivium),
        .feed_seed(core_feed_seed),
        .update(core_update),
        .rnd_out(random_bits[i*UNROLL +: UNROLL])
    );
end
endgenerate

// Generate the output DFF (to avoid glitches propagation)
reg [RND-1:0] reg_rnd_out;
always@(posedge clk)
if(core_update) begin
    reg_rnd_out <= random_bits[RND-1:0];
end

assign out_rnd = reg_rnd_out;

endmodule
