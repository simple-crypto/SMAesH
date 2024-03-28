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

// This is a simple implementation of the trivium cipher, unrolled to shift by RND per cycle.
// No nonce/key handling, it should be initialized either:
// - with full 288 bit entropy 
// - with enough entropy, then shifted enough without using the output to
// properly initialize the state (we recommend 4*288 shifts, as in the original trivium).
module trivium_prng
#
(
    parameter RND = 1
)
(
    clk,
    // The initial state (seed) is composed of the key and the IV.
    key,
    iv,
    // active high, triggers the load of seed to the state
    // the output is not freshly random at the cycle the state is feeded, nor
    // at the next cycle where update is high, it becomes fresh randomness at
    // the next second cycle where update is high. Bypass update signal if asserted.
    feed_seed,
    // active high,  triggers a shift of the state and update of the output
    update,
    // output randomness, WARNING: glitchy state
    rnd_out
);

`define TRIVINUM_BITS 288

// IO ports
input clk;
input [79:0] key;
input [79:0] iv;
input feed_seed;
input update;
output [RND-1:0] rnd_out;

reg [`TRIVINUM_BITS-1:0] state;
wire [`TRIVINUM_BITS-1:0] new_state;

wire [`TRIVINUM_BITS-1:0] seed;
assign seed[79:0] = key;
assign seed[92:80] = 0;
assign seed[172:93] = iv;
assign seed[284:173] = 0;
assign seed[287:285] = 3'b111;

always @(posedge clk) begin
    if (feed_seed) begin
        state <= seed;    
    end else if (update) begin
        state <= new_state;
    end
end

// Main Trivium shift/update logic logic
genvar i;
generate
for (i=0; i<RND; i=i+1) begin: update_step
    // use 1-based indexing to match spec at
    // https://www.ecrypt.eu.org/stream/p3ciphers/trivium/trivium_p3.pdf
    wire [`TRIVINUM_BITS:1] s, snew;

    if (i == 0) begin
        assign s = state;
    end else begin
        assign s = update_step[i-1].snew;
    end

    wire [3:1] t;
    assign t[1] = s[66] ^ s[93];
    assign t[2] = s[162] ^ s[177];
    assign t[3] = s[243] ^ s[288];
    assign rnd_out[i] = t[1] ^ t[2] ^ t[3];

    assign snew[1] = t[3] ^ s[286] & s[287] ^ s[69];
    assign snew[93:2] = s[92:1];
    assign snew[94] = t[1] ^ s[91] & s[92] ^ s[171];
    assign snew[177:95] = s[176:94];
    assign snew[178] = t[2] ^ s[175] & s[176] ^ s[264];
    assign snew[288:179] = s[287:178];
end
endgenerate
assign new_state = update_step[RND-1].snew;

endmodule