$! --- Copyright Integral Solutions Ltd 1990. All rights reserved. -------
$! File:            $popneural/bin/neural
$! Purpose:         Poplog-Neural build/invoke script
$! Author:          Julian Clinton, Jan 1990
$! Documentation:   $popneural/help
$! Related Files:
$ on error then goto errexit
$
$ assign/nolog "no" NEURAL_X_REQUEST
$ IDIR = "''f$trnlnm("POPNEURAL")'" + "[BIN.VAX]"
$ NEURAL_MAKE = "no"
$ NEURAL_INDEXES = "no"
$
$ if "''f$trnlnm("NEURAL_IMAGEDIR")'" .eqs. "" then goto ARGLOOP
$
$ IDIR = "''f$trnlnm("NEURAL_IMAGEDIR")'"
$
$ ARGLOOP:
$	if p1 .eqs. "" then goto ARGSDONE
$	if p1 .eqs. "-DIR" .or. p1 .eqs. "-dir"
$	then
$		gosub SHIFTARG
$		IDIR = p1
$		goto NEXTARG
$	endif
$	if p1 .eqs. "-M" .or. p1 .eqs. "-m"
$	then
$		NEURAL_MAKE = "yes"
$		goto NEXTARG
$	endif
$	if p1 .eqs. "-INDEXES" .or. p1 .eqs. "-indexes"
$	then
$		NEURAL_INDEXES = "yes"
$		goto NEXTARG
$	endif
$	if p1 .eqs. "-X" .or. p1 .eqs. "-x"
$	then
$ 		assign/nolog "yes" NEURAL_X_REQUEST
$		goto NEXTARG
$	endif
$
$	write sys$output "Usage: neural [-x] [-m] [-dir <dir>] [-indexes]"
$	exit 20		! SS$_BADPARAM
$
$	NEXTARG:
$	gosub SHIFTARG
$	goto ARGLOOP
$
$	SHIFTARG:
$	p1 = p2
$	p2 = p3
$	p3 = p4
$	p4 = p5
$	p5 = p6
$	p6 = p7
$	p7 = p8
$	p8 = ""
$	return
$
$ ARGSDONE:
$  execn :== "''pop11' /''IDIR'neural"
$  execxn :== "''pop11' /''IDIR'neural \%x"
$
$ if NEURAL_MAKE .nes. "yes" then goto nstart
$  @popneural:[bin]mkneural "''f$trnlnm("IDIR")'"
$
$ if NEURAL_INDEXES .nes. "yes" then goto mkdone
$  pop11 mkrefindex popneural:[ref]
$
$ mkdone:
$  exit
$
$ errexit:
$  write sys$output "Poplog-Neural: startup/build error"
$  exit
$
$ nstart:
$
$ if "''f$trnlnm("NEURAL_X_REQUEST")'" .eqs. "yes" then goto xnstart
$
$  spawn/nolog execn
$  exit
$
$ xnstart:
$  spawn/nolog execxn
$  exit
