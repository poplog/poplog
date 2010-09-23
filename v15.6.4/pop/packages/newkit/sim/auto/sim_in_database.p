/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/sim/auto/sim_in_database.p
 > Purpose:			Generalisation of prb_in_database, for objects
 > Author:          Aaron Sloman, Jun  6 1996 (see revisions)
 > Documentation:
 > Related Files:
 */

compile_mode :pop11 +strict;
section;

uses sim_agent

define sim_in_database(pattern, object);
    dlocal
        prb_database = sim_get_data(object),
        popmatchvars = [];
        prb_present(pattern)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 30 2000
	made to use sim_get_data
 */
