/* --- Copyright University of Birmingham 1992. All rights reserved. ----------
 > File:			$poplocal/local/auto/ved_ins.p
 > Purpose:			Insert a string specified on command line
 > Author:			Aaron Sloman, Sep 27 1992
 > Documentation:	Below
 > Related Files:	LIB * ved_do, * veddo
 */

/*
Draft  REF VED_INS entry

ved_ins STRING												 [procedure]
	Interpret the string as if it were typed between string quotes to
	POP-11 in accordance with the conventions described in HELP * ASCII
	and REF * ITEMISE. For example, to insert a setence with each
	word on a new line indented by a tab

		ENTER ins \n\tThe\n\tcat\n\tchased\n\tthe\n\tdog

   	This facility  is very  conveniently combined  with ved_do,  for
   	multiple VED  commands.  Compare  * ved_ic,  which  inserts  one
    (non-printing) character.
*/

section;

define ved_ins();
	;;; insert the argument, intrepreting it as if it were a string
	;;; enclosed in string quotes
	;;; E.g. ENTER ins \sthe cat\r\ton the mat
	vedinsertstring(incharitem(stringin('\'' <> vedargument <> '\''))())
enddefine;

endsection;
