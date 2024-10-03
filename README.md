# SIMPLE-Crypto's Masked AES in Hardware (SMAesH)

An optimized masked hardware implementation of AES using HPC. 

This repository contains the masked AES hardware implementation published by [SIMPLE-Crypto](https://simple-crypto.org).

Main features:

- Supports the three AES variants (i.e., using 128-, 192- or 256-bit key), chosen at run-time.
- Both the encryption and decryption are supported, chosen at run-time.
- The security of the masked architecture is formally proven, and analyzed using the [MATCHI](https://github.com/cassiersg/matchi) tool.
- Implements an optimised architecture of the Sbox, automatically generated using the [COMPRESS](https://github.com/cassiersg/compress) tool. 
- The core performs a single AES execution at a time. 
- The required randomness is generated on-the-fly internally to the core, using an embedded PRNG. 
- The core stores the long-term key shares, and refreshes the latter at each execution. 


See PDF [technical documentation](https://simple-crypto.org/outputs) and [preliminary evaluation report](https://simple-crypto.org/outputs) for additional details.

## Contents

- `hdl`: Verilog implementation, apart from the sbox module.
- `sbox-compress`: Scripts used to generate the sbox module using [COMPRESS](https://github.com/cassiersg/compress).  
- `func_tests`: Scripts for functionnal verification, using the [cocotb](https://www.cocotb.org/) framework and the [Verilator](https://www.veripool.org/verilator/) simulator.
- `formal_verif`: Scripts for formal security analysis using [MATCHI](https://github.com/cassiersg/matchi).
- `synth`: Script to perform the synsthesis using [Yosys](https://yosyshq.net/yosys/) and the [nangate45 PDK](https://github.com/The-OpenROAD-Project-Attic/PEX/tree/master/kits/nangate45). 
- `docs`: Sources of the [technical documentation](https://simple-crypto.org/outputs).

## Usage

Clone this repository with its submodules:
```
git clone https://github.com/simple-crypto/SMAesH.git --recursive
```

A top-level Makefile is provided in order to easily perform useful operations. 
The main useful variables to configure the workflows are: 

- `NSHARES`: The amount of shares the consider (default: 2). 
- `DIR_MATCHI_ROOT`: The absolute path to the MATCHI tool repository on your computer (only required in order to run the formal verification checks). 
- `YOSYS`: Path to the yosys's binary installed on your machine (by default, we consider that you have `yosys` in your PATH).  
- `WORK`: Working directory of the workflow. 

The Makefile enables the following commands: 

- `make sbox`: Generate the sbox module using COMPRESS.  
- `make hdl`: 

## Contact

You are welcome to open issues or discussions on the [github repository](https://github.com/simple-crypto/SMAesH/issues/new).
You may also contact us privately at <info@simple-crypto.org>.

## License

See [LICENSE.txt](LICENSE.txt) and [COPYRIGHT.txt](COPYRIGHT.txt).
See also the [SIMPLE-Crypto licensing policy](https://www.simple-crypto.dev/organization).

## Acknowledgements

This work has been funded in part by the Belgian Fund for Scientific Research
(F.R.S.-FNRS) through individual researchers' grants, by the European Union
(EU) through the ERC project 724725 (acronym SWORD) and the ERC project
101096871 (acronym BRIDGE), and by the Walloon Region through the Win2Wal
project PIRATE (convention number 1910082).
