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

`ifndef INVERSE
`define INVERSE 0
`endif
`ifndef NSHARES
`define NSHARES 2
`endif
`ifndef KEY_SIZE
`define KEY_SIZE 128
`endif
module tb_MSKaes_32bits_core
#
(
    parameter T = 2,
    parameter d = `NSHARES,
    parameter RND_RANGE_LAT_RESEED=600,
    parameter RND_RANGE_LAT_IN=100,
    parameter CONTINUOUS = 0,
    parameter KSIZE = `KEY_SIZE
);

localparam wait_delay = 100*T;
localparam init_delay=Td/2.0;

`include "utils.vh"
`include "canright_aes_sbox_dual.vh"

localparam Td = T/2.0;

reg clk;
reg syn_rst;

reg dut_in_valid;
wire dut_in_ready;

wire [128*d-1:0] dut_shares_plaintext, dut_shares_ciphertext, dut_shares_out;
wire [256*d-1:0] dut_shares_key;

reg dut_seed_valid;
wire dut_seed_ready;
reg [127:0] dut_seed;

wire dut_out_valid;
wire dut_out_ready;


wire dut_busy;
reg dut_inverse;
reg dut_key_schedule_only;
wire dut_last_key_valid;
reg dut_mode256;
reg dut_mode192;

wire dut_in_ready_rnd;

// Encoding of the shares
wire [128*d-1:0] dut_sh_plaintext, dut_sh_ciphertext, dut_sh_in, dut_sh_out;
wire [256*d-1:0] dut_sh_key; 
shares2shbus #(.d(d),.count(128))
switch_encoding_pt(
    .shares(dut_shares_plaintext),
    .shbus(dut_sh_plaintext)
);

shares2shbus #(.d(d),.count(128))
switch_encoding_ct(
    .shares(dut_shares_ciphertext),
    .shbus(dut_sh_ciphertext)
);

shares2shbus #(.d(d),.count(256))
switch_encoding_key(
    .shares(dut_shares_key),
    .shbus(dut_sh_key)
);

shbus2shares #(.d(d),.count(128))
switch_encoding_out(
    .shbus(dut_sh_out),
    .shares(dut_shares_out)
);

assign dut_sh_in = `INVERSE ? dut_sh_ciphertext : dut_sh_plaintext;

// Generate the clock
always #Td clk=~clk;


// Dut
MSKaes_32bits_core
`ifdef behavioral
#(
    .d(d)
)
`endif
dut(
    .clk(clk),
    .rst(syn_rst),
    .busy(dut_busy),
    .valid_in(dut_in_valid),
    .in_ready(dut_in_ready),
    .out_valid(dut_out_valid),
    .out_ready(dut_out_ready),
    .inverse(dut_inverse),
    .key_schedule_only(dut_key_schedule_only),
    .last_key_pre_valid(dut_last_key_valid),
    .mode_256(dut_mode256),
    .mode_192(dut_mode192),
    .sh_data_in(dut_sh_in),
    .sh_key(dut_sh_key),
    .sh_data_out(dut_sh_out),
    .rnd_bus0w({(4*rnd_bus0){1'b0}}),
    .rnd_bus1w({(4*rnd_bus1){1'b0}}),
    .rnd_bus2w({(4*rnd_bus2){1'b0}}),
    .rnd_bus3w({(4*rnd_bus3){1'b0}}),
    .in_ready_rnd(dut_in_ready_rnd)
);


//// Value read from files
reg [127:0] read_plaintext;
reg [KSIZE-1:0] read_umsk_key;
reg [127:0] read_umsk_ciphertext;
reg read_last_in;
reg read_last_out;

assign dut_shares_plaintext[128 +: (d-1)*128] = 0;
assign dut_shares_ciphertext[128 +: (d-1)*128] = 0;
endian_reverse #(
        .BSIZE(128),
        .WIDTH(8)
    ) er_plaintext (
        .bus_in(read_plaintext),
        .bus_out(dut_shares_plaintext[127:0])
    );
endian_reverse #(
        .BSIZE(128),
        .WIDTH(8)
    ) er_ciphertext (
        .bus_in(read_umsk_ciphertext),
        .bus_out(dut_shares_ciphertext[127:0])
    );

assign dut_shares_key[256 +: (d-1)*256] = 0;
generate
if(KSIZE==128) begin: ksize
    assign dut_shares_key[128 +: 128] = 128'b0;
end
endgenerate
    endian_reverse #(
        .BSIZE(KSIZE),
        .WIDTH(8)
    ) er_key (
        .bus_in(read_umsk_key),
        .bus_out(dut_shares_key[KSIZE-1:0])
    );

wire [127:0] ref_read_umsk_out = `INVERSE ? read_umsk_ciphertext : read_plaintext;
wire [127:0] ref_umsk_out;
endian_reverse #(
    .BSIZE(128),
    .WIDTH(8)
) er_umsk_out (
    .bus_in(ref_read_umsk_out),
    .bus_out(ref_umsk_out)
);

// Recombine unit 
wire [127:0] rec_dut_out;
recombine_shares_unit #(.d(d),.count(128))
ru(
    .shares_in(dut_shares_out),
    .out(rec_dut_out)
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

reg [15:0] cnt_cycles;
always@(posedge clk)
if(syn_rst) begin
    cnt_cycles <= 0;
end else begin
    cnt_cycles <= cnt_cycles + 1;
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
        $dumpvars(0,tb_MSKaes_32bits_core);
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

    clk = 1;
    syn_rst = 0;
    
    dut_in_valid = 0;
    dut_seed_valid = 0;

    // Set status
    dut_inverse = `INVERSE;
    dut_key_schedule_only = 0;

    if (KSIZE==256) begin
        dut_mode256 = 1;
    end else begin
        dut_mode256 = 0;
    end 
    if (KSIZE==192) begin
        dut_mode192 = 1;
    end else begin
        dut_mode192 = 0;
    end


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
        if(ref_umsk_out!==rec_dut_out[127:0]) begin
            $display("FAILURE for case %d",id_out);
            $display("Ciphertext computed:\n%x\n",rec_dut_out[127:0]);
            $display("Expected ciphertext:\n%x\n",ref_umsk_out);
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
