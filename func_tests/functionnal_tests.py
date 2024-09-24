import cocotb
import logging
import utils_KAT
import utils_smaesh
from cocotb.triggers import Timer, RisingEdge, FallingEdge

# Logger for global debug
myl = logging.getLogger(__name__)
myl.setLevel(logging.INFO)

# Amount of shares (TODO: fetch from ENV)
NSHARES=2

# Generate the clock
async def generate_clock(dut,ncycles=1000):
    """Generate clock pulses."""
    if ncycles is not None:
        for cycle in range(ncycles):
            dut.clk.value = 0
            await Timer(1, units="ns")
            dut.clk.value = 1
            await Timer(1, units="ns")
    else:
        while True:
            dut.clk.value = 0
            await Timer(1, units="ns")
            dut.clk.value = 1
            await Timer(1, units="ns")

# Set non X value to control signal
async def set_valid_external_control(dut):
    # Set all the extenal control signal
    dut.in_data_valid.value = 0
    dut.in_key_valid.value = 0
    dut.in_key_size_cfg.value = 0
    dut.in_key_mode_inverse.value = 0
    dut.in_seed_valid.value = 0
    dut.out_ready.value = 0
    dut.rst.valid = 0

# Reset procedure
async def reset_dut(dut):
    await set_valid_external_control(dut)
    # Drive the reset
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0

# Wait "ncycles" cycles, i.e., "ncycles" posedge (Consider then that the
# latency starts after a posedge detection)
async def wait_ncycles(dut, ncycles):
    for c in range(ncycles):
        await RisingEdge(dut.clk)

# Wait for the signal assertion (typically in SVRS transaction)
# IN_SYNC: RisingEdge
# OUT_SYNC: FallingEdge
async def wait_signal_asserted(dut, sig):
    # Wait for falling edge
    await FallingEdge(dut.clk)
    # Wait for the ready signal to be set
    while (sig.value != 1):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

# Transaction on the reseed SVRS interface.
# No latency overhead for serialization (several transactions following)
# SYNC: RisingEdge
async def svrs_seed_transaction(dut, seed: int):
    # Set the value to the bus
    dut.in_seed.value = seed
    dut.in_seed_valid.value = 1
    # Wait for falling edge
    await wait_signal_asserted(dut, dut.in_seed_ready)
    # End transaction, by waiting till next Rising edge and clearing 
    # input signals
    await RisingEdge(dut.clk)
    dut.in_seed.value = 0
    dut.in_seed_valid.value = 0

# Transaction on the key interface
# No latency overhead for serialization (several transactions following)
# SYNC: RisingEdge
async def svrs_key_transaction(dut, data: int, cfg_size, cfg_inverse):
    # Set the value to the bus
    dut.in_key_data.value = data
    dut.in_key_size_cfg.value = cfg_size
    dut.in_key_mode_inverse.value = cfg_inverse
    dut.in_key_valid.value = 1
    # Wait for falling edge
    await wait_signal_asserted(dut, dut.in_key_ready)
    # End transaction, by waiting till next Rising edge and clearing 
    # input signals
    await RisingEdge(dut.clk)
    dut.in_key_data.value = 0
    dut.in_key_size_cfg.value = 0
    dut.in_key_mode_inverse.value = 0
    dut.in_key_valid.value = 0

# Transaction on the data interface
# No latency overhead for serialization (several transactions following)
# SYNC: RisingEdge
async def svrs_input_data_transaction(dut, data: int):
    # Set the value to the bus
    dut.in_shares_data.value = data
    dut.in_data_valid.value = 1
    await wait_signal_asserted(dut, dut.in_data_ready)
    # End transaction, by waiting till next Rising edge and clearing 
    # input signals
    await RisingEdge(dut.clk)
    dut.in_data_valid.value = 0

# Procedure to setup a new key from un-masked key
async def svrs_key_procedure(dut, bytes_umsk_key, inverse_mode, nshares):
    # Amount of 32-bit words to send
    am32 = len(bytes_umsk_key) // 4
    # First transaction, required to set the configuration
    await svrs_key_transaction(
            dut, 
            int.from_bytes(bytes_umsk_key[0:4],byteorder="little"), 
            utils_smaesh.CFG_KEY_SIZE[len(bytes_umsk_key)*8],
            inverse_mode
            )
    # Remaining of transactions for first share
    for t in range(am32-1):
        await svrs_key_transaction(
                dut, 
                int.from_bytes(bytes_umsk_key[(t+1)*4:(t+2)*4],byteorder="little"), 
                0,
                0)
    # Relaining of transactions for remaining of shares with 0 values
    for d in range(nshares-1):
        for t in range(am32):
            await svrs_key_transaction(dut,0,0,0)

# Task to recover the value at the output of the core
async def svrs_output_data_transaction(dut):
    # Set the ready signal 
    dut.out_ready.value = 1
    # Wait for falling
    await wait_signal_asserted(dut,dut.out_valid)
    out_shares_data_int = int(dut.out_shares_data)
    # End transaction by waiting till the next Rising edged and clearing
    # input signal
    await RisingEdge(dut.clk)
    dut.out_ready.value = 0
    return out_shares_data_int

# Template for simple use case of the core, performing only encryption 
# for a list of cases. 
# At most 'timeout_cycles' are runned during the encryption
async def AES_BC_ENC_TEMPLATE(dut, list_cases, timeout_cycles, nshares):
    """Try accessing the design."""
    # Start the clock
    await cocotb.start(generate_clock(dut,ncycles=timeout_cycles))  # run the clock "in the background"
    # Reset the core
    await reset_dut(dut)
    # Wait some delay 
    await wait_ncycles(dut, 5)
    # Reseed
    await svrs_seed_transaction(dut, 0xdeadbeefdeadbeef)
    # Process every cases
    for c in list_cases: 
        # Key configuration
        await svrs_key_procedure(dut, c.key.bytes, 0, nshares)
        # Start execution with plaintext 
        await svrs_input_data_transaction(
                dut, 
                utils_smaesh.Sharing.from_int_umsk(c.plaintext.int, 16, nshares).to_int(),
                )
        # Wait for output
        out_shares_data = await svrs_output_data_transaction(dut)
        rec_output_int = utils_smaesh.Sharing.from_int(out_shares_data,16, nshares).recombine2int()
        assert rec_output_int == c.ciphertext.int, "Execution failure for case {}".format(c)

# Template for simple use case of the core, performing only decryption
# for a list of cases. 
# At most 'timeout_cycles' are runned during the encryption
async def AES_BC_DEC_TEMPLATE(dut, list_cases, timeout_cycles, nshares):
    """Try accessing the design."""
    # Start the clock
    await cocotb.start(generate_clock(dut,ncycles=timeout_cycles))  # run the clock "in the background"
    # Reset the core
    await reset_dut(dut)
    # Wait some delay 
    await wait_ncycles(dut, 5)
    # Reseed
    await svrs_seed_transaction(dut, 0xdeadbeefdeadbeef)
    # Process every cases
    for c in list_cases: 
        # Key configuration
        await svrs_key_procedure(dut, c.key.bytes, 1, nshares)
        # Start execution with plaintext 
        await svrs_input_data_transaction(
                dut, 
                utils_smaesh.Sharing.from_int_umsk(c.ciphertext.int, 16, nshares).to_int(),
                )
        # Wait for output
        out_shares_data = await svrs_output_data_transaction(dut)
        rec_output_int = utils_smaesh.Sharing.from_int(out_shares_data,16, nshares).recombine2int()
        assert rec_output_int == c.plaintext.int, "Execution failure for case {}".format(c)

# Test for the AES-128 encryption KAT
@cocotb.test()
async def AES_128_ENC_KAT(dut):
    # Load the test cases
    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_128_FILES)
    await AES_BC_ENC_TEMPLATE(dut, list_cases, 50000, NSHARES)

# Test for the AES-128 execution
@cocotb.test()
async def AES_128_DEC_KAT(dut):
    # Load the test cases
    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_128_FILES)
    await AES_BC_DEC_TEMPLATE(dut, list_cases, 150000, NSHARES)

# Test for the AES-92 encryption KAT
@cocotb.test()
async def AES_192_ENC_KAT(dut):
    # Load the test cases
    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_192_FILES)
    await AES_BC_ENC_TEMPLATE(dut, list_cases, 100000, NSHARES)

# Test for the AES-128 execution
@cocotb.test()
async def AES_192_DEC_KAT(dut):
    # Load the test cases
    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_192_FILES)
    await AES_BC_DEC_TEMPLATE(dut, list_cases, 300000, NSHARES)

# Test for the AES-92 encryption KAT
@cocotb.test()
async def AES_256_ENC_KAT(dut):
    # Load the test cases
    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_256_FILES)
    await AES_BC_ENC_TEMPLATE(dut, list_cases, 100000, NSHARES)

# Test for the AES-128 execution
@cocotb.test()
async def AES_256_DEC_KAT(dut):
    # Load the test cases
    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_256_FILES)
    await AES_BC_DEC_TEMPLATE(dut, list_cases, 300000, NSHARES)

##########" Add more fancy tests
