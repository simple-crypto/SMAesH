// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// This changes the representation of sharings, from a "bus" representation to
// a packed representation, seed shares2bus.v for details on these
// representations.
module shbus2shares
#
(
    parameter d = 2,
    parameter count = 8
)
(
    shbus,
    shares
);

// IOs
input [d*count-1:0] shbus;
output [d*count-1:0] shares;

genvar i,j;
generate
for(i=0;i<count;i=i+1) begin: bit_wiring
    for(j=0;j<d;j=j+1) begin: share_wiring
        assign shares[count*j + i] = shbus[d*i + j];
    end
end
endgenerate


endmodule
