/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/sim/auto/sim_flush.p
 > Purpose:			Generalisation of prb_flush, for objects
 > Author:          Aaron Sloman, Jun  6 1996 (see revisions)
 > Documentation:
 > Related Files:
 */

compile_mode :pop11 +strict;
section;

uses sim_agent

define sim_flush(pattern, object);
	;;; may side-effect prb_foubd
    dlocal
        prb_database = sim_get_data(object),
        popmatchvars = [];
        prb_flush(pattern)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 30 2000
	made to use sim_get_data
 */
