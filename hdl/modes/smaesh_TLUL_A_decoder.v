module smaesh_TLUL_A_decoder
#(
    //// TILELINK-UL parameters
    // Width of the data bus, in bytes (MUST be a power of two)
    parameter TL_W=4,
    // Number of bits needed to disambiguate per-link master sources. 
    parameter TL_O=4,
    // Number of bits needed to disambiguate per-link slave sink. 
    parameter TL_I=4,
    // Width of each adress, in bits
    parameter TL_A=8 
)
(
    //// TILELINK-UL interface
    // Channel A 
    a_opcode,
    a_address,
    a_mask,
    a_data,
    // SMAesh internal decoding
    a_data_shifted,
    a_write,
    a_read,
    a_req_valid,
    a_req_W_softreset,
    a_req_R_busy,
    a_req_R_seeded,
    a_req_R_keyed,
    a_req_W_mode,
    a_req_R_mode,
    a_req_R_infree,
    a_req_R_outawait,
    a_req_W_decerror,
    a_req_R_decerror,
    a_req_W_statechange,
    a_req_W_seed,
    a_req_W_key,
    a_req_W_iv,
    a_req_W_indata,
    a_req_R_outdata
);

// Include TL-UL set of fixed param 
`include "TL_UL_config.vh"

// TL_Z derivation as a function of TL_W. 
// For TL-UL support only, as the width cannot be higher than the maximum
// amount of bytes that can be sent in a beat. 
parameter TL_Z = $clog2(TL_W);
localparam TL_8W = 8*TL_W;
parameter LOG2_TL_W = $clog2(TL_W);

// General IOs
input clk;
input nrst;
// TL-UL channel A
input [TL_UL_W_A_OPCODE-1:0] a_opcode;
input [TL_A-1:0] a_address;
input [TL_W-1:0] a_mask;
input [TL_8W-1:0] a_data;

output [TL_8W-1:0] a_data_shifted;
output a_write;
output a_read;
output a_req_valid;
output a_req_W_softreset;
output a_req_R_busy;
output a_req_R_seeded;
output a_req_R_keyed; 
output a_req_W_mode;
output a_req_R_mode;
output a_req_R_infree;
output a_req_R_outawait;
output a_req_W_decerror;
output a_req_R_decerror;
output a_req_W_statechange;
output a_req_W_seed;
output a_req_W_key;
output a_req_W_iv;
output a_req_W_indata;
output a_req_R_outdata;

////// Slave interface 
// Recover the shift to apply to the input data 
wire [LOG2_TL_W-1:0] data_offset;
bus_offset_decoder #(.TL_W(TL_W))
data_offset_decoder(
    .mask(a_mask),
    .offset(data_offset)
);
assign a_data_shifted = (a_data >> (8*data_offset));

//// Decode the request 
// Write is requested when either PutFullData or PutPartialData are
// requested. Write is used to keep track of the answer to issue to the
// request, and must therefore also handle non-supproted request (e.g.,
// PutPartialData.
wire is_ppd = a_opcode == TL_PutPartialData;
wire is_pfd = a_opcode == TL_PutFullData;
assign a_write = is_pfd | is_ppd;
// Read is requested when Get is requested. Read is used to keep track of the answer to issue to the
// request, and must therefore also handle non-supported request.
wire is_get = (a_opcode == TL_Get);
assign a_read = is_get;

// Here we parse which one of the supported request (R/W) is issued to the core. 
assign a_req_W_softreset = is_pfd & (a_address == TLA_ADDR_SoftReset);
assign a_req_R_busy = is_get & (a_address == TLA_ADDR_Busy);
assign a_req_R_seeded = is_get & (a_address == TLA_ADDR_Seeded);
assign a_req_R_keyed = is_get & (a_address == TLA_ADDR_Keyed);
assign a_req_W_mode = is_pfd & (a_address == TLA_ADDR_Mode);
assign a_req_R_mode = is_get & (a_address == TLA_ADDR_Mode);
assign a_req_R_infree = is_get & (a_address == TLA_ADDR_InFree);
assign a_req_R_outawait = is_get & (a_address == TLA_ADDR_OutAwait);
assign a_req_W_decerror = is_pfd & (a_address == TLA_ADDR_DecError);
assign a_req_R_decerror = is_get & (a_address == TLA_ADDR_DecError);
assign a_req_W_statechange = is_pfd & (a_address == TLA_ADDR_StateChange);
assign a_req_W_seed = is_pfd & (a_address == TLA_ADDR_Seed);
assign a_req_W_key = is_pfd & (a_address == TLA_ADDR_Key);
assign a_req_W_iv = is_pfd & (a_address == TLA_ADDR_IV);
assign a_req_W_indata = is_pfd & (a_address == TLA_ADDR_InData);
assign a_req_R_outdata = is_get & (a_address == TLA_ADDR_OutData);

assign a_req_valid = (
    a_req_W_softreset |
    a_req_R_busy |
    a_req_R_seeded |
    a_req_R_keyed |
    a_req_W_mode |
    a_req_R_mode |
    a_req_R_infree |
    a_req_R_outawait |
    a_req_W_decerror |
    a_req_R_decerror |
    a_req_W_statechange |
    a_req_W_seed |
    a_req_W_key |
    a_req_W_iv |
    a_req_W_indata |
    a_req_R_outdata
);

endmodule

