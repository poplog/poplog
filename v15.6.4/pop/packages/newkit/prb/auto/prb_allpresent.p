/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_allpresent.p
 > Purpose:			Check if all patterns in a list have consistent
					instances in the database
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */


section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;

define global vars procedure prb_allpresent(patternlist) -> found;
	lvars patternlist, found;

	define lconstant procedure report_success(/* vec, num */);
		;;; return the items found.
		->; ->; 	;;; ignore vector and number
		ncrev(prb_found);
		exitfrom(prb_allpresent)
	enddefine;

	prb_forevery(patternlist, report_success);
	false -> found;
enddefine;

endsection;
