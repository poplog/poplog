/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_foreach.p
 > Purpose:			Do an action for each occurrence of a pattern
 > Author:          Aaron Sloman, Oct 30 1994 (see revisions)
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;


define global vars procedure prb_foreach(pattern, proc);
	;;; Apply proc for every match between pattern and a database item.
	;;; prb_found will be the item matched when proc runs.
	lvars pattern;
	dlvars procedure proc;
	dlocal popmatchvars = [];	;;; don't extend popmatchvars

	prb_match_apply(
		prb_database,
		pattern,
		procedure(); -> prb_found; proc() endprocedure)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 16 1995
	Fixed bug reported by Jeremy Baxter due to popmatchvars not being
	initialised
--- Aaron Sloman, Jul  1 1995
	Changed for new database format
 */
