// Assymetric FIFO Buffer 
//
// v2: aims to be similar as buffer_fifo, but with optimized input push layer. 
// 
// CAUTION: no internal verification are made relative to the amount of bytes
// stored/that can still be stored. Proper usage MUST be handled at a higher
// level. 
module buffer_fifo_v2
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
    push_1,
    push_2,
    push_4,
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
input push_1;
input push_2;
input push_4;
input push;
output [LOG2_NBYTES:0] left_nbytes;

output [255:0] out_data;
input [LOG2_NBYTES:0] pop_nbytes;
input pop;
output [LOG2_NBYTES:0] stored_nbytes;

// Generate the internals DFF with shifting mux tree
reg [7:0] mem [0:MEM_NBYTES-1];
wire [7:0] to_mem_sh1 [0:MEM_NBYTES-1];
wire [7:0] to_mem_sh2 [0:MEM_NBYTES-1];
wire [7:0] to_mem_sh4 [0:MEM_NBYTES-1];

genvar i;
generate
    for(i=0;i<MEM_NBYTES;i=i+1) begin: g_mem_reg
        wire [7:0] to_mem = push_1 ? to_mem_sh1[i] : (push_2 ? to_mem_sh2[i] : to_mem_sh4[i]);
        always@(posedge clk)
            if(push) begin
                mem[i] <= to_mem;
            end
    end
endgenerate

// Assign proper signal for the 4 first byte register that deal with 
// input. 
assign to_mem_sh1[0] = in_data[0 +: 8];
assign to_mem_sh2[0] = in_data[8 +: 8];
assign to_mem_sh4[0] = in_data[24 +: 8];

assign to_mem_sh1[1] = mem[0];
assign to_mem_sh2[1] = in_data[0 +: 8];
assign to_mem_sh4[1] = in_data[16 +: 8];

assign to_mem_sh1[2] = mem[1];
assign to_mem_sh2[2] = mem[0];
assign to_mem_sh4[2] = in_data[8 +: 8];

assign to_mem_sh1[3] = mem[2];
assign to_mem_sh2[3] = mem[1];
assign to_mem_sh4[3] = in_data[0 +: 8];

// Assign remaining signals 
generate
    for(i=0;i<MEM_NBYTES-4;i=i+1) begin: g_to_mem_hcol
        if (i>3) begin
            assign to_mem_sh1[i] = mem[i-1];
            assign to_mem_sh2[i] = mem[i-2];
            assign to_mem_sh4[i] = mem[i-4];
        end
    end
endgenerate

// Generate the reading pointer logic
reg [LOG2_NBYTES-1:0] ptr_read; 
wire [2:0] push_nbytes = push_1 ? 1 : (push_2 ? 2 : 4);
always@(posedge clk)
    if(rst) begin
        ptr_read <= 0;
    end else begin 
        ptr_read <= ptr_read + (push ? push_nbytes : 0) - (pop ? pop_nbytes : 0); 
    end

// Generate the reading adresses 
wire [LOG2_NBYTES-1:0] addr_read [31:0];

// Generate the read address 
generate
    for(i=0;i<MEM_NBYTES;i=i+1) begin: g_add_read
        assign addr_read[i] = (MEM_NBYTES + (ptr_read - i - 1)) % (MEM_NBYTES);
    end
endgenerate 

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
