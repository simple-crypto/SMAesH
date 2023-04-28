// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

module endian_reverse
#
(
    // Bus size
    parameter BSIZE=32,
    // Size of the word on which to apply the 
    // transformation
    parameter WIDTH=8
    // 
)
(
    input [BSIZE-1:0] bus_in,
    output [BSIZE-1:0] bus_out
);

localparam DIV=BSIZE/WIDTH;
genvar w;

generate
for(w=0;w<DIV;w=w+1) begin: word_move
    assign bus_out[w*WIDTH +: WIDTH] = bus_in[(DIV-1-w)*WIDTH +: WIDTH];
end
endgenerate

endmodule
