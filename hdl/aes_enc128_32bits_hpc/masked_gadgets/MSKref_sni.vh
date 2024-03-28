// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Randomness requirement for SNI refresh gadget.
function integer _ref_nrnd(input integer d);
begin
if (d==1) _ref_nrnd = 1; // Hack to avoid 0-width signals.
else if (d==2 || d==3) _ref_nrnd = d-1;
else if (d==4 || d == 5) _ref_nrnd = d;
// Make it fail for d >= 6: little use, and makes latency description more complex, we therefore do not implement them here.
//else if (d==6) _ref_nrnd = d+1;
//else if (d==7) _ref_nrnd = d+2;
//else if (d==8 || d==9) _ref_nrnd = d+3;
//else if (d == 10) _ref_nrnd = d+5;
//else if (d == 11) _ref_nrnd = d+6;
//else if (d == 12) _ref_nrnd = d+8;
//else if (d >= 13 && d <= 16) _ref_nrnd = 2*d;
end
endfunction

localparam ref_n_rnd = _ref_nrnd(d);

function integer _ref_rndlat(input integer d);
begin
if (d==1 || d == 2) _ref_rndlat = 0;
else if (d==3 || d==4 || d == 5) _ref_rndlat = 1;
else _ref_rndlat = 2;
end
endfunction

localparam ref_rndlat = _ref_rndlat(d);
