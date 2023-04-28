// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.
module recombine_shares_unit
#
(
    parameter d = 2,
    parameter count = 8
)
(
    input [d*count-1:0] shares_in,
    output [count-1:0] out
);

wire [d*count-1:0] sh_in;
shares2shbus #(.d(d),.count(count))
s2b(
    .shares(shares_in),
    .shbus(sh_in)
);

recombine_unit #(.d(d),.count(count))
ru(
    .sh_in(sh_in),
    .out(out)
);


endmodule
