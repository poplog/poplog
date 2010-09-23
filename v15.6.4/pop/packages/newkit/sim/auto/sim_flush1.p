/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/sim/auto/sim_flush1.p
 > Purpose:			Generalisation of prb_flush1, for objects
 > Author:          Aaron Sloman, Jun  6 1996 (see revisions)
 > Documentation:
 > Related Files:
 */

compile_mode :pop11 +strict;
section;

define sim_flush1(pattern, object);
    dlocal
        prb_database = sim_get_data(object),
        popmatchvars = [];
        prb_flush1(pattern)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 30 2000
	Made to use sim_get_data
 */
