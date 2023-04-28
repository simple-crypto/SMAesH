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
module tb_aes_enc128_32bits_hpc2
#
(
    parameter T = 2,
    parameter d = 2,
    parameter RND_RANGE_LAT_RESEED=600,
    parameter RND_RANGE_LAT_IN=100,
    parameter CONTINUOUS = 0
)
();

localparam wait_delay = 100*T;
localparam init_delay=Td/2.0;

`include "MSKand_HPC2.vh"
`include "utils.vh"

localparam Td = T/2.0;

reg clk;
reg syn_rst;

reg dut_in_valid;
wire dut_in_ready;

wire [128*d-1:0] dut_shares_plaintext;
wire [128*d-1:0] dut_shares_key;

reg dut_seed_valid;
wire dut_seed_ready;
reg [127:0] dut_seed;

wire [128*d-1:0] dut_shares_ciphertext;
wire dut_out_valid;
wire dut_out_ready;

// Generate the clock
always #Td clk=~clk;


// Dut
aes_enc128_32bits_hpc2 #(
    .d(d)
)
dut(
    .clk(clk),
    .rst(syn_rst),
    .in_valid(dut_in_valid),
    .in_ready(dut_in_ready),
    .in_shares_plaintext(dut_shares_plaintext),
    .in_shares_key(dut_shares_key),
    .in_seed_valid(dut_seed_valid),
    .in_seed_ready(dut_seed_ready),
    .in_seed(dut_seed[79:0]),
    .out_shares_ciphertext(dut_shares_ciphertext),
    .out_valid(dut_out_valid),
    .out_ready(dut_out_ready)
);

//// Value read from files
reg [127:0] read_plaintext;
reg [127:0] read_umsk_key;
reg [127:0] read_umsk_ciphertext;
reg read_last_in;
reg read_last_out;

assign dut_shares_plaintext[128 +: (d-1)*128] = 0;
endian_reverse #(
    .BSIZE(128),
    .WIDTH(8)
) er_plaintext (
    .bus_in(read_plaintext),
    .bus_out(dut_shares_plaintext[127:0])
);

assign dut_shares_key[128 +: (d-1)*128] = 0;
endian_reverse #(
    .BSIZE(128),
    .WIDTH(8)
) er_key (
    .bus_in(read_umsk_key),
    .bus_out(dut_shares_key[127:0])
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
    .shares_in(dut_shares_ciphertext),
    .out(rec_dut_ciphertext)
);

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
            while(dut_in_valid!==1 | dut_in_ready!==1) begin
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
            dut_seed_valid = 1;
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


// Input feeding
integer i;
integer cnt_in;
integer id_in;
integer rnd_time_before_valid_in;
initial begin
    `ifdef DUMPFILE
        // Open dumping file
        $dumpfile(`DUMPFILE);
        $dumpvars(0,tb_aes_enc128_32bits_hpc2);
    `endif
    
    $display("Files configuration used:");
    $display(`TV_IN);
    $display(`TV_OUT);

    // Open TV file
    id_tv_in = $fopen(`TV_IN, "r");

    // Read file header
    read_file_header(id_tv_in,RUN_AM);
    `ifdef RUN_AM
        RUN_AM = `RUN_AM;
    `endif

    clk = 1;
    syn_rst = 0;
    
    dut_in_valid = 0;
    dut_seed_valid = 0;

    // Init delay 
    #(wait_delay); 

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
        // Generate random timing before asserting valid
        if (CONTINUOUS===1) begin
            rnd_time_before_valid_in = 0;
        end else begin
            rnd_time_before_valid_in = {$random} % RND_RANGE_LAT_IN;
        end
        for(i=0;i<rnd_time_before_valid_in;i=i+1) begin
            #T;
        end
        // Assert valid in
        dut_in_valid = 1;
        while(dut_in_ready!==1) begin
            #T;
        end
        #T;
        dut_in_valid = 0;
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
        // Wait for next fetch at the output 
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
        $display("%d/%d done!",cnt_out+1,RUN_AM);
        #T;
    end
    $display("KAT executions done!");
    #T;
    $display("SUCCESS");
    $finish;
end



endmodule
