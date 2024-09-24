import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from enum import Enum

import functools as ft
import random
import utils_smaesh

class MessageType(Enum):
    SEED = 0
    KEY = 1
    DATA = 2

class MessageData:
    def __init__(self, data:bytes , description="data"):
        self.data = data
        self.len = len(data)
        self.description = description
    def __str__(self):
        return "{}[{}] - {}".format(
                self.description, 
                self.len, 
                ''.join(format(x, "02x") for x in self.data)
                )

class MessageBus:
    def __init__(self, datas: list[MessageData]):
        self.datas = {}
        self.sizes = {}
        for d in datas:
            self.datas[d.description] = d
            self.sizes[d.description] = d.len
    
    @property
    def keys(self):
        return self.datas.keys()

    def __str__(self):
        all_str_data = ["({}): {}".format(i, d) for i, d in enumerate(self.datas.values())]
        return ft.reduce(lambda a,b: a+b, all_str_data)

class SMAESHMessage:
    TYPE_STR = {
            MessageType.SEED : "SEED",
            MessageType.KEY: "KEY",
            MessageType.DATA: "DATA"
            }
    def int2bytes(v: int, nbytes: int):
        return bytes([(v>>(8*i))&0xff for i in range(nbytes)])

    def seed_msg(data: bytes):
        if len(data)!=10:
            raise ValueError("A seed must be 80-bit long")
        else:
            return SMAESHMessage(
                    MessageType.SEED, 
                    MessageBus([MessageData(data, description="data")])
                    ) 

    def seed_msg_int(data: int):
        return SMAESHMessage.seed_msg(SMAESHMessage.int2bytes(data, 10))

    def key_msg(data: bytes, key_size: int, inverse_mode: bool):
        if len(data)!=4:
            raise ValueError("Key material word must be 32-bit long")
        else:
            return SMAESHMessage(
                    MessageType.KEY,
                    MessageBus([
                        MessageData(data, description="data"),
                        MessageData(bytes([key_size]), description="size"),
                        MessageData(bytes([inverse_mode]), description="inverse")
                        ])
                    )
    def key_msg_int(data: int, key_size: int, inverse_mode: bool):
        return SMAESHMessage.key_msg(SMAESHMessage.int2bytes(data, 4), key_size, inverse_mode)

    def data_msg(data: bytes, nshares):
        if len(data)!=(16*nshares):
            raise ValueError("An input data must be d*128-bit long")
        else:
            return SMAESHMessage(
                    MessageType.DATA, 
                    MessageBus([MessageData(data, description="data")])
                    ) 

    def data_msg_int(data: bytes, nshares):
        return SMAESHMessage.data_msg(SMAESHMessage.int2bytes(data, 16*nshares), nshares)
        
    def __init__(self, mtype: MessageType, data: MessageBus):
        self.type=mtype
        self.data = data

    def __str__(self):
        return "-{}-\n{}".format(SMAESHMessage.TYPE_STR[self.type], self.data)

# Object used to generate a randomized stream following the SVRS protocol 
# defined in the doc.
# TODO update with fine tuning of probability or interval between valid
class SVRStreamGenerator:
    def __init__(self, 
            clk_sig: cocotb.handle.ModifiableObject, 
            valid_sig: cocotb.handle.ModifiableObject, 
            ready_sig: cocotb.handle.ModifiableObject, 
            data_list: list[cocotb.handle.ModifiableObject]
            ):
        self.clk = clk_sig
        self.valid = valid_sig
        self.ready = ready_sig
        self.data_list = data_list
        # Internal value for simulation
        self.transaction_done = True
        
        # Init with 0
        self.valid.value = 0

    async def generate_random_data(self):
        for d in self.data_list:
            d.value = random.randint(0,(2**d.value.n_bits)-1)

    async def sample_random(self):
        await self.generate_random_data()
        self.valid.value = random.randint(0,1)

    # Async run used to generate the value, per cycle
    # respect the "stick" behavior of the valid signal
    async def run(self):
        while True:
            # Wait the following RisingEdge
            await RisingEdge(self.clk)
            if self.transaction_done or (self.valid.value == 0):
                # Need to sample fresh data
                await self.sample_random()
                self.transaction_done = False
            # Wait for the FallingEdge
            await FallingEdge(self.clk)
            # Resolve the transaction
            if (self.ready.value == 1) and (self.valid.value == 1):
                self.transaction_done = True


class FunctionnalException(Exception):
    def __init__(self, message):
        super().__init__(message)


class SimpleFIFO:
    class EmptyFIFOException(Exception):
        def __init__(self):
            super().__init__("The FIFO is empty")

    def __init__(self):
        self.elems = []

    def push(self, e):
        self.elems.append(e)
    
    def __len__(self):
        return len(self.elems)

    def pop(self):
        if self.__len__()==0:
            raise SimpleFIFO.EmptyFIFOException()
        else:
            return self.elems.pop(0)

# SMAesH Packetizer:
# Object used to decode the continuous control flow at the top level of SMAesH 
# in order to interpret the control signal as a sequence of following packed. 
# Assumes that no reset occurs
class SMAesHPacketizer:
    def __init__(self, dut, nshares, logger=None):
        self.dut = dut
        self.nshares = nshares
        self.packets = SimpleFIFO()
        self.logger = logger
        self.msg_ready = cocotb.triggers.Event()
        self.msg_ready.clear()

    def _log(self, m):
        if self.logger is not None:
            self.logger.info(m)

    def _push(self, m):
        self.packets.push(m)
        self._log("[Packet.pushed]: {}".format(m))

    def flag_new_message(self):
        return self.msg_ready.wait()

    def reset_flag_new_message(self):
        self.msg_ready.clear()

    async def run(self):
        while True:
            # Wait for the following rising Edge 
            await RisingEdge(self.dut.clk) 
            # Wait for the FallingEdge
            await FallingEdge(self.dut.clk)
            # Interpret signals
            tr_key = (self.dut.in_key_valid.value == 1) and (self.dut.in_key_ready.value == 1)
            tr_seed = (self.dut.in_seed_valid.value == 1) and (self.dut.in_seed_ready.value == 1)
            tr_data = (self.dut.in_data_valid.value == 1) and (self.dut.in_data_ready.value == 1)
            if (tr_key and tr_seed and tr_data):
                raise FunctionnalException("Transactions occured in more than 1 stream") 
            # Process different transaction, if it occurs
            if tr_key:
                self._push(SMAESHMessage.key_msg_int(
                    self.dut.in_key_data.value,
                    self.dut.in_key_size_cfg.value,
                    int(self.dut.in_key_mode_inverse.value)
                    ))
            if tr_seed:
                self._push(SMAESHMessage.seed_msg_int(self.dut.in_seed.value))
            if tr_data:
                self._push(SMAESHMessage.data_msg_int(self.dut.in_shares_data.value, self.nshares))
            # Synchronize 
            if len(self.packets)>0:
                self._log("[Packet.remaining]: {} packet(s) left.".format(len(self.packets)))
                self.msg_ready.set()

# PacketProcessor
# Take serial message rom Packetizer and simulate the 
# expected behaviour of the SMAesH IP.  
class SMAesHPacketProcessor:
    def __init__(self, packetizer: SMAesHPacketizer, nshares, logger=None):
        self.nshares = nshares
        self.packetizer = packetizer
        self.output_fifo = SimpleFIFO()
        self.logger = logger
        self.event_new_message = None
        # Init internal state
        self._init_state()         

    def _init_state(self):
        self.key_shares = []
        self.key_size = None
        self.inverse = None

    def _key_initialized(self):
        return (self.key_size != None)

    def _key_configured(self):
        if self._key_initialized():
            return len(self.key_shares) == (self.nshares*utils_smaesh.MAP_CFG_KSIZE[self.key_size]//8)
        else:
            return False

    def _log(self, m:str):
        if self.logger is not None:
            self.logger.info(m)

    def _proc_seed(self, m):
        # Nothing to do yet
        return 

    def _proc_key(self, m):
        # If 
        # - nothing yet initialized
        # - or new key configuration start (that is, if key is already configured)
        # -> Start a fresh processing
        if not(self._key_initialized()) or self._key_configured() :
            self.key_shares = m.data["data"].data
            self.key_size = int(m.data["size"].data[0])
            self.inverse = int(m.data["inverse"].data[0])
        else:
            # Simply append fresh data.
            # Configuration not considered here
            self.key_shares += m.data["data"].data

    def _execute(self, din:bytes):
        # First, unmask data to process 
        sharing_key = utils_smaesh.Sharing(self.key_shares, self.nshares, encoding="stridded")
        sharing_din = utils_smaesh.Sharing(self.din, self.nshares, encoding="stridded")
        self._log("[Processor.exec]: kcfg={} inverse={}".format(self.key_size, self.inverse))   
        self._log("key: {}".format(sharing_key.recombine2bytes().hex()))
        self._log("din: {}".format(sharing_din.recombine2bytes().hex()))

    def _proc_data(self, m):
        # Fetch the sharing, and process to execution
        self._execute(m.data["data"])

    async def run(self):
        while True:
            await self.packetizer.flag_new_message()
            self.packetizer.reset_flag_new_message()
            # A message must be processed
            m = self.packetizer.packets.pop()
            self._log("[Processor.proc]: {}".format(m))
            if m.type == MessageType.SEED:
                self._proc_seed(m)
            elif m.type == MessageType.KEY:
                self._proc_key(m)
            elif m.type == MessageType.DATA:
                self._proc_data(m)
            else:
                raise Exception("Message Type unsupported")
            

                

        














