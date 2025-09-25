`timescale 1ns/1ps
module tb_buffer_fifo();

localparam T=2.0;
localparam Td = T / 2.0;

localparam LOG2_NBYTES=5;

reg clk;
reg rst;

reg [31:0] in_data;
reg [2:0] push_nbytes;
reg push;
wire [LOG2_NBYTES:0] left_nbytes,left_nbytes2; 

wire [255:0] out_data,out_data2;
reg [LOG2_NBYTES:0] pop_nbytes;
reg pop;
wire [LOG2_NBYTES:0] stored_nbytes,stored_nbytes2; 

// clk 
always@(*) #Td clk<=~clk;

// dut 
buffer_fifo #(.LOG2_NBYTES(LOG2_NBYTES))
dut(
    .clk(clk),
    .rst(rst),
    .in_data(in_data),
    .push_nbytes(push_nbytes),
    .push(push),
    .left_nbytes(left_nbytes),
    .out_data(out_data),
    .pop_nbytes(pop_nbytes),
    .pop(pop),
    .stored_nbytes(stored_nbytes)
);

buffer_fifo_v2 #(.LOG2_NBYTES(LOG2_NBYTES))
dut2(
    .clk(clk),
    .rst(rst),
    .in_data(in_data),
    .push_1(push_nbytes==1),
    .push_2(push_nbytes==2),
    .push_4(push_nbytes==4),
    .push(push),
    .left_nbytes(left_nbytes2),
    .out_data(out_data2),
    .pop_nbytes(pop_nbytes),
    .pop(pop),
    .stored_nbytes(stored_nbytes2)
);

initial begin 
    $dumpfile("log.vcd");
    $dumpvars(0, tb_buffer_fifo);

    clk = 1;
    rst = 0;
    push = 0;
    pop = 0;
    push_nbytes = 0;
    pop_nbytes = 0;

    #(0.1*T);

    rst = 1;
    #T;
    rst = 0;
    
    // 
    in_data = 32'h03020100;
    push_nbytes = 4;
    push = 1;
    #T;
    in_data = 32'h00000004;
    push_nbytes = 1;
    push = 1;
    #T;
    in_data = 32'h00000605;
    push_nbytes = 2;
    push = 1;
    #T;
    in_data = 32'h00000007;
    push_nbytes = 1;
    push = 1;
    #T;
    in_data = 32'h0B0A0908;
    push_nbytes = 4;
    push = 1;
    #T;
    in_data = 32'h0F0E0D0C;
    push_nbytes = 4;
    push = 1;
    #T;
    push = 0;

    // First check 
    if (
        (out_data[127:0] !== 128'h0F0E0D0C0B0A09080706050403020100) |
        (left_nbytes !== 16) | 
        (stored_nbytes !== 16)
    ) begin
        $display("ERROR OCCURED: ... with first feeding");
        $finish();
    end
    if (out_data[127:0]!==out_data2[127:0]) begin
        $display("MISMATCH OCCURED: ... with first feeding");
    end

    // Try to read 
    pop_nbytes = 2;
    pop = 1;
    #T;
    if (
        (out_data[111:0] !== 112'h0F0E0D0C0B0A0908070605040302) |
        (left_nbytes !== 18) | 
        (stored_nbytes !== 14)
    ) begin
        $display("ERROR OCCURED: ... poping 2");
        $finish();
    end
    if (out_data[111:0]!==out_data2[111:0]) begin
        $display("MISMATCH OCCURED: ... poping 2");
    end
    pop_nbytes = 4;
    pop = 1;
    #T;
    if (
        (out_data[8*10-1:0] !== 80'h0F0E0D0C0B0A09080706) | 
        (left_nbytes !== 22) | 
        (stored_nbytes !== 10)
    ) begin

        $display("ERROR OCCURED: ... poping 4");
        $finish();
    end
    if (out_data[8*10-1:0]!==out_data2[8*10-1:0]) begin
        $display("MISMATCH OCCURED: ... poping 4");
    end
    pop_nbytes = 1;
    pop = 1;
    #T;
    if (
        (out_data[8*9-1:0] !== 72'h0F0E0D0C0B0A090807) |
        (left_nbytes !== 23) |
        (stored_nbytes !== 9)
    ) begin
        $display("ERROR OCCURED: ... poping 1");
        $finish();
    end
    if (out_data[8*9-1:0]!==out_data2[8*9-1:0]) begin
        $display("MISMATCH OCCURED: ... poping 1");
    end
    pop = 0;

    #(5*T);
    $finish();
end

endmodule
