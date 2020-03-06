#!/bin/bash

BSC="bsc"
BSCFLAGS="-keep-fires -wait-for-license"

TOPFILE=Test.bsv
TOPMOD=mkTest

echo Compiling $TOPMOD in file $TOPFILE
echo Generating verilog
$BSC $BSCFLAGS -u -verilog -g $TOPMOD $TOPFILE

echo Generating simulator
$BSC $BSCFLAGS -D SIMULATE -sim -g $TOPMOD -u $TOPFILE
$BSC $BSCFLAGS -sim -o $TOPMOD -e $TOPMOD
