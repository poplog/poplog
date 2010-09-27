/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_untrace.p
 > Purpose:			Turn off a type of tracing.
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;
;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;

define global vars procedure prb_untrace(list);
	lvars word, list;
	if list = "all" or list = #_< [all] >_# then
		newproperty([], 100, false, true) -> prb_istraced
	else
		for word in list do
			false -> prb_istraced(word)
		endfor
	endif
enddefine;

endsection;
