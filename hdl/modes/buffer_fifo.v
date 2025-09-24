// Assymetric FIFO Buffer (v1) 
// 
// CAUTION: no internal verification are made relative to the amount of bytes
// stored/that can still be stored. Proper usage MUST be handled at a higher
// level. 
module buffer_fifo
#(
    // Log2 of the total amount of bytes that can be stored 
    // MUST BE AT LEAST EQUAL TO 5
    parameter LOG2_NBYTES = 5
)
(
    clk,
    rst,
    // 
    in_data,
    push_nbytes,
    push,
    // Amount of bytes that can be stored
    left_nbytes, 
    // 
    out_data,
    pop_nbytes,
    pop,
    // Amount of bytes that are stored
    stored_nbytes
);

// Architectural paramaters 
parameter MEM_NBYTES = 1 << LOG2_NBYTES;

// IOs 
input clk;
input rst;
input [31:0] in_data;
input [2:0] push_nbytes; 
input push;
output [LOG2_NBYTES:0] left_nbytes;

output [255:0] out_data;
input [LOG2_NBYTES:0] pop_nbytes;
input pop;
output [LOG2_NBYTES:0] stored_nbytes;

// Internals pointers 
reg [LOG2_NBYTES-1:0] ptr_write, ptr_read; 
always@(posedge clk)
    if(rst) begin
        ptr_write <= 0;
    end else if(push) begin 
        ptr_write <= ptr_write + push_nbytes; 
    end

always@(posedge clk)
    if(rst) begin
        ptr_read <= 0;
    end else if(pop) begin 
        ptr_read <= ptr_read + pop_nbytes; 
    end

// Generate the writing addresses
wire [LOG2_NBYTES-1:0] addr_write [3:0];
wire [LOG2_NBYTES-1:0] addr_read [31:0];

// Generate the write address 
genvar i;
generate
    for(i=0;i<4;i=i+1) begin: g_add_write
        assign addr_write[i] = (ptr_write + i);
    end
endgenerate 

// Generate the read address 
generate
    for(i=0;i<MEM_NBYTES;i=i+1) begin: g_add_read
        assign addr_read[i] = (ptr_read + i);
    end
endgenerate 

// Generate the enable signal
wire [3:0] en;
generate
    for(i=0;i<4;i=i+1) begin: g_en 
        assign en[i] = push & (i <= push_nbytes - 1);
    end
endgenerate

// Generate the memory in itself 
reg [7:0] mem [MEM_NBYTES-1:0];
always@(posedge clk) begin 
    if(en[0]) begin
        mem[addr_write[0]] <= in_data[0 +: 8];
    end
    if(en[1]) begin
        mem[addr_write[1]] <= in_data[8 +: 8];
    end
    if(en[2]) begin
        mem[addr_write[2]] <= in_data[16 +: 8];
    end
    if(en[3]) begin
        mem[addr_write[3]] <= in_data[24 +: 8];
    end
end

// Assign the output 
generate 
    for(i=0;i<32;i=i+1) begin: g_byte_out
        assign out_data[8*i +: 8] = mem[addr_read[i]];
    end
endgenerate

// Counter to keep track of the amount of stored bytes 
reg [LOG2_NBYTES:0] cnt_bytes;
always@(posedge clk)
    if(rst) begin
        cnt_bytes <= 0;
    end else begin 
        cnt_bytes <= cnt_bytes + (push ? push_nbytes : 0) - (pop ? pop_nbytes : 0);
    end

assign stored_nbytes = cnt_bytes;
assign left_nbytes = MEM_NBYTES - stored_nbytes;

endmodule
