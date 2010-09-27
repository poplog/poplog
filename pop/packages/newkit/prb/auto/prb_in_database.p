/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_in_database.p
 > Purpose:			Check if the pattern matches an item in the database
					If so, return the item and side-effect prb_found
					otherwise return false
 > Author:          Aaron Sloman, 30th Aug 1995
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */


section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;

define global vars procedure prb_in_database(pattern);
	lvars pattern;

	;;; Like prb_present, but resets popmatchvars
	dlocal popmatchvars = [];

	prb_present(pattern);

enddefine;

endsection;
