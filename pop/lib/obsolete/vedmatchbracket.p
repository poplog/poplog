/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/vedmatchbracket.p
 >  Purpose:        Some bracket matching utilities
 >  Author:         John Williams, Aug 16 1985 (see revisions)
 >  Documentation:
 >  Related Files:  C.all/lib/ved/vedfindbracket.p
 */

#_TERMIN_IF DEF POPC_COMPILING

printf(';;; NOTE: vedmatchbracket has been superceded by vedfindbracket.\n');
printf(';;;       After Version 14.5, vedmatchbracket will only be available\n');
printf(';;;       with \'uses popobsoletelib\' and \'uses vedmatchbracket\'.\n');

section;


define vedmatchbracket(ket, bra, movepdr, endtest, pdr);
	lvars bra ket endtest movepdr pdr;
	dlocal vedpositionstack;
	vedpositionpush();
	vedfindbracket(bra, ket, endtest, movepdr);
	pdr();
	vedpositionpop();
enddefine;


/*  VEDCHOOSEBRACKET returns apppropriate values for the first four arguments
 *  of VEDMATCHBRACKET, using the value of the variable VEDBRATABLE.
 */

global vars vedbratable = '()[]{}<>';

define global procedure vedchoosebracket(char);
	lvars char i;
	if locchar(char, 1, vedbratable) ->> i then
		if i && 1 == 1 then
			char, subscrs(i fi_+ 1, vedbratable), vedcharnext, vedatend
		else
			char, fast_subscrs(i fi_- 1, vedbratable), vedcharleft, vedatstart
		endif
	else
		vederror('Unrecognised bracket: "' <> consstring(char, 1) <> '"')
	endif
enddefine;


endsection;


/*  --- Revision History ---------------------------------------------------
--- John Williams, Oct 21 1988 - rewritten using -vedfindbracket-
--- John Williams, Aug 1985 - calls "endtest" AFTER testing current char
 */
