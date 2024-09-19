import functools as ft

CFG_KEY_SIZE = {
    128: 0,
    192: 1,
    256: 2
}

class Sharing:
    def __parse_shares(bvalues, nshares, encoding="stidded"):
        lv = len(bvalues)//nshares
        if encoding=="stridded":
            return [bvalues[i*lv:(i+1)*lv] for i in range(nshares)]    
        else:
            raise ValueError("Encoding not supported")
    def from_int(v, nbytes, nshares, encoding="stridded"):
        return Sharing(
                v.to_bytes(length=nbytes*nshares,byteorder='little'),
                nshares, 
                encoding=encoding
                )
    def from_int_umsk(v, nbytes, nshares):
        vbytes = bytes([(v>>(8*i))&0xff for i in range(nbytes)])
        for d in range(nshares-1):
            vbytes += bytes(nbytes*[0])
        return Sharing(vbytes, nshares, encoding="stridded")

    def __init__(self, bvalues, nshares, encoding="stridded"):
        self.shares = Sharing.__parse_shares(bvalues, nshares, encoding=encoding)
        self.nshares = nshares
        self.nbytes = len(bvalues) // nshares
        self.encoding = encoding

    def recombine2bytes(self):
        rec_bytes = self.nbytes*[0]
        for bi in range(self.nbytes):
            for di in range(self.nshares):
                rec_bytes[bi] ^= self.shares[di][bi]
        return bytes(rec_bytes)

    def recombine2int(self):
        return int.from_bytes(self.recombine2bytes(),byteorder="little")

    def to_int(self):
        if self.encoding=="stridded":
            return int.from_bytes(ft.reduce(lambda a,b:a+b,self.shares),byteorder='little') 
        else:
            raise ValueError("Encoding unsupported")
            
if __name__ == "__main__":
    a = Sharing.from_int_umsk(0x12345678, 4, 3)
    print(a.shares)
    print(hex(a.recombine2int()))
