import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from enum import Enum

import functools as ft
import random
import utils_smaesh
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

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
        all_str_data = ["\t({}): {}".format(i, d) for i, d in enumerate(self.datas.values())]
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

# An object that allows to deal with a SVRStream
class SVRStreamBus:
    def __init__(self, 
            valid_sig: cocotb.handle.ModifiableObject,
            ready_sig: cocotb.handle.ModifiableObject,
            data_list: list[cocotb.handle.ModifiableObject]
            ):
        self.valid = valid_sig
        self.ready = ready_sig
        self.data_list = data_list
        self.valid.value = 0

    # Generate fresh (random) value on the different data signals of the Bus
    def sample_random_data(self):
        for d in self.data_list:
            d.value = random.randint(0,(2**d.value.n_bits)-1)

    # Generate fresh (random) data and validity signal
    def sample_random(self):
        self.sample_random_data()
        self.valid.value = random.randint(0,1)

    def set_valid(self):
        self.valid.value = 1

    def reset_valid(self):
        self.valid.value = 0

    # Enforce a new fresh (random) data with valid asserted 
    def enforce_fresh_valid(self):
        self.sample_random_data()
        self.set_valid()

    # When sample, return tje status of an ongoing trnasaction.
    @property 
    def in_transaction(self):
        return (self.ready.value == 1) and (self.valid.value == 1)


class DeadlockException(Exception):
    def __init__(self):
        super().__init__("A deadlock occured in the simulation")

class SVRStreamGeneratorWithRandomDelay:
    def __init__(
            self,
            clk: cocotb.handle.ModifiableObject,
            stream: SVRStreamBus,
            latency_max_bound: int,
            latency_min_bound = 0,
            logger= None,
            logprefix = "GeneratorDelay"
            ):
        self.clk = clk
        self.stream = stream
        self.latency_min_bound = latency_min_bound
        self.latency_max_bound = latency_max_bound
        self.logger = logger
        self.logprefix = logprefix
        # Counter for the amount of cycles to wait
        self.transaction_done = False
        self.cnt_cycles = 0
        self.current_latency = 0
        self._update_latency()

    def _log(self, m):
        if self.logger is not None:
            self.logger.info(m)

    def _update_latency(self):
        self.current_latency = random.randint(
                self.latency_min_bound,
                self.latency_max_bound
                )
        self._log("[{}]: latency update with value {}".format(
            self.logprefix,self.current_latency))

    def _update_validity(self):
        if (self.cnt_cycles >= self.current_latency) and (self.stream.valid.value == 0):
            self._log("[{}]: {} cycles remaining ...".format(
            self.logprefix, self.current_latency - self.cnt_cycles))
            # Set the validity
            self.stream.set_valid()
            self._log("[{}]: Wait is over! Enforce stream validity.".format(self.logprefix))

    def _update_stream(self):
        if (self.stream.valid.value == 0):
            self.stream.sample_random_data()
        self._update_validity()

    def _update_transaction_done(self):
        if (self.stream.valid.value == 1) and (self.stream.ready.value == 1):
            self.transaction_done = True
            self._log("[{}]: A transaction happens!".format(self.logprefix))

    def _resolve_transaction_done(self):
        if self.transaction_done:
            # Redraw a random delay
            self._update_latency()
            # Reset counter
            self.cnt_cycles = 0
            self.stream.reset_valid()
            self.transaction_done = False

    async def run(self):
        while True:
            await RisingEdge(self.clk)
            self._resolve_transaction_done()
            self._update_stream()
            await FallingEdge(self.clk)
            self._update_transaction_done()
            self.cnt_cycles += 1

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


class SMAesHStats:
    def __init__(self):
        self.seed_cfg = 0
        self.key_cfg = 0
        self.data_cfg = 0

    def inc_seed(self):
        self.seed_cfg += 1

    def inc_key(self):
        self.key_cfg += 1

    def inc_data(self):
        self.data_cfg += 1

    def get_stats(self):
        return dict(
                seed = self.seed_cfg,
                key = self.key_cfg,
                data = self.data_cfg
                )

    def __str__(self):
        return "-- STATS --\n seeds:{}\nkey:{}\ndata:{}\n".format(
                self.seed_cfg,
                self.key_cfg,
                self.data_cfg
                )

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
        self.stats = SMAesHStats()
        # Init internal state
        self._init_state()         

    def _init_state(self):
        self.key_shares = []
        self.key_size = 0 # default
        self.inverse = 0

    def _key_initialized(self):
        return (len(self.key_shares)!=0)

    def _key_bytes_remaining(self):
        return (self.nshares*utils_smaesh.MAP_CFG_KSIZE[self.key_size]//8)-len(self.key_shares)

    def _key_configured(self):
        if self._key_initialized():
            return self._key_bytes_remaining()==0
        else:
            return False

    def _log(self, m:str):
        if self.logger is not None:
            self.logger.info(m)

    def _proc_seed(self, m):
        self.stats.inc_seed()

    def _proc_key(self, m):
        # If 
        # - nothing yet initialized
        # - or new key configuration start (that is, if key is already configured)
        # -> Start a fresh processing
        if not(self._key_initialized()) or self._key_configured() :
            self.key_shares = m.data.datas["data"].data
            self.key_size = int(m.data.datas["size"].data[0])
            self.inverse = int(m.data.datas["inverse"].data[0])
            self._log("[Processor.proc_key]: New key starts ({},{})".format(self.key_size,self.inverse))
        else:
            # Simply append fresh data.
            # Configuration not considered here
            self.key_shares += m.data.datas["data"].data
            self._log("[Processor.proc_key]: {} words remaining".format(self._key_bytes_remaining()//4))
            if self._key_configured():
                self.stats.inc_key()

    def _execute(self, din:bytes):
        # First, unmask data to process 
        sharing_key = utils_smaesh.Sharing(self.key_shares, self.nshares, encoding="stridded")
        sharing_din = utils_smaesh.Sharing(din, self.nshares, encoding="stridded")
        umsk_key = sharing_key.recombine2bytes()
        umsk_din = sharing_din.recombine2bytes()
        # Processus
        self.stats.inc_data()
        self._log("[Processor.exec]: kcfg={} inverse={}".format(self.key_size, self.inverse))   
        self._log("key: {}".format(umsk_key.hex()))
        self._log("din: {}".format(umsk_din.hex()))
        if len(umsk_key)!=0:
            cipher = Cipher(algorithms.AES(umsk_key), modes.ECB())
            if self.inverse:
                core = cipher.decryptor()
            else:
                core = cipher.encryptor()
            umsk_dout = core.update(umsk_din)
            self.output_fifo.push(umsk_dout)
            self._log("dout: {}".format(umsk_dout.hex()))
        else:
            self.output_fifo.push(None)

    def _proc_data(self, m):
        # TODO: refactorize: data.datas stuff is heavy
        # Fetch the sharing, and process to execution
        self._execute(m.data.datas["data"].data)

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
            

# SMAesH Verifie         
class SMAesHVerifier:
    def __init__(self, dut, ref_processor, nshares, logger=None):
        self.dut = dut
        self.ref_processor = ref_processor
        self.nshares = nshares
        self.logger = logger

    def _log(self, m:str):
        if self.logger is not None:
            self.logger.info(m)

    async def run(self):
        # Currently constant fetching
        # TODO: add a reader with back pressure
        # then add compartor on top of it
        self.dut.out_ready.value = 1
        while True:
            await FallingEdge(self.dut.clk)
            if self.dut.out_valid.value == 1:
                # Compare value
                self._log("[Verifier.verify]")
                sharing_dout = utils_smaesh.Sharing.from_int(
                        int(self.dut.out_shares_data.value), 
                        16,
                        self.nshares, 
                        encoding="stridded"
                        )  
                umsk_dout = sharing_dout.recombine2bytes()
                umsk_ref = self.ref_processor.output_fifo.pop()
                self._log("dut.dout: {}".format(umsk_dout.hex()))
                self._log("ref.dout: {}".format(umsk_ref.hex()))
                assert umsk_dout == umsk_ref, "Verification failed"
                


        
        














