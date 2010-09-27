;;; LIB VED_TRANS                                            A.Sloman Nov 1991

/*
A simple utility for inspecting values of environment varibles
in VED.

	ENTER trans <string>
		Will display the translation on the status line

	ENTER trans - <string>
    	Will insert the translation into the current VED buffer at
		the current cursor location.

Examples
	ENTER trans usepop

	ENTER trans - usepop

*/

define global ved_trans;
	lvars args = sysparse_string(vedargument);
	if args(1) = '-' then
		vedinsertstring(systranslate(args(2)))
	else
		systranslate(args(1))
	endif;
enddefine;
