#! /bin/bash 
# SPDX-FileCopyrightText: SIMPLE-Crypto contributors
# SPDX-License-Identifier: Apache-2.0
#
# Copyright SIMPLE-Crypto contributors
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Generate testvectors from known-answer test files.

import numpy as np
import argparse
from os.path import basename

def bytes2hexstr(b):
    st = ''
    for e in b:
        st += '{:02x}'.format(e)
    return st

def clean_line(l):
    t = l.replace("\n","")
    t = t.replace(" ","")
    return t

def fetch_int_data(line):
    cl = clean_line(line)
    spl = cl.split("=")
    return int(spl[1])

def fetch_bytes_data(line):
    cl = clean_line(line)
    spl = cl.split("=")
    return bytes(bytearray.fromhex(spl[1]))

def lineIsUsefull(l):
    if l=='\n':
        return False
    elif l[0]=="#":
        return False
    elif l[0]=="[":
        return False
    else:
        return True

def read_and_filter_file(filename):
    lines = []
    with open(filename,'r') as f:
        ls = f.readlines()
        for l in ls:
            if lineIsUsefull(l):
                lines.append(l)
    return lines

def parse_line(l):
    # Clean line
    cl = clean_line(l)
    # Parse
    split = cl.split("=")
    if len(split[1])==1:
        fv = "0{}".format(split[1])
    else:
        fv = split[1]
    if split[0]=="COUNT":
        return [split[0],int(split[1])]
    else:
        return [split[0],bytes(bytearray.fromhex(fv))]


def load_cases(filename):
    # Loda content of files and filter it
    ffile = read_and_filter_file(filename)
    # Parse content for cases
    cases = []
    case = None
    for l in ffile:
        # Parse the line
        [k,v] = parse_line(l)
        # Check if new case starts
        if k=="COUNT":
            if case != None:
                cases.append(case)
            case = {}
        # Update case value
        case[k]=v
    return cases

def parse_file_in(fnin):
    # Load cases
    cases = load_cases(fnin) 
    # Format cases
    list_cases = [[
        i,
        c["KEY"],
        c["PLAINTEXT"],
        c["CIPHERTEXT"],
        ] for i,c in enumerate(cases)]
    return list_cases
    
def write_file_head(fid,am):
    fid.write("## CASES:{}\n".format(am))

def write_case_head(fid,cid):
    fid.write("#### CASE:{}\n".format(cid))

def write_data(fid,name,datastr):
    fid.write("{}: {}\n".format(name,datastr)) 

def write_files_tv(cases,fn_in,fn_out):
    # Generate random last_in sigs
    last = np.random.randint(0,2,size=len(cases)).tolist()

    # Open files
    fin = open(fn_in,'w')
    fout = open(fn_out,'w')
    
    # Write file header
    write_file_head(fin,len(cases))
    write_file_head(fout,len(cases))

    # Iterate over each case
    for ci,c in enumerate(cases):
        [cid,k,p,c] = c
        # Write case head
        write_case_head(fin,cid)
        write_case_head(fout,cid)
        # Write data IN
        write_data(fin,"plaintext",bytes2hexstr(p))
        write_data(fin,"umsk_key",bytes2hexstr(k))
        write_data(fin,"last",str(last[ci]))
        # Write data OUT
        write_data(fout,"ciphertext",bytes2hexstr(c))
        write_data(fout,"last",str(last[ci]))

    # Clsoe file
    fin.close()
    fout.close()

def parser_add_options(parser):
    parser.add_argument(
            "--file-in",
            type=str,
            required=True,
            help="Input .rsp KAT file to process"
            )
    parser.add_argument(
            "--dir-out",
            type=str,
            required=True,
            help="Directory where file will be generated."
            )

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="File parser for testbench")
    parser_add_options(parser)
    args = parser.parse_args()

    filepref = basename(args.file_in).split(".")[0] 

    kat_in= '{}'.format(args.file_in)
    fn_in = '{}/TV_{}_in.rsp'.format(args.dir_out,filepref)
    fn_out = '{}/TV_{}_out.rsp'.format(args.dir_out,filepref)

    ## Parse files
    cases = parse_file_in(kat_in)

    ## Write files    
    write_files_tv(cases,fn_in,fn_out)
