$! --- Copyright Integral Solutions Ltd. 1994. All rights reserved. ----------
$! File:             $popneural/src/c/compall
$! Purpose:          Compile all C code
$! Author:           Julian Clinton, Apr 1994
$! Related Files:
$ cc backprop
$ cc complearn
$ cc ranvecs
$ copy *.obj popneural:[bin.vax]
$ pu *.obj
