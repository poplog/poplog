/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/sim/auto/sim_present.p
 > Purpose:			Generalisation of prb_present, for objects
 > Author:          Aaron Sloman, Jun  6 1996 (see revisions)
 > Documentation:
 > Related Files:	sim_in_database
 */

compile_mode :pop11 +strict;
section;

uses sim_agent

define sim_present(pattern, object);
	;;; NB does not localise popmatchvars
    dlocal
        prb_database = sim_get_data(object);
        prb_present(pattern)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 30 2000
	Made to use sim_get_data
 */
