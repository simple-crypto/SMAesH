import math
import re
import functools as ft

KAT_AES_BC_DIR="./KAT"
KAT_AES_BC_TEMPLATE=[
        "ECBGFSbox{}.rsp",
        "ECBKeySbox{}.rsp",
        "ECBVarKey{}.rsp",
        "ECBVarKey{}.rsp"
        ]


# Generate the paths the the file containing the KAT testvector for 
# single block cipher execution
def generate_KAT_AES_BC_paths(key_size):
    possible_ksize = [128,192,256]
    if key_size not in possible_ksize:
        raise ValueError("Value provided not handled")
    return ["{}/{}".format(KAT_AES_BC_DIR,e) for e in [f.format(key_size) for f in KAT_AES_BC_TEMPLATE]]

class HexBytesStringData:
    # Parse the string provided as an array of hexadecimal bytes
    @staticmethod
    def parse_hex_bytes(string, big_endian=False):
        # First, keep only hex characater, in lower case
        hex_char = re.sub('[^0-9,^abcdef,^ABCDEF]',"",string).lower()
        bstring = bytearray.fromhex(hex_char)
        if big_endian:
            bstring.reverse()
        return bstring
         
    def __init__(self, dstring, big_endian=False):
        self.bytes = HexBytesStringData.parse_hex_bytes(dstring, big_endian)
        self.int = int.from_bytes(self.bytes, 'little', signed=False)

    def __str__(self):
        return self.bytes.hex()


class AESBCExecuctionCase:
    def __init__(self, KAT_key, KAT_plaintext, KAT_ciphertext, source):
        self.key = HexBytesStringData(KAT_key, big_endian=False)
        self.plaintext = HexBytesStringData(KAT_plaintext, big_endian=False)
        self.ciphertext = HexBytesStringData(KAT_ciphertext, big_endian=False)
        self.source = source
        # UID as concat of hexvalue 
        self.uid = "{}-{}-{}".format(
                self.key,
                self.plaintext,
                self.ciphertext
                )

    def uid(self):
        return self.uid

    def __str__(self):
        return "[{}]\nkey:{}\nplaintext:{}\nciphertext:{}\n".format(
                    self.source,
                    self.key,
                    self.plaintext,
                    self.ciphertext
                )

# Parse a KAT file for single execution only for AES
def load_AES_BC_KAT_file(filepath):
    # Read the file
    with open(filepath, "r") as f:
        # Read filetext
        filetext = f.read()

    # Regex to get the different case in the files
    regex_text = re.findall("KEY = [A-Fa-f0-9]*[\r\n]PLAINTEXT = [A-Fa-f0-9]*[\r\n]CIPHERTEXT = [A-Fa-f0-9]*[\r\n]",filetext)
    # Iterate over the match and parse them to recover the values
    list_cases = []
    for m in regex_text:
        # Parse
        sp = re.split("[\r\n]",m)
        key = re.split("KEY = ",sp[0])[1]
        plaintext = re.split("PLAINTEXT = ",sp[1])[1]
        ciphertext = re.split("CIPHERTEXT = ",sp[2])[1]
        # Create the case
        list_cases.append(AESBCExecuctionCase(key,plaintext,ciphertext,filepath))
    # Return 
    return list_cases

# Load multiple files 
def load_AES_BC_KAT_files(list_files):
    cases = []
    for f in list_files:
        cases += load_AES_BC_KAT_file(f)
    return cases

# Compute some macros
KAT_AES_BC_128_FILES = generate_KAT_AES_BC_paths(128)
KAT_AES_BC_192_FILES = generate_KAT_AES_BC_paths(192)
KAT_AES_BC_256_FILES = generate_KAT_AES_BC_paths(256)

if __name__ == "__main__":
    list_cases = load_AES_BC_KAT_files(KAT_AES_BC_128_FILES)
    for c in list_cases[:5]:
        print("Key: {}".format(c.key))
        print("Plain: {}".format(c.plaintext))
        print("Ciphertext: {}".format(c.ciphertext))

