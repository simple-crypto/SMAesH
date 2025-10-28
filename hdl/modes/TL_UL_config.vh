// Add reference to the TL spec
// Constant width for the channel A signals
localparam TL_UL_W_A_OPCODE=3;
localparam TL_UL_W_A_PARAM=3;
localparam TL_UL_W_A_CORRUPT=1;

// Constant width for the channel D signals
localparam TL_UL_W_D_OPCODE=3;
localparam TL_UL_W_D_PARAM=2;
localparam TL_UL_W_D_DENIED=1;
localparam TL_UL_W_D_CORRUPT=1;

// Constant for OPCODE
localparam TL_Get = 4;
localparam TL_AccessAckData = 1;
localparam TL_PutFullData = 0;
localparam TL_PutPartialData = 1;
localparam TL_AccessAck = 0;
