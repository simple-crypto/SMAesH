import cocotb
import logging
import utils_KAT
import utils_smaesh
from cocotb.triggers import Timer, RisingEdge, FallingEdge

import functools as ft
import math
import utils_fuzzing
import random

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
async def wait_ncycles(clk, ncycles):
    for c in range(ncycles):
        await RisingEdge(clk)

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
            utils_smaesh.MAP_KSIZE_CFG[len(bytes_umsk_key)*8],
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
    await wait_ncycles(dut.clk, 5)
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
    await wait_ncycles(dut.clk, 5)
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

### Test for the AES-128 encryption KAT
#@cocotb.test()
#async def AES_128_ENC_KAT(dut):
#    # Load the test cases
#    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_128_FILES)
#    await AES_BC_ENC_TEMPLATE(dut, list_cases, 50000, NSHARES)
#
## Test for the AES-128 execution
#@cocotb.test()
#async def AES_128_DEC_KAT(dut):
#    # Load the test cases
#    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_128_FILES)
#    await AES_BC_DEC_TEMPLATE(dut, list_cases, 150000, NSHARES)
#
## Test for the AES-92 encryption KAT
#@cocotb.test()
#async def AES_192_ENC_KAT(dut):
#    # Load the test cases
#    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_192_FILES)
#    await AES_BC_ENC_TEMPLATE(dut, list_cases, 100000, NSHARES)
#
## Test for the AES-128 execution
#@cocotb.test()
#async def AES_192_DEC_KAT(dut):
#    # Load the test cases
#    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_192_FILES)
#    await AES_BC_DEC_TEMPLATE(dut, list_cases, 300000, NSHARES)
#
## Test for the AES-92 encryption KAT
#@cocotb.test()
#async def AES_256_ENC_KAT(dut):
#    # Load the test cases
#    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_256_FILES)
#    await AES_BC_ENC_TEMPLATE(dut, list_cases, 100000, NSHARES)
#
## Test for the AES-128 execution
#@cocotb.test()
#async def AES_256_DEC_KAT(dut):
#    # Load the test cases
#    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_256_FILES)
#    await AES_BC_DEC_TEMPLATE(dut, list_cases, 300000, NSHARES)

# Monitor signals on the posedge of the provided clock
class SyncMonitor:
    def __init__(self, 
            logger,
            clk: cocotb.handle.ModifiableObject, 
            sigs: list[cocotb.handle.ModifiableObject],
            description= "Monitor"
            ):
        self.description = description
        self.log = logger
        self.clk = clk
        self.sigs = sigs

    def int2hexstring(self, v, nbytes):
        bl = ["{:02x}".format((v>>(i*8))&0xff) for i in range(nbytes)]
        bl.reverse()
        return ft.reduce(lambda a, b: a+b, bl) 

    async def run(self):
        cycle = 0
        while True: 
            await FallingEdge(self.clk)
            self.log.info("--- {} cycle {} ---".format(self.description, cycle))
            for si, s in enumerate(self.sigs):
                nbyte = math.ceil(s.value.n_bits/8)
                self.log.info("({}) {}: {}".format(si, s._name, self.int2hexstring(s.value, nbyte)))
            # Update cycle counter
            cycle += 1

# Generator of clock, with feature to stop the clock generation
# and counter for the clock cycle generated
class ClockGenerator:
    def __init__(self, clk: cocotb.handle.ModifiableObject, ncycles=None, units="ns", period=2):
        self.clk = clk
        self.ncycles = ncycles
        self.units=units
        self.period=2
        self.running = False
        self.cycle_counter = 0

    def set_maxcycles(self, ncycles):
        self.ncycles =  ncycles

    async def __turn_off(self):
        self.running = False

    async def __clock_cycle(self):
        self.clk.value = 0
        await Timer(self.period/2, units=self.units)
        self.clk.value = 1
        await Timer(self.period/2, units=self.units)
        self.cycle_counter += 1

    async def __start(self):
        self.running = True
        if (self.ncycles is not None):
            for c in range(self.ncycles):
                if self.running:
                    await self.__clock_cycle()
                else:
                    break
        else:
            while self.running:
                await self.__clock_cycle()

    async def start(self):
        await cocotb.start(self.__start())

    async def stop(self):
        await self.__turn_off()

########## More advanced tests
# Test of refresh
# Test of same guy configured
# Test of randomized transaction

# Basic generator, driving the dut 
# in order to perform the following flow 
# for the list of executions cases provided
# - reset (done only once)
# - send the seed (done only once)
# - configure the key
# - send the data
class SVRStreamsSimpleGenerator:
    def __init__(self, 
            dut,
            list_cases,
            inverse,
            nshares,
            logger = None
            ):
        self.dut = dut
        self.list_cases = list_cases
        self.inverse = inverse
        self.nshares = nshares
        self.logger = logger

    def _log(self, m:str):
        if self.logger is not None:
            self.logger.info(m)

    def _get_inverse(self):
        if self.inverse not in [0,1]:
            return random.randint(0,1)
        else:
            return self.inverse

    async def run(self):
        await set_valid_external_control(self.dut)
        await reset_dut(self.dut)
        await wait_ncycles(self.dut.clk, 2)
        await svrs_seed_transaction(self.dut, 0xdeadbeefdeadbeef)
        for c in self.list_cases:
            # Key configuration
            inverse_status = self._get_inverse()
            await svrs_key_procedure(self.dut, c.key.bytes, inverse_status, self.nshares)
            # Start execution with input data
            if inverse_status==0:
                datain = c.plaintext.int
            else:
                datain = c.ciphertext.int
            await svrs_input_data_transaction(
                    self.dut, 
                    utils_smaesh.Sharing.from_int_umsk(datain, 16, self.nshares).to_int(),
                    )

@cocotb.test()
async def basic_fuzzying(dut):
    # Logger for this test
    tl = logging.getLogger(__name__)
    tl.setLevel(logging.INFO)

    # Instaciate the clock generator
    clkgen = ClockGenerator(dut.clk, ncycles=None) 

    # Instanciate the svrs_generator 
    list_cases = utils_KAT.load_AES_BC_KAT_files(utils_KAT.KAT_AES_BC_256_FILES)
    svrs_generator = SVRStreamsSimpleGenerator(
            dut,
            list_cases[:10],
            0,
            NSHARES,
            logger=tl,
            )  
    
    # Create the packetizer
    packetizer = utils_fuzzing.SMAesHPacketizer(
            dut,
            NSHARES,
            logger=tl
            )

    # Create the reference processor
    ref_model = utils_fuzzing.SMAesHPacketProcessor(
            packetizer,
            NSHARES,
            logger=tl
            )

    # Create the Verifier
    verifier = utils_fuzzing.SMAesHVerifier(
            dut,
            ref_model,
            NSHARES,
            logger=tl
            )

    # Monitor
    monitor = SyncMonitor(
            myl,
            dut.clk,
            sigs=[
                dut.in_data_valid,
                dut.aes_valid_in,
                dut.in_data_ready,
                dut.in_shares_data,
                dut.in_key_valid,
                dut.in_key_ready,
                dut.in_key_data,
                dut.in_seed_valid,
                dut.in_seed_ready,
                dut.in_seed
                ]
            )

    # Reset the core
    await clkgen.start()
    await reset_dut(dut)
    await clkgen.stop()

    # Start the simulation flow
    await cocotb.start(svrs_generator.run())
    await cocotb.start(packetizer.run())
    await cocotb.start(ref_model.run())
    await cocotb.start(verifier.run())
    #await cocotb.start(monitor.run())
    await clkgen.start()

    # Simulate for several cycle
    await wait_ncycles(dut.clk,1000)





