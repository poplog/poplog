/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_addline.p
 > Purpose:			Add up numbers in current line
 > Author:          Aaron Sloman, Oct 15 1996
 > Documentation:   below
 > Related Files:	HELP VEDBLOCKS, LIB * VED_ADDBLOCK
 */

/*
Position VED cursor to right of current line, then do
	ENTER addline

All the text in the line will be ignored and the total will be inserted
to right of cursor, e.g. try adding the next three numbers:

This is one 10000 and another 50005 and 6999   = 67004

*/

section;
;;; LIB VED_ADDLINE                                           A.Sloman Nov 1988

define ved_addline();
	;;; Add up all the numbers in the current line and insert the
	;;; total to right of cursor. Ignore non-numbers in the line.

	;;; If there's an argument print it before the total, otherwise
	;;; print '='
	lvars num, total = 0,
		 items=incharitem(stringin(subscrv(vedline,vedbuffer)));
	dlocal vedbreak = false;
	repeat
		items() -> num;
	quitif(num == termin);
		if isnumber(num) then num + total -> total endif;
	endrepeat;
	dlocal cucharout = vedcharinsert;
	if vedargument = nullstring then pr('= ')
	else pr(vedargument); vedcharright()
	endif;
	pr(total)
enddefine;

endsection;
