/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_implies.p
 > Purpose:			Deal with [IMPLIES ...] conditions
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;

define procedure prb_implies(patternlist, pattern) -> boole;
	lvars patternlist, pattern, boole;

	define lconstant procedure test(/* vec, num */);
		;;; check that the pattern is also there
		->; ->; 	;;; ignore vector and number
		unless prb_present(pattern) then
			exitfrom(false, prb_implies)
		endunless;
	enddefine;

	prb_forevery(patternlist, test);
	true -> boole;
enddefine;

endsection;
