# `aes_enc128_32bits_hpc2` HDL tree

This is is a masked implementation of AES-128 encryption using the HPC2 masking
scheme and a 32-bit architecture based on <https://eprint.iacr.org/2022/252>.

For functional and architectural details, see the technical documentation in
this repository.

## Source tree

```
├── aes_enc128_32bits_hpc2 # All sources required for synthesis.
│   ├── aes_enc128_32bits_hpc2.v # Top-level source.
│   ├── masked_gadgets # Basic masked gadgets and composing gates.
│   │   ├── [...]
│   ├── [...] # Other sources.
│   ├── rnd_gen # PRNG for masking randomness.
│   │   ├── [...]
│   └── sbox # Masked S-box implementation and generating script.
│   │   ├── [...]
├── gather_sources.sh # To copy all the sources in a single directory.
├── hdl_cleanup.sh # To remove the fv_* and verilator_me attributes from the sources.
├── README.md
└── tb # Testbench
    ├── tb_aes_enc128_32bits_hpc2.v
    ├── [...]
```

Notes:
- `masked_gadgets/bin_*` are simple logic gates aimed at preventing damaging synthesis optimizations.
- `masked_gadgets/MSK_*` are masked logic gate implementations.

