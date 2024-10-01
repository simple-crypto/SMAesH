import cocotb
import logging
import os 
import random

import utils_smaesh

from functionnal_tests import reset_dut, wait_ncycles, wait_signal_asserted, svrs_seed_transaction, svrs_key_transaction, svrs_input_data_transaction, svrs_key_procedure, svrs_output_data_transaction, generate_clock 
from cocotb.triggers import Timer, RisingEdge, FallingEdge

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

def aes_execution(key: bytes, din: bytes, inverse: bool):
    cipher = Cipher(algorithms.AES(key), modes.ECB())
    if inverse:
        core = cipher.decryptor()
    else:
        core = cipher.encryptor()
    dout = core.update(din)
    return dout

@cocotb.test()
async def simple_execution(dut):
    # Logger for global debug
    myl = logging.getLogger(__name__)
    myl.setLevel(logging.INFO)
    # Recover execution parameters 
    NSHARES = int(os.getenv("NSHARES"))
    KEY_SIZE = int(os.getenv("KEY_SIZE"))
    INVERSE = int(os.getenv("INVERSE"))
    myl.info("--- MATCHI simulation parameters ---")
    myl.info("NSHARES: {}".format(NSHARES))
    myl.info("KEY_SIZE: {}".format(KEY_SIZE))
    myl.info("INVERSE: {}".format(INVERSE))
   
    # Some verifications
    assert KEY_SIZE in [128,192,256], "Invalid key size specified"
    assert INVERSE in [0,1], "Invalid inverse mode"
    assert NSHARES >= 2, "The amount of share must be >= 2"
    
    # Run the simple execution
    key_nbytes = KEY_SIZE // 8

    # Generate random case
    bytes_key = bytes([random.randint(0,255) for _ in range(key_nbytes)])
    bytes_pt = bytes([random.randint(0,255) for _ in range(16)])
    bytes_ct = aes_execution(bytes_key, bytes_pt, False)
    myl.info("Simulation case:")
    myl.info("key: {}".format(hex(int.from_bytes(bytes_key,byteorder="little"))))
    myl.info("pt: {}".format(hex(int.from_bytes(bytes_pt,byteorder="little"))))
    myl.info("ct: {}".format(hex(int.from_bytes(bytes_ct,byteorder="little"))))

    # Simulate the run with dut
    await cocotb.start(generate_clock(dut,ncycles=None)) 
    await reset_dut(dut)
    await wait_ncycles(dut.clk, 5)
    await svrs_seed_transaction(dut, 0xdeadbeefdeadbeef)
    await svrs_key_procedure(dut, bytes_key, INVERSE, NSHARES)
    if bool(INVERSE):
        bytes_din = bytes_ct
        ref_dout = int.from_bytes(bytes_pt,byteorder="little")
    else:
        bytes_din = bytes_pt
        ref_dout = int.from_bytes(bytes_ct,byteorder="little")
    # Encode din as int
    din = utils_smaesh.Sharing.from_int_umsk(
                int.from_bytes(bytes_din,byteorder='little'), 16, NSHARES
                ).to_int()
    myl.info("DEBGU: {}".format(hex(din)))
    # Start the execution
    await svrs_input_data_transaction(dut, din)
    # Wait for the end
    dout = await svrs_output_data_transaction(dut)
    await wait_ncycles(dut.clk, 5)
    umsk_dout = utils_smaesh.Sharing.from_int(
            dout, 16, NSHARES
            ).recombine2int()
    assert umsk_dout == ref_dout, "Functionnal failure of the execution..."
    
