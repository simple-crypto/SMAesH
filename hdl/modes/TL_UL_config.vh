//// TL-UL generic configuration
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
localparam TL_PutFullData = 0;
localparam TL_PutPartialData = 1;
localparam TL_AccessAckData = 1;
localparam TL_AccessAck = 0;

//// SMAESH DMA configuration 
localparam TLA_ADDR_SoftReset = 8'h00;
localparam TLA_ADDR_Busy = 8'h01;
localparam TLA_ADDR_Seeded = 8'h02;
localparam TLA_ADDR_Keyed = 8'h03;
localparam TLA_ADDR_Mode = 8'h04;
localparam TLA_ADDR_InFree = 8'h05;
localparam TLA_ADDR_OutAwait = 8'h06;
localparam TLA_ADDR_DecError = 8'h07;
localparam TLA_ADDR_StateChange = 8'h08;
localparam TLA_ADDR_Seed = 8'h09;
localparam TLA_ADDR_Key= 8'h0a;
localparam TLA_ADDR_IV= 8'h0b;
localparam TLA_ADDR_InData= 8'h0c;
localparam TLA_ADDR_OutData= 8'h0d;
