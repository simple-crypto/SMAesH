# CHANGELOG

## v2.0.0

- Extend SMAesH IP to support AES128/192/256 in encryption and decyption.
- Add internal long-term key storage unit. 
- Add Sbox generation using COMPRESS.
- Move to cocotb based functional verification procedure.
- Move from fullverif to MATCHI based formal verification procedure. 
- Add CI featuring:
    - Generation of sbox
    - functionnal tests (using cocotb + verilator)
    - formal tests (using cocotb + verilator + MATCHI)
    - Doc generation. 
- Refactorisation of the repo (removing useless files)

## v1.1.0 (2024-09-02)

- Integrate a new 4 cycles Sbox based on the Canright architecture.

## v1.0.1 (2023-06-15)

- Doc fix: latency discussion in Section 5.4.

## v1.0.0 (2023-05-01)

- Initial release: AES128 encrypt.
