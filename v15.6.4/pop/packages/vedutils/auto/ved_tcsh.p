/* --- Copyright University of Birmingham 2002. All rights reserved. ----------
 > File:            $poplocal/local/auto/ved_tcsh.p
 > Purpose:			Run a TCSH command, and read output into a VED buffer
 > Author:          Aaron Sloman, 27 Jul 2002
 > Documentation:	HELP * PIPEUTILS, HELP * SHELL
 > Related Files:	SHOWLIB * VEDGENSHELL, * VEDPIPEIN, * PIPEIN
 >						LIB ved_sh, ved_csh, ved_bash
 */
compile_mode :pop11 +strict;

/*
ved_tcsh
A VED command for running a C-shell command and reading the output
into a temporary VED file.

 <ENTER> tcsh <command>

Runs the /bin/tcsh with the <command> and reads in any output.

*/

section;

define vars ved_tcsh;
	vedgenshell('/bin/tcsh',copy(vedcommand));
enddefine;

endsection;
