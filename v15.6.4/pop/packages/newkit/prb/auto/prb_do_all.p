/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_do_all.p
 > Purpose:			Obey a list of actions
 > Author:          Aaron Sloman, Oct 31 1994 (see revisions)
 > Documentation:	HELP * POPRULEBASE/DOALL
 > Related Files:
 */


section;
;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;

define prb_do_all(rule_instance, action);
	lvars rule_instance, action;
	;;; action should be of form [DOALL action action action ]
	prb_eval_list(back(action))
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov  8 1994
	Changed prb_eval_list back to having only one argument.
	It picks up rule_instacnce non-locally.
 */
