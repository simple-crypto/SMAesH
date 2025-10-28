module TL_smaesh_enc_dec
#(
    //// TILELINK-UL parameters
    // Width of the data bus, in bytes (MUST be a power of two)
    parameter TL_W=32,
    // Number of bits needed to disambiguate per-link master sources. 
    parameter TL_O=4,
    // Number of bits needed to disambiguate per-link slave sink. 
    parameter TL_I=4,
    // Width of each adress, in bits
    parameter TL_A=32
)
(
    // General IOs
    clk,
    rst,
    //// TILELINK-UL interface
    // Channel A 
    a_opcode,
    a_param,  // reserved, must be 0
    a_size,
    a_source,
    a_address,
    a_mask,
    a_corrupt,
    a_data,
    a_valid,
    a_ready,
    // Channel D 
    d_opcode,
    d_param, // reserved, MUST be 0
    d_size,
    d_source,
    d_sink, // ignored, can be X
    d_denied,
    d_corrupt,
    d_data,
    d_valid,
    d_ready
    // Remaining TBD
);

// Include TL-UL set of fixed param 
`include "TL_UL_config.vh"

// TL_Z derivation as a function of TL_W. 
// For TL-UL support only, as the width cannot be higher than the maximum
// amount of bytes that can be sent in a beat. 
parameter TL_Z = $clog2(TL_W);
localparam TL_8W = 8*TL_W;

// General IOs
input clk;
input rst;
// TL-UL channel A
input [TL_UL_W_A_OPCODE-1:0] a_opcode;
input [TL_UL_W_A_PARAM-1:0] a_param;
input [TL_Z-1:0] a_size;
input [TL_O-1:0] a_source;
input [TL_A-1:0] a_address;
input [TL_W-1:0] a_mask;
input [TL_UL_W_A_CORRUPT-1:0] a_corrupt;
input [TL_8W-1:0] a_data;
input a_valid;
output a_ready;
// TL-UL channel D
output [TL_UL_W_D_OPCODE-1:0] d_opcode;
output [TL_UL_W_D_PARAM-1:0] d_param;
output [TL_Z-1:0] d_size;
output [TL_O-1:0] d_source;
output [TL_I-1:0] d_sink;
output [TL_UL_W_D_DENIED-1:0] d_denied;
output [TL_UL_W_D_CORRUPT-1:0] d_corrupt;
output [TL_8W-1:0] d_data;
input d_ready;
output d_valid;



endmodule
