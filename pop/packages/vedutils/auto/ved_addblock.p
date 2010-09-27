/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_addblock.p
 > Purpose:			Add numbers between corners of a ved block
 > Author:          Aaron Sloman, Oct 15 1996
 > Documentation:
 > Related Files:
 */

/*
  Use the PUSH key to record two opposite corners of a VED text block as
  in HELP * VEDBLOCKS, then position VED cursor for location of total and do
	ENTER addblock

  All the text in the block will be ignored and the total will be inserted
  to right of cursor, e.g. try adding the next three numbers:

	10000
		50005
	  6999        = 67004

*/

;;; LIB VED_ADDBLOCK                                         A.Sloman Nov 1988

section;
uses vedblocks;
uses vedblockrepeater;

define ved_addblock;
	;;; Add up the numbers in the block between two stacked positions and
	;;; print total to right of cursor
	;;; If there's an argument print it before the total, otherwise
	;;; print '='
	lvars arg = vedargument;
	dlocal vedargument = nullstring, vedstatic = true;
	lvars num, total = 0, items;
	;;; Copy block of text between stacked positions
	ved_stb();
	incharitem(vedblockrepeater(vvedblockdump)) -> items;
	repeat
		items() -> num;
	quitif(num == termin);
		if isnumber(num) then num + total -> total endif;
	endrepeat;
	dlocal cucharout = vedcharinsert;
	if arg = nullstring then;;; pr(' = ')
	else vedcharright(); pr(arg); vedcharright()
	endif;
	pr(total)
enddefine;

endsection;
