module smaesh_arbitrer
(
    input clk,
    input rst,
    //// Seed related
    input in_seed_valid,
    output in_seed_ready,
    //// Key related
    input in_key_valid,
    output in_key_ready,
    //// Data related
    input in_data_valid,
    output in_data_ready,
    //// Internals 
    // internal ready
    input KSU_in_ready,
    input aes_in_ready,
    // busy
    input prng_busy,
    input KSU_busy,
    input aes_busy,
    // PRNG seeded
    input prng_seeded,
    // start procedure control signal
    output prng_start_reseed,
    output KSU_start_fetch_procedure,
    input KSU_last_key_computation_required,
    output aes_valid_in
);

//// Lock wire
// Seed has precendence over the rest, so only lock when other are busy
wire lock_seed_stream = (KSU_busy | aes_busy);
// Key has precedence over data, but not over seed
wire lock_key_stream = (prng_busy | aes_busy | in_seed_valid | ~prng_seeded);
// Data has no precedence over the rest
wire lock_data_stream = (KSU_busy | prng_busy | in_seed_valid | in_key_valid | ~prng_seeded);

//// PRNG drivers 
// Starting a reseed has precedence over all the rest
assign prng_start_reseed = in_seed_valid & ~lock_seed_stream;

// Compute in_seed_ready.
// We used input seed when there is as posedge on busy_prng.
reg prev_prng_busy;
always @(posedge clk)
if (rst) begin
    prev_prng_busy <= 0; 
end else begin
    prev_prng_busy <= prng_busy; 
end
assign in_seed_ready = ~prev_prng_busy & prng_busy & ~lock_seed_stream;

//// Key holder driver
assign KSU_start_fetch_procedure = in_key_valid & ~lock_key_stream;
assign in_key_ready = KSU_in_ready & ~lock_key_stream;

//// AES core driver
// aes_valid_in asserted in two cases:
// (1) under key configuration, if last round key must be computed and prng is seeded
// (2) otherwise, if the key stream is not locked and valid is asserted
assign aes_valid_in = KSU_busy ? (prng_seeded & KSU_last_key_computation_required) : in_data_valid & ~lock_data_stream;
assign in_data_ready = aes_in_ready & ~lock_data_stream;





endmodule
