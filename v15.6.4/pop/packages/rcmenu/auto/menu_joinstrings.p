/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_joinstrings.p
 > Purpose:         join strings with newlines in between
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

section;

define global vars procedure menu_joinstrings(list) -> string;
	;;; given a list of strings return a single string, with newlines
	;;; separating originals
	lvars list, s, string;
	consstring(
		#|	explode('PURPOSE OF COMMAND:\n'),
			for s in list do explode(s), `\n` endfor,
			erase() |#) -> string;
enddefine;

endsection;
