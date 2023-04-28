#! /bin/env python3 
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

"""
Generator of masked pipelines from logical expressions.
"""

import argparse

def parse_args():
    parser = argparse.ArgumentParser(description="Automated generation of HPC verilog netlist")
    parser.add_argument(
            "--circuit-file",
            type=str,
            required=True,
            help="File where the circuit to generate is encoded"
            )
    parser.add_argument(
            "--verilog-module",
            type=str,
            required=True,
            help="Name of the generated module file. "
            )
    parser.add_argument(
            "--dir-out",
            type=str,
            default=".",
            help="Directory where the new Verilog module will be generated."
            )
    parser.add_argument(
            "--gen-enable",
            action='store_true',
            help="Use this flag to force generating enabling logic."
            )
    parser.add_argument(
            "--gen-ctrl",
            action="store_true",
            help="Use this flag to force the generation of control signal for randomness"
            )
    args = parser.parse_args()
    return args

class Nodeop:
    global_node_idx = 0
    def __init__(self,op,idsrc0,idsrc1):
        self.src0 = idsrc0
        self.src1 = idsrc1
        self.op = op
        self.lat = self.exp_lat()
        self.rndam = self.rnd_am()
        self.rndlat = self.rnd_lat()
        self.rnd_src = None
        self.ctrlsig0 = None
        self.node_index = Nodeop.global_node_idx
        Nodeop.global_node_idx += 1

    def update_op(self,op):
        self.op = op
        self.lat = self.exp_lat()
        self.rndam = self.rnd_am()
        self.rndlat = self.rnd_lat()
        if self.rnd_am is None:
            self.rnd_src = None
        if self.op != 'mux' and self.op != 'muxp*':
            self.ctrlsig0 = None

    def exp_lat(self):
        if self.op=='id':
            return (0,0,0)
        elif self.op=='not':
            return (0,0,0)
        elif self.op=='add':
            return (0,0,0)
        elif self.op=='and':
            return (0,0,0)
        elif self.op=='notp*':
            return (0,0,0)
        elif self.op=='andp2':
            #return (0,0,1)
            return (0,1,2)
        elif self.op=='addp2':
            return (0,0,0)
        elif self.op=='reg':
            return (0,0,1)
        elif self.op=='ctrl_reg':
            return (0,0,1)
        elif self.op=='mux':
            return (0,0,0)
        elif self.op=='muxp*':
            return (0,0,0)
        else:
            raise ValueError("Configuration not handled")

    def rnd_am(self):
        if self.op=='andp2':
            return 'and_pini_nrnd'
        else:
            return None

    def rnd_lat(self):
        return 0  


class NodeVar:
    global_var_id = 0
    def __init__(self,strid,op,time,dtype,lenstr):
        self.id = strid
        self.op = op
        # dtype='data' or 'control'
        self.dtype=dtype
        self.lenstr=lenstr
        self.var_index = NodeVar.global_var_id
        NodeVar.global_var_id += 1
        if op==None:
            self.time=time
        else:
            self.time=None
    
    def rnd_time(self):
        if self.op is None:
            return None
        elif self.op.rndam is None:
            return None
        else:
            return self.time + self.op.rndlat - self.op.lat[2]

def parse_cmd(cmd):
    # Remove space
    lws = cmd.replace(' ','')
    [idref,opref] = lws.split('=')
    # Create the pairs (IDs,OPs) 
    idstrs = []
    ops = []
    if '+' in opref:
        srcs = opref.split('+')
        idstrs.append(idref)
        ops.append('add({},{})'.format(srcs[0],srcs[1]))
    elif '&' in opref:
        srcs = opref.split('&')
        idstrs.append(idref)
        ops.append('and({},{})'.format(srcs[0],srcs[1]))
    elif '~' in opref:
        srcs = opref.split('~')
        idstrs.append(idref)
        ops.append('not({})'.format(srcs[1]))
    elif '?' in opref and ':' in opref:
        [ctrl,srcs] = opref.split('?')
        srcs = srcs.split(':')
        idstrs.append(idref)
        ops.append('mux({},{},{})'.format(srcs[0],srcs[1],ctrl))
    elif '#' in opref or 'xnor(' in opref:
        if '#' in opref:
            srcs = opref.split('#')
        else:
            src0 = opref.split('xnor(')[1].split(')')[0].split(',')[0]
            src1 = opref.split('xnor(')[1].split(')')[0].split(',')[1]
            srcs = [src0,src1]
        # Temporary node
        idtmp = '{}_tmpNXOR'.format(idref)
        optmp = 'add({},{})'.format(srcs[0],srcs[1])
        idstrs.append(idtmp)
        ops.append(optmp)
        # Final not
        idstrs.append(idref)
        ops.append('not({})'.format(idtmp))
    elif '(' not in opref:
        idstrs.append(idref)
        ops.append('id({})'.format(opref))
    else:
        idstrs.append(idref)
        ops.append(opref)
    return [idstrs,ops]


def parse_line(line):
    # Parse as ID=op
    [idstrs,ops] = parse_cmd(line)
    # Create Node accordingly
    list_of_node = []
    for e in zip(idstrs,ops):
        (idstr,op) = e
        if 'input(' in op:
            size = op.split('input(')[1].split(')')[0].split(',')[0]
            dtype = op.split('input(')[1].split(')')[0].split(',')[1]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        None,
                        0,
                        dtype,
                        size
                        ),
                    False,
                    True
                    ])
        elif 'id(' in op:
            node = op.split('id(')[1].split(')')[0]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        Nodeop(
                            'id',
                            node,
                            None,
                            ),
                        None,
                        None,
                        None
                        ),
                    False,
                    False
                    ])
        elif 'not(' in op:
            node = op.split('not(')[1].split(')')[0]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        Nodeop(
                            'not',
                            node,
                            None,
                            ),
                        None,
                        None,
                        None
                        ),
                    False,
                    False
                    ])
        elif 'output(' in op:
            node = op.split('output(')[1].split(')')[0]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        Nodeop(
                            'id',
                            node,
                            None,
                            ),
                        None,
                        None,
                        None
                        ),
                    True,
                    False
                    ])
        elif 'reg(' in op:
            node = op.split('reg(')[1].split(')')[0]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        Nodeop(
                            'reg',
                            node,
                            None,
                            ),
                        None,
                        None,
                        None
                        ),
                    False,
                    False
                    ])
        elif 'add(' in op:
            op0 = op.split('add(')[1].split(')')[0].split(',')[0]
            op1 = op.split('add(')[1].split(')')[0].split(',')[1]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        Nodeop(
                            'add',
                            op0,
                            op1,
                            ),
                        None,
                        None,
                        None
                        ),
                    False,
                    False
                    ])
        elif 'and(' in op:
            op0 = op.split('and(')[1].split(')')[0].split(',')[0]
            op1 = op.split('and(')[1].split(')')[0].split(',')[1]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        Nodeop(
                            'and',
                            op0,
                            op1,
                            ),
                        None,
                        None,
                        None
                        ),
                    False,
                    False
                    ])
        elif 'andp2(' in op:
            op0 = op.split('andp2(')[1].split(')')[0].split(',')[0]
            op1 = op.split('andp2(')[1].split(')')[0].split(',')[1]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        Nodeop(
                            'andp2',
                            op0,
                            op1,
                            ),
                        None,
                        None,
                        None
                        ),
                    False,
                    False
                    ])
        elif 'addp2(' in op:
            op0 = op.split('addp2(')[1].split(')')[0].split(',')[0]
            op1 = op.split('addp2(')[1].split(')')[0].split(',')[1]
            list_of_node.append([
                    idstr,
                    NodeVar(
                        idstr,
                        Nodeop(
                            'addp2',
                            op0,
                            op1,
                            ),
                        None,
                        None,
                        None
                        ),
                    False,
                    False
                    ])
        elif 'mux(' in op:
            op0 = op.split('mux(')[1].split(')')[0].split(',')[0]
            op1 = op.split('mux(')[1].split(')')[0].split(',')[1]
            ctrl0 = op.split('mux(')[1].split(')')[0].split(',')[2]
            nodev = NodeVar(
                    idstr,
                    Nodeop(
                        'mux',
                        op0,
                        op1,
                        ),
                    None,
                    None,
                    None
                    )
            nodev.op.ctrlsig0 = ctrl0
            list_of_node.append([
                    idstr,
                    nodev,
                    False,
                    False
                    ])
        else:
            raise ValueError('Failure when parsing: {}'.format(op))
    return list_of_node

# Search the data source of the source of a signal
def search_dtype_source(circuit,idstr):
    if idstr not in circuit:
        raise ValueError("Signal reference '{}' not found in the circuit".format(idstr))
    vnode = circuit[idstr]
    if vnode.dtype is not None:
        return vnode.dtype
    else:
        if vnode.op is None:
            if vnode.dtype is None:
                raise ValueError(
                        'Architecture error...Data type should exist for {}'.format(
                            vnode.id
                            )
                        )
            else:
                return vnode.dtype
        else:
            vnop = vnode.op
            dt0 = None
            dt1 = None
            if vnop.src0 is not None:
                dt0 = search_dtype_source(circuit,vnop.src0)
                dt1=dt0
            if vnop.src1 is not None:
                dt1 = search_dtype_source(circuit,vnop.src1)
            if dt0==dt1:
                return dt0
            else:
                raise ValueError(
                        'Architecture error...Data type mixed accros the circuit at node {}'.format(
                            vnode.id
                        )
                    )

# Resolve the data type of each node in a circuit
def resolve_dtype_circuit(circuit):
    for gk in circuit.keys():
        vdtype=search_dtype_source(circuit,gk)
        circuit[gk].dtype=vdtype

# Search len of a source of a signal
def search_len_source(circuit,idstr):
    vnode = circuit[idstr]
    if vnode.lenstr is not None:
        return vnode.lenstr
    else:
        if vnode.op is None:
            if vnode.lenstr is None:
                raise ValueError(
                        "Architecture error... Node lenstr should exist for node {}".format(
                            vnode.id
                            )
                        )
            else:
                return vnode.lenstr
        else:
            vnop = vnode.op
            l0 = None
            l1 = None
            if vnop.src0 is not None:
                l0 = search_len_source(circuit,vnop.src0)
                l1 = l0
            if vnop.src1 is not None:
                l1 = search_len_source(circuit,vnop.src1)
            if l0==l1:
                return l0
            else:
                raise ValueError(
                        'Architecture error... Mismatch between length at node {}'.format(
                            vnode.id
                        )
                    )

# Resolve the len of each variable in a circuit 
def resolve_len_circuit(circuit):
    for gk in circuit.keys():
        vlen = search_len_source(circuit,gk)
        circuit[gk].lenstr = vlen


def add_node_to_circuit(k,n,circuit):
    if k not in circuit.keys():
        circuit[k] = n
        return False
    else:
        return True

def parse_circuit(filename):
    circuits = {}
    outputs = []
    inputs = []
    with open(filename,'r') as f:
        gtxt = f.read()
        gtxt_lines = gtxt.split('\n')
        for l in gtxt_lines:
            if l!='' and '//' not in l:
                list_of_node = parse_line(l)
                for nstr in list_of_node:
                    [idstr,node,isout,isin] = nstr
                    error_node = add_node_to_circuit(idstr,node,circuits)
                    if not(error_node):
                        if isout:
                            outputs.append(idstr)
                        if isin:
                            inputs.append(idstr)
                    else:
                        raise ValueError('Collision in vairable key: {}'.format(idstr))
    return (circuits,outputs,inputs)

def reset_latency_circuit(circuit):
    for n in circuit.values():
        if n.op is not None:
            n.time = None

# Evaluate the latency of a specific node in the circuit
def evaluate_latency_node(idstr,circuits,verbose=False):
    vNode = circuits[idstr]
    if vNode.time is None:
        nop = vNode.op
        lat_0 = 0
        lat_1 = 0
        if nop.src0 is not None:
            evaluate_latency_node(nop.src0,circuits,verbose=verbose)
            lat_0 = circuits[nop.src0].time 
        if nop.src1 is not None:
            evaluate_latency_node(nop.src1,circuits,verbose=verbose)
            lat_1 = circuits[nop.src1].time
        # Compute the effective latency
        time_ref = 0
        del2add = 0
        if lat_0>=lat_1:
            time_ref = lat_0
            del2add = nop.lat[2]
        else:
            time_ref = lat_1
            del2add = nop.lat[2]-nop.lat[1]
        vNode.time = time_ref+del2add
        if verbose:
            print('Evaluate latency \'{}\''.format(vNode.id))
            if nop.src0 is not None:
                print('-Src0 \'{}\' : {} (lat: {})'.format(
                    nop.src0,
                    circuits[nop.src0].time,
                    nop.lat[0]
                    )
                    )
            if nop.src1 is not None:
                print('-Src1 \'{}\' : {} (lat: {})'.format(
                    nop.src1,
                    circuits[nop.src1].time,
                    nop.lat[1]
                    )
                    )
            print('-Output lat: {}'.format(nop.lat[2]))
            print('-> Time: {}\n'.format(vNode.time))
    else:
        if verbose:
            print('Evaluate latency \'{}\''.format(vNode.id))
            print('-> Time: {}\n'.format(vNode.time))
    
# Evaluate the latency of each node in the circuit
def evaluate_latency_circuit(circuits,outs,verbose=False):
    if verbose:
        print("## TIMING EVALUATION OF THE CIRCUIT ##")
    reset_latency_circuit(circuits)
    for og in circuits.keys():
        evaluate_latency_node(og,circuits,verbose=verbose)
    if verbose:
        print("## TIMING EVALUATION DONE ##")

def merge_node_list(l0,l1):
    merged = l0
    for e in l1:
        if e not in merged:
            merged.append(e)
    return merged

def check_latency_node(idstr,circuit):
    node = circuit[idstr]
    if node.op is None:
        return []
    else:
        ops0 = node.op.src0
        ops1 = node.op.src1
        # Get back result from previous operations
        if ops0 is not None:
            blisto0 = check_latency_node(ops0,circuit)
        else:
            blisto0 = []
        if ops1 is not None:
            blisto1 = check_latency_node(ops1,circuit)
        else:
            blisto1 = []

        failures = merge_node_list(blisto0,blisto1)

        # evaluate current gate
        if ops1 is not None:
            reft = circuit[ops0].time
            t1 = circuit[ops1].time
            flag_fail = t1-reft != node.op.lat[1]
            if flag_fail:
                failures = merge_node_list(failures,[idstr])

        return failures

# Must be done after timing resolution (evaluate timing starting starting with all output node)
def pass_opti_timing_two_inputs(circuit,out,verbose=False):
    if verbose:
        print('Optimisation pass to reduce latency due to two inputs gadget')
    for gk in circuit.keys():
        g = circuit[gk]
        if g.op is not None:
            if g.op.src1 is not None:
                tin0 = circuit[g.op.src0].time
                tin1 = circuit[g.op.src1].time

                if tin0>tin1:
                    if verbose:
                        print('Possible optimisation found in {}'.format(g.id))
                        print('Timestamp in0 (T=0): {}'.format(tin0))
                        print('Timestamp in1 (T=1): {}'.format(tin1))
                        print('Inputs have been swapped')
                        print()
                    temp_node = g.op.src0
                    g.op.src0 = g.op.src1
                    g.op.src1 = temp_node 
    evaluate_latency_circuit(circuit,out,verbose=verbose)
    

def check_latency_accross_circuit(circuit,outputs):
    list_failures = []
    # First evaluate latency accross the circuit
    for oid in outputs:
        evaluate_latency_node(oid,circuit)
        list_failures = merge_node_list(list_failures,check_latency_node(oid,circuit))
    return list_failures

def gen_dsig_name(signame,delay):
    dname = signame
    for i in range(delay):
        dname = 'd{}'.format(dname)
    return dname

def recur_add_delay_step_opin(op,idsrc,sig2add,circuit,ntype="data"):
    # First, check if the signal to add does not exist
    if sig2add in circuit.keys():
        # Just change the connexion
        if idsrc==0:
            op.src0 = sig2add
        elif idsrc==1:
            op.src1 = sig2add
        else:
            raise ValueError("Error")
    else:
        nodetype = 'ctrl_reg' if ntype=="control" else "reg"
        nextsig2add = sig2add[1:]
        # Create the signal, add it to the circuit, change
        # connexion and iterate with the newly created operation
        reg_node = NodeVar(
                    sig2add,
                    Nodeop(
                        nodetype,
                        nextsig2add,
                        None,
                        ),
                    None,
                    None,
                    None
                    )
        error_node = add_node_to_circuit(sig2add,reg_node,circuit)
        if error_node:
            raise ValueError('Failure when adding delay')
        if idsrc==0:
            op.src0 = sig2add
        elif idsrc==1:
            op.src1 = sig2add
        else:
            raise ValueError("Error")
        
        # Add next connexion
        recur_add_delay_step_opin(
                circuit[sig2add].op,
                0,
                nextsig2add,
                circuit,
                ntype=ntype
                )

def add_delay_opin(op,idsrc,delay,circuit,ntype="data"):
    if idsrc==0:
        ref_sign = op.src0
    else:
        ref_sign = op.src1

    # Generate the last delay signal to add   
    lds_name = gen_dsig_name(ref_sign,delay)
    
    # Add delay recursively
    recur_add_delay_step_opin(op,idsrc,lds_name,circuit,ntype=ntype)

def fix_latency_node(idstr,circuit):
    node = circuit[idstr]
    if node.op is not None:
        ops0 = node.op.src0
        ops1 = node.op.src1
        
        if ops1 is not None:
            reft = circuit[ops0].time
            t1 = circuit[ops1].time
            latency = t1 - reft
            latreq = node.op.lat[1]
            delta_latency = latency - latreq
            lat2add = abs(delta_latency)
            if delta_latency>0:
                # Need to add delay on the src0 input 
                add_delay_opin(node.op,0,lat2add,circuit)        
            else:
                # Need to add delay on the src1 input
                add_delay_opin(node.op,1,lat2add,circuit)        

def reset_latency_circuit(circuit):
    for n in circuit.values():
        if n.op is not None:
            n.time = None

def convert_gates(circuits,dicconv):
    for n in circuits.values():
        if n.op is not None and n.dtype=='data':
            if n.op.op in dicconv.keys():
                n.op.update_op(dicconv[n.op.op])

def fix_latency_failures(failures,circuit,outs,maxoverhead=10):
    epoc = 0
    maxpass = maxoverhead + len(failures)
    rem_error = failures.copy()
    while epoc<maxpass and len(rem_error)>0:
        fix_latency_node(rem_error[0],circuit)
        reset_latency_circuit(circuit)
        rem_error = check_latency_accross_circuit(circuit,outs)
        epoc += 1

def fix_output_latency(circuit,outs):
    # Fetch output value
    time_output = []
    for oui in outs:
        time_output.append(circuit[oui].time)
    # Target latency is the max one
    tlat = max(time_output)
    for ei,e in enumerate(time_output):
        d2add = tlat - e
        if d2add>0:
            # Generate the last delay signal to add
            lds_name = gen_dsig_name(circuit[outs[ei]].op.src0,d2add)
            recur_add_delay_step_opin(
                    circuit[outs[ei]].op,
                    0,
                    lds_name,
                    circuit
                    )
    # Recompute timing
    reset_latency_circuit(circuit)
    for o in outs:
        evaluate_latency_node(o,circuit)

def recur_gatelist_order(idstr,circuit):
    if circuit[idstr].op is None:
        return [idstr]
    else:
        rec_list_gate = []
        if circuit[idstr].op.src0 is not None:
            rec_list_gate = merge_node_list(
                    rec_list_gate,
                    recur_gatelist_order(
                        circuit[idstr].op.src0,
                        circuit
                        )
                    )
        if circuit[idstr].op.src1 is not None:
            rec_list_gate = merge_node_list(
                    rec_list_gate,
                    recur_gatelist_order(
                        circuit[idstr].op.src1,
                        circuit
                        )
                    )
        rec_list_gate.append(idstr)
        return rec_list_gate

def create_gatelist_order(circuit,outs,ins):
    list_gate = []
    for out in outs:
        list_gate = merge_node_list(
                recur_gatelist_order(out,circuit),
                list_gate
                )
    return list_gate

def create_mux_ctrl_tree_order(circuit):
    # Create list of mux control signals
    mux_ctrl_id = []
    for g in circuit.values():
        if g.op is not None:
            if g.op.op == 'mux' or g.op.op == 'muxp*':
                mux_ctrl_id.append(g.op.ctrlsig0)
    # Elaborate variables nodes
    list_gate = []
    for mctrl in mux_ctrl_id:
        list_gate = merge_node_list(
                recur_gatelist_order(mctrl,circuit),
                list_gate
                )
    return list_gate


def create_verilog_template_entry(var,iotype,def_clk='clk',def_en='enable',def_rst='rst',gen_en=False):
    if iotype=='input':
        return "assign {} = 0;".format(var.id)
    elif iotype=='output':
        return "assign {} = {};".format(var.id,var.op.src0)
    else:
        if var.op.op=='id':
            return "assign {} = {};\n".format(
                    var.id,
                    var.op.src0
                    )
        elif var.op.op=='not':
            return "assign {} = ~{};\n".format(
                    var.id,
                    var.op.src0
                    )
        elif var.op.op=='add':
            return "assign {} = {} ^ {};\n".format(
                    var.id,
                    var.op.src0,
                    var.op.src1
                    )
        elif var.op.op=='and':
            return "assign {} = {} & {};\n".format(
                    var.id,
                    var.op.src0,
                    var.op.src1
                    )
        elif var.op.op=='mux':
            return "assign {} = {} ? {} : {};\n".format(
                    var.id,
                    var.op.ctrlsig0,
                    var.op.src0,
                    var.op.src1
                    )
        elif var.op.op=='notp*':
            return """MSKinv #(.d({}))
inv_{} (
    .in({}),
    .out({})
    );\n""".format(var.lenstr,var.id,var.op.src0,var.id)
        elif var.op.op=='andp2' and gen_en:
            return """MSKandEn_HPC2 #(.d({}))
andhpc2_{} (
    .ina({}),
    .inb({}),
    .rnd({}),
    .clk({}),
    .out({}),
    .en({})
    );\n""".format(var.lenstr,var.id,var.op.src1,var.op.src0,var.op.rnd_src,def_clk,var.id,def_en)
        elif var.op.op=='andp2' and not(gen_en):
            return """MSKand_HPC2 #(.d({}))
andhpc2_{} (
    .ina({}),
    .inb({}),
    .rnd({}),
    .clk({}),
    .out({})
    );\n""".format(var.lenstr,var.id,var.op.src1,var.op.src0,var.op.rnd_src,def_clk,var.id)
        elif var.op.op=='addp2':
            return """MSKxor #(.d({}))
xorhpc2_{} (
    .ina({}),
    .inb({}),
    .out({})
    );\n""".format(var.lenstr,var.id,var.op.src0,var.op.src1,var.id)
        elif var.op.op=='reg' and gen_en:
            return """MSKregEn #(.d({}))
regen_{} (
    .clk({}),
    .en({}), 
    .in({}),
    .out({})
    );\n""".format(var.lenstr,var.id,def_clk,def_en,var.op.src0,var.id)
        elif var.op.op=='reg' and not(gen_en):
            return """MSKreg #(.d({}))
regen_{} (
    .clk({}),
    .in({}),
    .out({})
    );\n""".format(var.lenstr,var.id,def_clk,var.op.src0,var.id)
        elif var.op.op=='ctrl_reg' and gen_en:
            return """ctrl_regEn #(.l({}))
ctrl_reg_{} (
    .clk({}),
    .en({}),
    .rst({}),
    .in({}),
    .out({})
    );\n""".format(var.lenstr,var.id,def_clk,def_en,def_rst,var.op.src0,var.id)
        elif var.op.op=='ctrl_reg' and not(gen_en):
            return """ctrl_reg #(.l({}))
ctrl_reg_{} (
    .clk({}),
    .rst({}),
    .in({}),
    .out({})
    );\n""".format(var.lenstr,var.id,def_clk,def_rst,var.op.src0,var.id)
        elif var.op.op=='muxp*':
            return """MSKmux #(.d({}))
muxp_{} (
    .sel({}),
    .in_true({}),
    .in_false({}),
    .out({})
    );\n""".format(var.lenstr,var.id,var.op.ctrlsig0,var.op.src0,var.op.src1,var.id)
        else:
            raise ValueError("Gate not handled")

def create_internal_variable_list(circuit,outs,ins):
    # First keep only internal variable
    signals = []
    for gi,g in enumerate(circuit.keys()):
        if g not in outs and g not in ins:
            signals.append(g)
    # Create list of internal variable 
    var_list = '// Internal variables\n'
    for s in signals:
        ls = circuit[s].lenstr
        if ls=='1' or ls=='1*1':
            var_list += 'wire {};\n'.format(s)
        else:
            var_list += 'wire [{}-1:0] {};\n'.format(ls,s)
    var_list += '\n'
    return var_list

def interface_selection(circuit,gen_enable):
    interface = []
    for g in circuit.values():
        if g.op is not None:
            if g.op.op=='andp2' or g.op.op=="reg":
                if 'clock' not in interface:
                    interface.append('clock')
                if 'enable' not in interface and gen_enable:
                    interface.append('enable')
            if g.op.op=='ctrl_reg':
                if 'clock' not in interface:
                    interface.append('clock')
                if 'enable' not in interface and gen_enable:
                    interface.append('enable')
                if 'reset' not in interface:
                    interface.append('reset')

    return interface

def create_rnd_bus_string(btime):
    return 'rnd_bus{}'.format(btime)

def get_time_from_rnd_bus_str(rnd_bus_str):
    return rnd_bus_str[-1]

def create_need_rnd_string(btime):
    return 'need_rnd_bus{}'.format(btime)

def create_top_verilog_interface(name_module,circuit,outs,ins,gen_enable):
    ## Create inputs signals
    io_verilog = '\t// Circuit inputs IOs\n'
    # Fetch interface additional signals
    interface_sig = interface_selection(circuit,gen_enable)
    for interf in interface_sig:
        if interf=='clock':
            io_verilog += '\tclk,\n'
        elif interf=='enable':
            io_verilog += '\tenable,\n'
        elif interf=='reset':
            io_verilog += '\trst,\n'
    # Parse inputs
    for ing in ins:
        io_verilog += '\t{},\n'.format(ing)
    ## Parse circuit outputs
    io_verilog += '\t// Circuit outputs IOs\n'
    for outg in outs:
        io_verilog += '\t{},\n'.format(outg)
    # Finalize
    io_verilog = io_verilog[:-2]
    io_verilog += '\n'
    ## Create format
    top_interface_IO = """(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module {}
#
(
    parameter d=2
)
(
    {}
);""".format(name_module,io_verilog)
    return top_interface_IO
   

def create_validity_pipeline(circuit,outs,ins):
    # Get the latency as the latency of the output after having fixed 
    # the latency
    global_latency = circuit[outs[0]].time
    if global_latency>0:
        circuit_nopipe = circuit.copy()
        # Create input IO
        id_valid_in = 'valid_in'
        in_var = NodeVar(
            id_valid_in,
            None,
            0,
            'control',
            '1'
            )
        ins.append(id_valid_in)
        circuit[id_valid_in] = in_var
        # Create output IO
        id_valid_out = 'valid_out'
        out_var = NodeVar(
                    'valid_out',
                    Nodeop(
                        'id',
                        'valid_in',
                        None,
                        ),
                    None,
                    'control',
                    '1'
                    )
        outs.append(id_valid_out)
        circuit[id_valid_out] = out_var
        # Create delay pipeline
        add_delay_opin(
                circuit[id_valid_out].op,
                0,
                global_latency,
                circuit,
                ntype='control'
                )
        # Create differential gate list
        gate_list_pipe_ordered = []
        for gk in circuit.keys():
            if gk not in circuit_nopipe:
                gate_list_pipe_ordered.append(gk)
        # Remove signal and put it again to have it ordered
        gate_list_pipe_ordered.remove('valid_in')
        gate_list_pipe_ordered.append('valid_in')
        gate_list_pipe_ordered.reverse()
        # Resolve post modification of the circuit
        resolve_dtype_circuit(circuit)
        resolve_len_circuit(circuit)
        evaluate_latency_circuit(circuit,outs)
        return gate_list_pipe_ordered

# Randomness busses represented as dico of dico
# where the keys are the time when the randomness
# is expected to enter and the value a randomness dico
def initialize_rnd_busses():
    return {}

# Add the id of the node 'node_var' to the bus with timing 'rnd_time' present in
# the busses list 'busses'.  A randomness bus is a dico containing two entries:
# 'nodes': a list of nodes id that depend on the bus 'lengths': a dico for
# which keys are node randomness requirement and keys are occurence of such
# requirement
def append_to_rnd_bus(busses,rnd_time,node_var):
    # Create the randomness bus if not already in the busses list
    if rnd_time not in busses.keys():
        busses[rnd_time] = {'nodes':[],'lengths':{}}
    # Add the node to the list and update the length
    busses[rnd_time]['nodes'].append(node_var.id)
    nodelen = node_var.op.rndam 
    if nodelen not in busses[rnd_time]['lengths'].keys():
        busses[rnd_time]['lengths'][nodelen] = 1
    else:
        busses[rnd_time]['lengths'][nodelen] += 1

def fetch_rnd_busses(circuit,outs,ins):
    # create gatelist order
    gatelist = create_gatelist_order(circuit,outs,ins)
    # Create the list of rnd busses, reprented as dico of dico
    rnd_busses = initialize_rnd_busses()
    for gk in gatelist:
        latency_time = circuit[gk].rnd_time()
        if latency_time is not None:
            append_to_rnd_bus(rnd_busses,latency_time,circuit[gk]) 
    # Pass in roder to sort the nodes in each bus by index
    # in order to keep the order of appearance for randomness branching
    for blat, blat_bus in rnd_busses.items():
        bus_nodes = blat_bus['nodes']
        # Create a list of node objects for sorting based on index
        nodes_obj = [circuit[n] for n in bus_nodes]
        sortedByIndex = sorted(nodes_obj,key=lambda x: x.var_index)
        sorted_nodes = [e.id for e in sortedByIndex]
        # Update with sorted index 
        blat_bus['nodes'] = sorted_nodes
    return rnd_busses

# Create the len as a string for a length dictionnary
def create_len_string(lengths):
    len_string = ''
    am_len_seen = 0
    for length,occurences in zip(lengths.keys(),lengths.values()):
        len_string += '{}*{}+'.format(occurences,length)
        am_len_seen+=1
    if am_len_seen==0:
        len_string = '0+'
    return len_string[:-1]

def create_rnd_connection_string(length_used,btime,n_rnd_am):
    return '{}[{} +: {}]'.format(
            create_rnd_bus_string(btime),
            create_len_string(length_used),
            n_rnd_am
            )

def connect_randomness_bus(circuit,bus_time,bus):
    length_used = {}
    for nodeid in bus['nodes']:
        node = circuit[nodeid]
        circuit[nodeid].op.rnd_src = create_rnd_connection_string(
                length_used,
                bus_time,
                node.op.rndam
                )
        if node.op.rndam in length_used:
            length_used[node.op.rndam] += 1
        else:
            length_used[node.op.rndam] = 1

def search_in_depth(idstart,idsearch,circuit,verbose=True):
    if verbose:
        print("Node: {}".format(idstart))
    if idstart==idsearch:
        if verbose:
            print('FOUND!')
        return True
    else:
        flag_found = False
        if circuit[idstart].op is None:
            return False
        else:
            if circuit[idstart].op.src0 is not None:
                flag_found = flag_found or search_in_depth(
                        circuit[idstart].op.src0,
                        idsearch,
                        circuit
                        )
            if circuit[idstart].op.src1 is not None:
                flag_found = flag_found or search_in_depth(
                        circuit[idstart].op.src1,
                        idsearch,
                        circuit
                        )
            return flag_found


def compute_level_gate(idstart,gatet,circuit):
    node = circuit[idstart]
    if node.op is None:
        return [0,[node.id]]
    else:
        sum_gate0 = [0,[]]
        sum_gate1 = [0,[]]
        if node.op.src0 is not None:
            sum_gate0 = compute_level_gate(
                    node.op.src0,
                    gatet,
                    circuit
                    )
        if node.op.src1 is not None:
            sum_gate1 = compute_level_gate(
                    node.op.src1,
                    gatet,
                    circuit
                    )
        sum_gate = max(sum_gate0[0],sum_gate1[0])
        list_gate = []
        if sum_gate==sum_gate0[0]:
            list_gate = sum_gate0[1]
        else:
            list_gate = sum_gate1[1]
        sum_gate += 1 if node.op.op is gatet else 0
        return [sum_gate,list_gate+[node.id]]

def create_include_directive(circuit):
    include_list= []
    # Create list of inclusion
    for g in circuit:
        node = circuit[g]
        if node.op is not None:
            if node.op.op == "andp2":
                if "MSKand_HPC2.vh" not in include_list:
                    include_list.append("MSKand_HPC2.vh")
    # Create the includes directives
    inc_dir = ''
    for inc in include_list:
        inc_dir += '`include "{}"\n'.format(inc)
    return inc_dir

def create_verilog_IO_ports(circuit,outs,ins,interface):
    # Create interface ports
    IO_ports_str = '// Inputs ports\n'
    for inter in interface:
        if inter=='clock':
            IO_ports_str += '(* fv_type="clock" *)\n'
            IO_ports_str += 'input clk;\n'
        elif inter=='enable':
            IO_ports_str += '(* fv_type="control" *)\n'
            IO_ports_str += 'input enable;\n'
        elif inter=='reset':
            IO_ports_str += '(* fv_type="control" *)\n'
            IO_ports_str += 'input rst;\n'
    # Create IOs ports in
    for inp in ins:
        lenins = circuit[inp].lenstr
        if circuit[inp].dtype=='data':
            IO_ports_str += '(* fv_type="sharing", fv_latency={}, fv_count=1 *)\n'.format(circuit[inp].time)
        elif circuit[inp].dtype=='control':
            IO_ports_str += '(* fv_type="control" *)\n'
        elif circuit[inp].dtype=='random':
            lat_str = get_time_from_rnd_bus_str(circuit[inp].id)
            rnd_len = circuit[inp].lenstr
            IO_ports_str += '(* fv_type="random", fv_count=1, fv_rnd_count_0={}, fv_rnd_lat_0={}  *)\n'.format(rnd_len,lat_str)
        if lenins=='1' or lenins=='1*1':
            IO_ports_str += 'input {};\n'.format(inp)
        else:
            IO_ports_str += 'input [{}-1:0] {};\n'.format(lenins,inp)

    # Create IOs ports out
    IO_ports_str += '\n// Outputs ports\n'
    for outp in outs:
        lenouts = circuit[outp].lenstr
        if circuit[outp].dtype=='data':
            IO_ports_str += '(* fv_type="sharing", fv_latency={}, fv_count=1 *)\n'.format(circuit[outp].time)
        elif circuit[outp].dtype=='control':
            IO_ports_str += '(* fv_type="control" *)\n'
        elif circuit[outp].dtype=='random':
            lat_str = get_time_from_rnd_bus_str(circuit[inp].id)
            rnd_len = circuit[inp].lenstr
            IO_ports_str += '(* fv_type="random", fv_count=0, fv_rnd_count_0={}, fv_rnd_lat_0={}  *)\n'.format(rnd_len,lat_str)
        if lenouts=='1' or lenouts=='1*1':
            IO_ports_str += 'output {};\n'.format(outp)
        else:
            IO_ports_str += 'output [{}-1:0] {};\n'.format(lenouts,outp)
    
    return IO_ports_str

def create_rnd_busses(circuit,outs,ins,rnd_busses,validity_pipeline):
    # For each bus, proceed to signal creation and connexion
    for rbi,rb in zip(rnd_busses.keys(),rnd_busses.values()):
        # Create the bus node
        bus_str = create_rnd_bus_string(rbi)
        busnode = NodeVar(
                bus_str,
                None,
                0,
                'random',
                create_len_string(rb['lengths'])
                )
        circuit[bus_str]=busnode
        ins.append(bus_str)
        # Create the connexion to the nodes
        connect_randomness_bus(circuit,rbi,rb)
        # Create the need rnd node
        if validity_pipeline != None:
            nrnd_str = create_need_rnd_string(rbi)
            nrndnode = NodeVar(
                    nrnd_str,
                    Nodeop(
                        'id',
                        validity_pipeline[rbi],
                        None,
                        ),
                    None,
                    'control',
                    '1'
                    )
            circuit[nrnd_str]=nrndnode
            outs.append(nrnd_str)
    # Resolve circuit post modification
    resolve_dtype_circuit(circuit)
    resolve_len_circuit(circuit)
    evaluate_latency_circuit(circuit,outs)


def create_verilog_netlist(circuit,outs,ins,mod_name="my_module",gen_enable=False,dirout='.'):
    print("Creating verilog netlist.")
    netlist_txt = ''
    # Create verilog interface
    # TODO: add the gen_enable to create_top_verilog_interface
    top_v_interface = create_top_verilog_interface(
            mod_name,
            circuit,
            outs,
            ins,
            gen_enable
            )
    netlist_txt += top_v_interface
    # Create include directive
    inc_directives = create_include_directive(circuit)
    netlist_txt += '\n\n'
    netlist_txt += inc_directives
    # Create IO ports
    IO_ports = create_verilog_IO_ports(
            circuit,
            outs,
            ins,
            interface_selection(circuit,gen_enable),
            )
    netlist_txt += '\n'
    netlist_txt += IO_ports
    # Create mux control signals
    
    # Create internal variable list 
    internal_vars_list = create_internal_variable_list(circuit,outs,ins)
    netlist_txt += '\n\n'
    netlist_txt += internal_vars_list
    # Create the gatelist in order
    muxctrl_list = create_mux_ctrl_tree_order(circuit)
    gatelist = create_gatelist_order(circuit,outs,ins)
    nodelist = muxctrl_list + gatelist
    netlist_txt += "// Internal computation node\n"
    for g in nodelist:
        if g not in outs and g not in ins:
            nentry = create_verilog_template_entry(
                    circuit[g],
                    None,
                    gen_en=gen_enable
                    )
            netlist_txt += nentry + '\n'
    # Connect the need rnd signal  
    netlist_txt += '// Output nodes\n'
    # Write output
    for g in nodelist:
        if g in outs:
            nentry = create_verilog_template_entry(
                    circuit[g],
                    None,
                    gen_en=gen_enable
                    )
            netlist_txt += nentry + '\n'
    # Close the module
    netlist_txt += 'endmodule'
    # Write the netlist
    filename = '{}/{}.v'.format(dirout,mod_name)
    print("Write netlist in '{}'".format(filename))
    with open(filename,'w') as f:
        f.write(netlist_txt)

def create_mctrl_stage(sctrl,time):
    return '{}_stage{}'.format(sctrl,time)

def fix_latency_ctrl_mux(muxvar,circuit):
    # Create connexion node
    mtime = muxvar.time
    cnode_id = create_mctrl_stage(muxvar.op.ctrlsig0,muxvar.time)
    if cnode_id not in circuit:
        # Create the node
        cnode = NodeVar(
            cnode_id,
            Nodeop(
                'id',
                muxvar.op.ctrlsig0,
                None,
                ),
            None,
            'control',
            '1' 
            )
        circuit[cnode_id]=cnode
        # Fix delay
        add_delay_opin(
                circuit[cnode_id].op,
                0,
                mtime,
                circuit,
                ntype='control'
                )
    # Connect the mux control signal
    muxvar.op.ctrlsig0 = cnode_id
    

def create_mux_ctrl(circuit,outs,ins):
    # First create list of mux
    muxes_id = []
    for g in circuit.values():
        if g.op is not None:
            if g.op.op == 'mux' or g.op.op == 'muxp*':
                muxes_id.append(g.id) 
    # Second fix control latency for each mux
    for mid in muxes_id:
        fix_latency_ctrl_mux(circuit[mid],circuit)
    # Resolve circuit post modification
    resolve_dtype_circuit(circuit)
    resolve_len_circuit(circuit)
    evaluate_latency_circuit(circuit,outs)

def build_transformed_verilog_netlist(toplevel_fn,convdic,module_name,gen_ctrl=True,gen_enable=True,dirout='.'):
    print("### START PROCESS ###")
    print('File: {}'.format(toplevel_fn))
    # Parse the top level circuit
    (circ,outs,ins) = parse_circuit(toplevel_fn)

    # Resolve data type
    resolve_dtype_circuit(circ)

    # Resolve length in the circuit
    resolve_len_circuit(circ)

    # Proceed to the gate conversion
    convert_gates(circ,convdic)
    gates_before = list(circ.keys())

    # Evaluate timing with the initial representation
    evaluate_latency_circuit(circ,outs,verbose=True)
    timing_out_no_opti = [circ[outs[i]].time for i in range(len(outs))]
    print('Outputs latency before optimisation: {}'.format(timing_out_no_opti))

    # Run optimisation pass
    pass_opti_timing_two_inputs(circ,outs,verbose=True)
    evaluate_latency_circuit(circ,outs)
    timing_out_opti = [circ[outs[i]].time for i in range(len(outs))]
    print('Outputs latency post optimisation: {}'.format(timing_out_opti))

    # Check the latency failure
    print('Check latency failures...')
    lf = check_latency_accross_circuit(circ,outs)
    print('List of nodes with latency failures:\n')
    print(lf)

    # Fix the latency failures
    fix_latency_failures(lf,circ,outs)
    gates_after = list(circ.keys())
    print('A total of {} registers have been added'.format(
        len(gates_after)-len(gates_before)
        )
        )
    timing_fix = [circ[outs[i]].time for i in range(len(outs))]
    print('Outputs latency post timing fixing: {}'.format(timing_fix))

    # Fix output latency to have same latency for each output node 
    fix_output_latency(circ,outs)
    timing_fix_out = [circ[outs[i]].time for i in range(len(outs))]
    print('Outputs latency post out timing fixing: {}'.format(timing_fix_out))

    # Add the validity pipeline to the circuit 
    if gen_ctrl:
        validity_pipeline = create_validity_pipeline(circ,outs,ins)
    else:
        validity_pipeline = None

    # Create randomness busses and connect them
    rnd_busses = fetch_rnd_busses(circ,outs,ins)
    create_rnd_busses(circ,outs,ins,rnd_busses,validity_pipeline)

    # Add the control signal of the muxes accros the circuit
    create_mux_ctrl(circ,outs,ins)

    # Create verilog netlist
    create_verilog_netlist(circ,outs,ins,mod_name=module_name,gen_enable=gen_enable,dirout=dirout) 
    

if __name__ == '__main__':
    args = parse_args()
    
    convdic = {'and':'andp2','add':'addp2','not':'notp*','mux':'muxp*'}
    
    build_transformed_verilog_netlist(
            args.circuit_file,
            convdic,
            args.verilog_module,
            gen_ctrl=args.gen_ctrl,
            gen_enable=args.gen_enable,
            dirout=args.dir_out
            ) 
