// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.
task error_exit;
    begin
        $display("Failure when parsing TV file...");
        $finish;
    end
endtask

task read_file_header;
    input integer id_tv;
    output integer run_am;
    integer ret, tmp;
    begin
        ret = $fscanf(id_tv,"## CASES:%d\n",tmp);
        if (ret!=1) begin
            error_exit();
        end else begin
            run_am = tmp;
        end
    end
endtask

task read_case_header;
    input integer id_tv;
    output integer cid;
    integer ret, tmp;
    begin
        ret = $fscanf(id_tv,"#### CASE:%d\n",tmp);
        if (ret!=1) begin
            error_exit();
        end else begin
            cid = tmp;
        end
    end
endtask

task read_next_in_words;
    input integer id_tv;
    output reg [127:0] plain_reg;
    output reg [255:0] key_reg;
    output reg last_reg;
    integer ret, tmp;
    begin
        ret = $fscanf(id_tv,"plaintext: %x\n",plain_reg);
        if (ret!=1) error_exit();
        ret = $fscanf(id_tv,"umsk_key: %x\n",key_reg);
        if (ret!=1) error_exit();
        ret = $fscanf(id_tv,"last: %x\n",last_reg);
        if (ret!=1) error_exit();
    end
endtask

task read_next_out_words;
    input integer id_tv;
    output reg [127:0] cipher_reg;
    output reg last_reg;
    integer ret, tmp;
    begin
        ret = $fscanf(id_tv,"ciphertext: %x\n",cipher_reg);
        if (ret!=1) error_exit();
        ret = $fscanf(id_tv,"last: %x\n",last_reg);
        if (ret!=1) error_exit();
    end
endtask
