# Formal verification with fullverif

## Dependencies

The verification requires the following tools (indicated versions are known to work):

- yosys (0.22)
- iverilog (11.0)
- fullverif (git commit 932fa952e44c64232fa660383804f25cfe4ca6b3)
- Unix utils (bash, find,...).

## Execution

Run the following script
```
./run_fullverif.sh
```

`yosys`, `iverilog`, `vvp` and `fullverif` must be in path, or their path can
be indicated as an environment variable with their capitalized name (e.g.,
`FULLVERIF=/path/to/fullverif/binary`).

