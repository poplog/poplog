/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_map_action.p
 > Purpose:         Used to map a collection of actions on the basis of a
					veclist produced by a filter condition
 > Author:          Aaron Sloman, Oct 29 1994
 > Documentation:
 > Related Files:
 */


section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;


define prb_map_action(rule_instance, action);
	;;; invoked by actions of the form
	;;; [MAP ?veclist <procedure> <action1> <action2> ... <actionn>]
	;;; the procedure must take a veclist and an actionlist
	;;; and decide what to do about actions in the
	;;; actionlist on the basis of items in veclist

	lvars rule_instance, action, veclist, proc, actionlist, action;

	destpair(fast_back(action)) -> (veclist, actionlist);

	destpair(actionlist) -> (proc, actionlist);
	prb_valof(proc) -> proc;

	unless isprocedure(proc) then
		mishap('MAP ACTION NEEDS Procedure',
			[^proc ^action ^(prb_rulename(prb_ruleof(rule_instance)))])
	endunless;

	;;; what happens next is up to the user's proc
	;;; but check that stack is left intact
	lvars list =
		[%proc(veclist, actionlist, rule_instance)%];

	unless list == [] then
		mishap('SPURIOUS ITEMS LEFT ON STACK BY MAP PROCEDURES',
				list)
	endunless;

enddefine;
		
endsection;
