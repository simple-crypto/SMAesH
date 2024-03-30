// Randomness bus sizes.
// This file has been automatically generated.
`include "MSKand_hpc1.vh"
`include "MSKand_hpc2.vh"
`include "MSKand_hpc3.vh"
localparam rnd_bus0 = 1*(4*d*(d-1))+2*(2*ref_n_rnd);
localparam rnd_bus1 = 1*(2*d*(d-1))+2*(4*ref_n_rnd);
localparam rnd_bus2 = 2*(2*d*(d-1)/2);
localparam rnd_bus3 = 2*(4*d*(d-1)/2);
