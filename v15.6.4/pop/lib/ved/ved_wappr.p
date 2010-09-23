/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            C.all/lib/ved/ved_wappr.p
 > Purpose:         Write and append marked range to named file
 > Author:          Aaron Sloman, Oct 17 1988 (see revisions)
 > Documentation:	____HELP _* ________VEDCOMMS
 > Related Files:	___LIB _* ___________VED_WAPPDR, _* ______________VEDAPPENDRANGE
 */
compile_mode :pop11 +strict;

;;; <ENTER> wappr <file>
;;; 	Write and append marked range to end of file.

section;

define vars ved_wappr();
	;;; write and append marked range to named file
	if vedargument = nullstring then
		vederror('NO FILENAME');
	elseif vvedmarklo > vvedmarkhi then
		vederror('NO MARKED RANGE');
	else
		vedappendrange(sysfileok(vedargument), vvedmarklo, vvedmarkhi);
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Jan 14 1994
		Changed to use new vedappendrange and made identical to ved_wr
 */
