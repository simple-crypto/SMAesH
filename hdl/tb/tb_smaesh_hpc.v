// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.
`timescale 1ns/1ps

`ifndef NSHARES
`define NSHARES 2
`endif
`ifndef KEY_SIZE
`define KEY_SIZE 128
`endif
module tb_smaesh_hpc
#
(
    parameter T = 2,
    parameter d = `NSHARES,
    parameter RND_RANGE_LAT_RESEED=600,
    parameter RND_RANGE_LAT_IN=100,
    parameter CONTINUOUS = 0
)
();

localparam KWORDS = `KEY_SIZE/32;

localparam wait_delay = 100*T;
localparam init_delay=Td/2.0;

`include "utils.vh"

localparam Td = T/2.0;

reg clk;
reg syn_rst;

reg dut_in_data_valid;
wire dut_in_data_ready;
wire [128*d-1:0] dut_in_shares_data;
reg [127:0] dut_in_shares_data_share0;
assign dut_in_shares_data[127:0] = dut_in_shares_data_share0;
assign dut_in_shares_data[128 +: (d-1)*128] = 0;

reg dut_in_key_valid;
wire dut_in_key_ready;
reg [31:0] dut_in_key_data;
reg [1:0] dut_in_key_size_cfg;
reg dut_in_key_mode_inverse;

reg dut_seed_valid;
wire dut_seed_ready;
reg [127:0] dut_seed;

wire [128*d-1:0] dut_out_shares_data;
wire dut_out_valid;
wire dut_out_ready;

// Generate the clock
always #Td clk=~clk;

// Dut
smaesh_hpc
`ifdef behavioral
#(
    .d(d)
)
`endif
dut(
    .clk(clk),
    .rst(syn_rst),
    .in_data_valid(dut_in_data_valid),
    .in_data_ready(dut_in_data_ready),
    .in_shares_data(dut_in_shares_data),
    .in_key_valid(dut_in_key_valid),
    .in_key_ready(dut_in_key_ready),
    .in_key_data(dut_in_key_data),
    .in_key_size_cfg(dut_in_key_size_cfg),
    .in_key_mode_inverse(dut_in_key_mode_inverse),
    .in_seed_valid(dut_seed_valid),
    .in_seed_ready(dut_seed_ready),
    .in_seed(dut_seed[79:0]),
    .out_shares_data(dut_out_shares_data),
    .out_valid(dut_out_valid),
    .out_ready(dut_out_ready)
);

//// Value read from files
reg [127:0] read_plaintext;
reg [`KEY_SIZE-1:0] read_umsk_key;
reg [127:0] read_umsk_ciphertext;
reg read_last_in;
reg read_last_out;

wire [127:0] ref_umsk_plaintext;
endian_reverse #(
    .BSIZE(128),
    .WIDTH(8)
) er_plaintext (
    .bus_in(read_plaintext),
    .bus_out(ref_umsk_plaintext)
);

wire [`KEY_SIZE-1:0] ref_umsk_key;
endian_reverse #(
    .BSIZE(`KEY_SIZE),
    .WIDTH(8)
) er_key (
    .bus_in(read_umsk_key),
    .bus_out(ref_umsk_key)
);

wire [127:0] ref_umsk_ciphertext;
endian_reverse #(
    .BSIZE(128),
    .WIDTH(8)
) er_ciphertext (
    .bus_in(read_umsk_ciphertext),
    .bus_out(ref_umsk_ciphertext)
);

// Recombine unit 
wire [127:0] rec_dut_ciphertext;
recombine_shares_unit #(.d(d),.count(128))
ru(
    .shares_in(dut_out_shares_data),
    .out(rec_dut_ciphertext)
);


////////////////////////// For debug usage
wire [`KEY_SIZE*d-1:0] prob_key_KSU = dut.KSU_sh_key_out[0 +: `KEY_SIZE*d] ;
wire [`KEY_SIZE*d-1:0] shares_prob_key_KSU;
shbus2shares #(.d(d), .count(`KEY_SIZE))
sh2sha_key(
    .shbus(prob_key_KSU),
    .shares(shares_prob_key_KSU)
);

wire [`KEY_SIZE-1:0] rec_key_KSU;
recombine_shares_unit #(.d(d),.count(`KEY_SIZE))
ruKSU(
    .shares_in(shares_prob_key_KSU),
    .out(rec_key_KSU)
);


wire [32*d-1:0] prob_sh4b_from_key = dut.aes_core.state_sh_4bytes_from_key;
wire [32*d-1:0] prob_shares_sh4b_from_key;
wire [31:0] rec_prob_sh4b_from_key;

shbus2shares #(.d(d), .count(32))
sh2sha_k2AK(
    .shbus(prob_sh4b_from_key),
    .shares(prob_shares_sh4b_from_key)
);

recombine_shares_unit #(.d(d),.count(32))
ruk2AK(
    .shares_in(prob_shares_sh4b_from_key),
    .out(rec_prob_sh4b_from_key)
);

genvar gi;
generate
for(gi=0;gi<32;gi=gi+1) begin: rec_key_dpkey
    wire [8*d-1:0] prob_sh_kbyte = dut.aes_core.key_holder.sh_m_key[gi];
    wire [8*d-1:0] prob_shares_kbyte;
    wire [7:0] rec_prob_kbyte;
    shbus2shares #(.d(d), .count(8))
    sh2sha_kbyte_dpkey(
        .shbus(prob_sh_kbyte),
        .shares(prob_shares_kbyte)
    );
    recombine_shares_unit #(.d(d),.count(8))
    ru_kbyte_dpkey(
        .shares_in(prob_shares_kbyte),
        .out(rec_prob_kbyte)
    );
end
endgenerate

generate
for(gi=0;gi<16;gi=gi+1) begin: rec_state_dpstate
    wire [8*d-1:0] prob_sh_sbyte = dut.aes_core.core_data.sh_reg_out[gi];
    wire [8*d-1:0] prob_shares_byte;
    wire [7:0] rec_prob_byte;
    shbus2shares #(.d(d), .count(8))
    sh2sha_kbyte_dpkey(
        .shbus(prob_sh_sbyte),
        .shares(prob_shares_byte)
    );
    recombine_shares_unit #(.d(d),.count(8))
    ru_kbyte_dpkey(
        .shares_in(prob_shares_byte),
        .out(rec_prob_byte)
    );
end
endgenerate

wire [32*d-1:0] prob_sh_from_sbox = dut.aes_core.sh_4bytes_from_SB;
wire [32*d-1:0] prob_shares_from_sbox;
wire [31:0] rec_prob_from_sbox;
shbus2shares #(.d(d), .count(32))
sh2sha_fSBox(
    .shbus(prob_sh_from_sbox),
    .shares(prob_shares_from_sbox)
);
recombine_shares_unit #(.d(d),.count(32))
ru_kbyte_fSbox(
    .shares_in(prob_shares_from_sbox),
    .out(rec_prob_from_sbox)
);


wire [32*d-1:0] prob_sh_to_sbox = dut.aes_core.state_sh_4bytes_to_SB;
wire [32*d-1:0] prob_shares_to_sbox;
wire [31:0] rec_prob_to_sbox;
shbus2shares #(.d(d), .count(32))
sh2sha_tSBox(
    .shbus(prob_sh_to_sbox),
    .shares(prob_shares_to_sbox)
);
recombine_shares_unit #(.d(d),.count(32))
ru_kbyte_tSbox(
    .shares_in(prob_shares_to_sbox),
    .out(rec_prob_to_sbox)
);



/////////////////////////////////////////:




////// RUN 
integer RUN_AM;

integer id_tv_in;
integer id_tv_out;

// Reseeding mechanism
reg reg_init_reseed_done;
reg set_init_reseed_done;
always@(posedge clk) 
if(syn_rst) begin
    reg_init_reseed_done <= 0;
end else begin
    reg_init_reseed_done <= reg_init_reseed_done | set_init_reseed_done;
end

integer rnd_time_before_reseeding;
integer i_seed;
integer seed_random = 0;
initial begin
    set_init_reseed_done = 0;
    #(wait_delay);
    #(init_delay);

    #T;
    #T;
    #T;
    // Initial reseed
    for(i_seed=0;i_seed<4;i_seed=i_seed+1) begin
        dut_seed[32*i_seed +: 32] = $random(seed_random);
    end
    $display("Reseed of PRNG requested...");
    dut_seed_valid=1;
    // wiat for ready seed assertion
    while(dut_seed_ready!==1) begin
        #T;
    end
    #T; 
    dut_seed_valid=0;
    $display("New seed of PRNG fetched!");
    set_init_reseed_done = 1;
    #T;

    // Generate random delay before next reseed 
    if (CONTINUOUS!==1) begin
        while(1) begin
            // wait the next execution start
            while(dut_in_data_valid!==1 | dut_in_data_ready!==1) begin
                #T;
            end
            // Generate random latecny beofre next reseeding
            rnd_time_before_reseeding = {$random} % RND_RANGE_LAT_RESEED;
            // Set new values
            for(i_seed=0;i_seed<4;i_seed=i_seed+1) begin
                dut_seed[32*i_seed +: 32] = $random(seed_random);
            end
            for(i_seed=0;i_seed<rnd_time_before_reseeding;i_seed=i_seed+1) begin
                #T;
            end
            // Start a new reseed procedure
            $display("Reseed of PRNG requested...");
            dut_seed_valid = 0; // FIX here
            // Wait for new seed eating
            while(dut_seed_ready!==1) begin
                #T;
            end
            #T;
            dut_seed_valid=0;
            $display("New seed of PRNG fetched!");
        end
    end
end

`include "smaesh_config.vh"

// Input feeding
integer i;
integer cnt_in;
integer id_in;
integer rnd_time_before_valid_in;
integer k, dr;
integer cnt_lock;
initial begin
    `ifdef DUMPFILE
        // Open dumping file
        $dumpfile(`DUMPFILE);
        $dumpvars(0,tb_smaesh_hpc);
    `endif
    
    $display("Files configuration used:");
    $display(`TV_IN);
    $display(`TV_OUT);
    $display("Amount of shares: %d",`NSHARES);

    // Open TV file
    id_tv_in = $fopen(`TV_IN, "r");

    // Read file header
    read_file_header(id_tv_in,RUN_AM);
    `ifdef RUN_AM
        RUN_AM = `RUN_AM;
    `endif

    if(`KEY_SIZE==128) begin
        dut_in_key_size_cfg = KSIZE_128;
    end else if(`KEY_SIZE==192) begin
        dut_in_key_size_cfg = KSIZE_192;
    end else if(`KEY_SIZE==256) begin
        dut_in_key_size_cfg = KSIZE_256;
    end else begin
        $display("Key size not supported. EXIT");
        $finish();
    end


    clk = 1;
    syn_rst = 0;
    
    dut_in_data_valid = 0;
    dut_seed_valid = 0;

    dut_in_key_valid = 0;
    dut_in_key_mode_inverse = 0;

    // Init delay 
    #(wait_delay); 
    #(init_delay);

    // Reset sequence
    syn_rst = 1;
    #T;
    syn_rst = 0;
    #T;
    $display("Reset done!");

    #(init_delay);

    // Wait that init reseed is done
    while(reg_init_reseed_done!==1) begin
        #T;
    end
    $display("KAT executions start (once reseed procedure is finished)...");
    // Input feeding
    for(cnt_in=0;cnt_in<RUN_AM;cnt_in=cnt_in+1) begin
        // Read the case header
        read_case_header(id_tv_in,id_in);
        // Read the case inputs
        read_next_in_words(id_tv_in,read_plaintext,read_umsk_key,read_last_in);
        // Set the key
        #Td;

        // ######### FIRST, run the encryption #########
        for(k=0;k<KWORDS;k=k+1) begin
            dut_in_key_data = ref_umsk_key[k*32 +: 32];
            dut_in_key_mode_inverse = 0;
            dut_in_key_valid = 1;
            while(dut_in_key_ready!==1) begin
                #T;
            end
            #T;
        end
        for(dr=0;dr<d-1;dr=dr+1) begin
            for(k=0;k<KWORDS;k=k+1) begin
                dut_in_key_data = 32'b0;
                dut_in_key_valid = 1;
                while(dut_in_key_ready!==1) begin
                    #T;
                end
                #T;
            end
        end
        dut_in_key_valid = 0;

        // Generate random timing before asserting valid
        if (CONTINUOUS===1) begin
            rnd_time_before_valid_in = 0;
        end else begin
            rnd_time_before_valid_in = {$random} % RND_RANGE_LAT_IN;
        end
        for(i=0;i<rnd_time_before_valid_in;i=i+1) begin
            #T;
        end
        // Assert valid in with the plaintext
        dut_in_shares_data_share0 = ref_umsk_plaintext;
        dut_in_data_valid = 1;
        while(dut_in_data_ready!==1) begin
            #T;
        end
        #T;
        dut_in_data_valid = 0;


        // #### DELAY before starting the decryption ####
        if (CONTINUOUS===1) begin
            rnd_time_before_valid_in = 0;
        end else begin
            rnd_time_before_valid_in = {$random} % RND_RANGE_LAT_IN;
        end
        for(i=0;i<rnd_time_before_valid_in;i=i+1) begin
            #T;
        end

        // ######### SECOND, run the decryption #########
        for(k=0;k<KWORDS;k=k+1) begin
            dut_in_key_data = ref_umsk_key[k*32 +: 32];
            dut_in_key_mode_inverse = 1;
            dut_in_key_valid = 1;
            while(dut_in_key_ready!==1) begin
                #T;
            end
            #T;
        end
        for(dr=0;dr<d-1;dr=dr+1) begin
            for(k=0;k<KWORDS;k=k+1) begin
                dut_in_key_data = 32'b0;
                dut_in_key_valid = 1;
                while(dut_in_key_ready!==1) begin
                    #T;
                end
                #T;
            end
        end
        dut_in_key_valid = 0;

        // Generate random timing before asserting valid
        if (CONTINUOUS===1) begin
            rnd_time_before_valid_in = 0;
        end else begin
            rnd_time_before_valid_in = {$random} % RND_RANGE_LAT_IN;
        end
        for(i=0;i<rnd_time_before_valid_in;i=i+1) begin
            #T;
        end
        // Assert valid in with the ciphertext
        dut_in_shares_data_share0 = ref_umsk_ciphertext;
        dut_in_data_valid = 1;
        while(dut_in_data_ready!==1) begin
            #T;
        end
        #T;
        dut_in_data_valid = 0;
        // Wait for unlock
        while(cnt_in !== cnt_lock) begin
            #T;
        end
    end

end

integer cycle_count;
always @(posedge clk) begin
    if (syn_rst) cycle_count = 0;
    else cycle_count = cycle_count +1;
end

// Generation of random ready_out (simulation of back pressure)
integer seed_rdy_out = 1;
reg [31:0] random_bit;
always@(posedge clk)
begin
    if(CONTINUOUS===1) begin
        random_bit <= 1;
    end else begin
        random_bit <= $random(seed_rdy_out);
    end
end
`ifdef FULLVERIF
assign dut_out_ready = 1;
`else
assign dut_out_ready = random_bit[0];
`endif



// Output feeding
integer trash;
integer cnt_out;
integer id_out;
initial begin
    cnt_lock = -1;
    // Open file
    id_tv_out = $fopen(`TV_OUT,"r");

    // Read file header
    read_file_header(id_tv_out,trash);

    //dut_out_ready = 1;

    // 
    #(wait_delay);
    #(init_delay);

    // Output reading and verification
    for(cnt_out=0;cnt_out<RUN_AM;cnt_out=cnt_out+1) begin
        // read case header 
        read_case_header(id_tv_out,id_out);
        // read case output
        read_next_out_words(id_tv_out,read_umsk_ciphertext,read_last_out);
        // (1. ENCRYPTION) Wait for next fetch at the output 
        while((dut_out_valid!==1) | (dut_out_ready!==1)) begin
            #T;
        end
        // Verification
        if(ref_umsk_ciphertext!==rec_dut_ciphertext[127:0]) begin
            $display("FAILURE for case %d",id_out);
            $display("Ciphertext computed:\n%x\n",rec_dut_ciphertext[127:0]);
            $display("Expected ciphertext:\n%x\n",read_umsk_ciphertext);
            $finish;
        end
        $display(" [ENCRYPT] %d/%d done!",cnt_out+1,RUN_AM);
        #T;

        // (1. DECRYPTION) Wait for next fetch at the output 
        while((dut_out_valid!==1) | (dut_out_ready!==1)) begin
            #T;
        end
        // Verification
        if(ref_umsk_plaintext!==rec_dut_ciphertext[127:0]) begin
            $display("FAILURE for case %d",id_out);
            $display("plaintext computed:\n%x\n",rec_dut_ciphertext[127:0]);
            $display("Expected plaintext:\n%x\n",ref_umsk_plaintext);
            $finish;
        end
        $display(" [DECRYPT] %d/%d done!",cnt_out+1,RUN_AM);
        #T;
        cnt_lock = cnt_out;
    end
    $display("KAT executions done!");
    #T;
    $display("SUCCESS");
    $finish;
end



endmodule
