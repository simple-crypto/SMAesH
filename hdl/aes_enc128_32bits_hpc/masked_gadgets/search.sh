#! /bin/bash

ROOT_BEH=../../../beh_simu/work
D2WD=$ROOT_BEH/nshares_2/hdl
D3WD=$ROOT_BEH/nshares_3/hdl
D4WD=$ROOT_BEH/nshares_4/hdl

echo D2
grep "$1" $D2WD/*
echo
echo 
echo D3
grep "$1" $D3WD/*
echo
echo
echo D4
grep "$1" $D4WD/*

