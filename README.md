# SIMPLE-Crypto's Masked AES in Hardware (SMAesH)

An optimized masked hardware implementation of AES-128 Encryption using HPC2.

This repository contains the masked AES hardware implementation published by [SIMPLE-Crypto](https://simple-crypto.org).

See PDF [technical documentation](https://simple-crypto.org/outputs) and [preliminary evaluation report](https://simple-crypto.org/outputs).

## Contents

- `hdl`: Verilog implementation and its testbench.
- `beh_simu`: Scripts for behavioral simulation using iverilog.
- `docs`: Sources of the [technical documentation](https://simple-crypto.org/outputs).
- `formal_verif`: Scripts for formal verification with [fullverif](https://github.com/cassiersg/fullverif)


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
