/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/auto/sim_pr_db.p
 > Purpose:			Print agent's database out in a predictable order
 > Author:          Brian Logan and Aaron Sloman, Jul 21 1999 (see revisions)
 > Documentation:	To be added
 > Related Files:
 */

section;
compile_mode :pop11+strict;
uses poprulebase
uses sim_agent
uses sim_data_precedes


define :method sim_syspr_db(agent:sim_object, keys);
	;;; Should this have a better name?

    ;;; Sort the keys so that we always get the output in the same order.

    lvars
		key, value,
		procedure dbtable = sim_get_data(agent);

    fast_for key in keys do
        unless fast_lmember(key, sim_noprint_keys) then
            fast_for value in dbtable(key) do
                value ==>
            endfor;
        endunless
    endfor;

enddefine;


;;; Print all the sub-databases in the table of the agent <agent>.  Optional
;;; second argument <keys> specifies a list of keys to use whose values are
;;; to be printed.


define sim_pr_db(agent, /* &optional keys */);

    lvars keys = false;
    ARGS agent, &OPTIONAL keys:islist;

    lvars dbtable = sim_get_data(agent);
    unless keys then
        syssort(prb_database_keys(dbtable), false, sim_data_precedes) -> keys;
    endunless;

	;;; now invoke method which can be redefined for different classes
	sim_syspr_db(agent, keys);

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 30 2000
	Made to use sim_get_data
 */
