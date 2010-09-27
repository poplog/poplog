/* --- Copyright University of Birmingham 1992. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_tlli.p
 > Purpose:         Transcribe Last Lines In from other file.
 > Author:          Aaron Sloman, Oct 11 1992
 > Documentation:   Below, and HELP INOROUT
 > Related Files:	LIB * VED_TLI, * VED_TLO
 */

/*
DREFT HELP VED_TLLI
ENTER tlli
	Transcribe Lastline In from other file

ENTER tlli <number>
	Transcribe <number> of lines from other file, i.e. the last <number> lines
	preceding the current VED location in the other file.

Both versions cause the text copied in to be marked, so that
	ENTER br <number>
can be used to indent it as appropriate.

For creating example interactions in online documentation files instead
of using "ENTER output .", which causes output to go into the current
file, it is often much more convenient to use the procedure ved_tlli (Transcribe
Lines In).


	ENTER tlli
	copies in one line of the other file (e.g. printed out by =>)
and
	ENTER tlli 5
	copies in the last 5 lines.

This is especially useful when checking old documentation files where
you want most of the output from test commands not to go into the
current file, but occasionally there's something new which should.

*/
section;

uses ved_tli;

define global procedure ved_tlli();
	;;; Transcribe Last Line(s) In
	lvars num = strnumber(vedargument);
	dlocal vedargument = nullstring;

	num or 1 -> num;
	vedmarklo();
	veddo('tli -' sys_>< num);
	vedmarkhi();
	vedpositionpush();
	;;; adjust beginning of marked range
	vedmarkfind(); vedchardown(); vedmarklo();
	vedpositionpop();

enddefine;

endsection;
