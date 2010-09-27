$! --- Copyright Integral Solutions Ltd. 1990. All rights reserved. ---------
$! File:            $popneural/bin/mkneural
$! Purpose:         make a saved image of Poplog-Neural
$! Author:          Julian Clinton, Feb 1990
$! Documentation:   $popneural/help
$! Related Files:   All those mentioned below
$
$ IDIR = "''f$trnlnm("POPNEURAL")'" + "[BIN.VAX]"
$ if p1 .eqs. "" then goto DOMAKE
$ IDIR = p1
$
$ DOMAKE:
$ pop11 \%nort popliblib:mkimage.p -
	"''IDIR'neural.psv" -
	popneural:[bin]mkneural.p -
	": nn_init();"
$ pu popneural:[bin.vax]neural.psv
$ exit
