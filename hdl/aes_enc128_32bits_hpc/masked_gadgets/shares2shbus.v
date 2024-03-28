// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// This changes the representation of sharings, from a packed representation
// where all the shares of a bit are adjacent, to a "bus" representation where all
// the bits for one share are adjacent.
// The packed representation is more convenient for computing on sharins as it
// is easy to extract subsets of bits, while the "bus" representation is often
// more convenient for interfacing and debugging.
module shares2shbus
#
(
    parameter d = 2,
    parameter count = 8
)
(
    shares,
    shbus
);

// IOs
input [d*count-1:0] shares;
output [d*count-1:0] shbus;

genvar i,j;
generate
for(i=0;i<count;i=i+1) begin: bit_wiring
    for(j=0;j<d;j=j+1) begin: share_wiring
        assign shbus[d*i + j] = shares[count*j + i];
    end
end
endgenerate


endmodule
